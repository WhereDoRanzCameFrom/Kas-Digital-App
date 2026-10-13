import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import '../dummy/dummy_data.dart';
import '../../core/services/local_auth_service.dart';
import 'repositories.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

final _db = FirebaseFirestore.instance;

/// Convert DateTime → Timestamp Firestore.
Timestamp _toTs(DateTime dt) => Timestamp.fromDate(dt);

/// Convert Timestamp Firestore → DateTime.
DateTime _fromTs(dynamic raw) {
  if (raw == null) return DateTime.now();
  if (raw is Timestamp) return raw.toDate();
  if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
  if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
  return DateTime.now();
}

// ─── FirebaseAuthRepository ───────────────────────────────────────────────────
//
// Alur login:
//   1. Ambil semua user dari Firestore (collection 'users').
//   2. Cari user berdasarkan userId.
//   3. Verifikasi PIN via LocalAuthService (PIN di-hash, disimpan di device).
//   4. Kalau cocok → simpan sesi ke SharedPreferences → return UserModel.
//
// Pertama kali pakai Firebase: PIN belum ada di lokal.
// Solusi: auto-seed PIN dari DummyData saat user belum punya hash tersimpan.
// (Lihat _ensurePinsSeeded di bawah)

class FirebaseAuthRepository implements AuthRepository {
  final _local = LocalAuthService.instance;

  // Flag in-memory: seed sudah selesai di sesi ini, skip Firestore read
  bool _seedChecked = false;

  @override
  Future<UserModel?> login(String userId, String pin) async {
    // Pastikan PIN sudah di-seed ke lokal
    await _ensurePinsSeeded();

    // Verifikasi PIN lokal
    final valid = await _local.verifyPin(userId, pin);
    if (!valid) return null;

    // Ambil data user dari Firestore
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      final user = UserModel.fromJson({...doc.data()!, 'id': doc.id});
      await _local.saveSession(user);
      return user;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    await _local.clearSession();
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    // Seed dulu sebelum fetch supaya dropdown langsung terisi
    // saat login page pertama kali dibuka
    await _ensurePinsSeeded();
    try {
      final snap = await _db.collection('users').orderBy('name').get();
      return snap.docs
          .map((d) => UserModel.fromJson({...d.data(), 'id': d.id}))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Seed awal: upload DummyData.users ke Firestore + simpan PIN lokal ────
  //
  // Dipanggil tiap login, tapi hanya eksekusi kalau Firestore kosong
  // DAN PIN belum pernah disimpan di lokal.
  // Setelah seed selesai, flag 'users_seeded' disimpan biar tidak repeat.

  Future<void> _ensurePinsSeeded() async {
    // Skip kalau sudah dicek di sesi ini — hemat 1 Firestore read per login
    if (_seedChecked) return;

    // Cek jumlah user di Firestore — kalau beda sama DummyData, re-seed
    // Ini handles: pertama kali install, ganti HP, tambah/hapus user
    try {
      final snap = await _db.collection('users').get();
      final firestoreCount = snap.docs.length;
      final expectedCount = DummyData.users.length;

      if (firestoreCount == expectedCount) {
        // Firestore sudah benar, pastikan PIN lokal juga ada
        final firstUser = DummyData.users.first;
        final pinOk = await _local.hasPinStored(firstUser.id);
        if (pinOk) {
          _seedChecked = true;
          return; // semuanya sudah oke, skip
        }
      }

      // Perlu seed ulang — hapus PIN lama dulu biar bersih
      final allIds = DummyData.users.map((u) => u.id).toList();
      await _local.clearAllPins(allIds);

      // Seed PIN semua user ke lokal
      for (final u in DummyData.users) {
        await _local.savePin(u.id, u.pin);
      }

      // Seed user data ke Firestore (tanpa PIN)
      // Pakai set overwrite biar data lama yang obsolete tertimpa
      final batch = _db.batch();
      for (final u in DummyData.users) {
        batch.set(
          _db.collection('users').doc(u.id),
          u.toJsonSafe(),
        );
      }
      await batch.commit();
      _seedChecked = true;
    } catch (_) {
      // Kalau Firestore tidak bisa diakses, fallback: seed PIN lokal saja
      for (final u in DummyData.users) {
        await _local.savePin(u.id, u.pin);
      }
    }
  }
}

// ─── FirebaseTransactionRepository ───────────────────────────────────────────

class FirebaseTransactionRepository implements TransactionRepository {
  final _col = _db.collection('transactions');

  @override
  Future<List<TransactionModel>> getAll() async {
    final snap = await _col.orderBy('date', descending: true).get();
    return snap.docs.map((d) => _fromDoc(d)).toList();
  }

  @override
  Future<List<TransactionModel>> getByUser(String userId) async {
    final snap = await _col
        .where('createdBy', isEqualTo: userId)
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map((d) => _fromDoc(d)).toList();
  }

  @override
  Future<String> add(TransactionModel tx,
      {required UserRole callerRole}) async {
    if (!callerRole.canAddTransaction) {
      throw PermissionException(
          'Role ${callerRole.shortLabel} tidak dapat menambah transaksi');
    }
    if (tx.amount <= 0) {
      throw const ValidationException('Jumlah transaksi harus lebih dari 0');
    }
    if (tx.type == TransactionType.masuk && !callerRole.canModifyMainKas) {
      throw const PermissionException(
          'Hanya Bendahara yang dapat mencatat kas masuk langsung');
    }
    if (tx.type == TransactionType.keluar &&
        tx.setoranId == null &&
        !callerRole.canModifyMainKas) {
      throw const PermissionException(
          'Divisi tidak dapat menambah kas keluar langsung. Gunakan setoran.');
    }

    final data = _toFirestore(tx);
    final ref = _col.doc(tx.id);
    await ref.set(data);
    return tx.id;
  }

  @override
  Future<void> update(TransactionModel tx,
      {required UserRole callerRole}) async {
    if (!callerRole.canModifyMainKas) {
      throw const PermissionException(
          'Hanya Bendahara yang dapat mengubah transaksi');
    }
    final ref = _col.doc(tx.id);
    final exists = (await ref.get()).exists;
    if (!exists) throw NotFoundException('Transaksi tidak ditemukan: ${tx.id}');
    await ref.update(_toFirestore(tx));
  }

  @override
  Future<void> delete(String txId, {required UserRole callerRole}) async {
    if (!callerRole.canDelete) {
      throw PermissionException(
          'Role ${callerRole.shortLabel} tidak dapat menghapus transaksi');
    }
    final ref = _col.doc(txId);
    final exists = (await ref.get()).exists;
    if (!exists) throw NotFoundException('Transaksi tidak ditemukan: $txId');
    await ref.delete();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  TransactionModel _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = {...doc.data()!, 'id': doc.id};
    // Override date dari Timestamp Firestore
    return TransactionModel(
      id: doc.id,
      type: TransactionType.fromValue((data['type'] as String?) ?? 'keluar'),
      category: TransactionCategory.fromValue(
          (data['category'] as String?) ?? 'lainnya'),
      amount: ((data['amount'] as num?) ?? 0).toDouble(),
      description: (data['description'] as String?) ?? '',
      date: _fromTs(data['date']),
      createdBy: (data['createdBy'] as String?) ?? '',
      createdByName: (data['createdByName'] as String?) ?? '',
      createdByRole:
          UserRole.fromValue((data['createdByRole'] as String?) ?? 'konsumsi'),
      setoranId: data['setoranId'] as String?,
    );
  }

  Map<String, dynamic> _toFirestore(TransactionModel tx) => {
        'type': tx.type.value,
        'category': tx.category.value,
        'amount': tx.amount,
        'description': tx.description,
        'date': _toTs(tx.date), // Timestamp Firestore, bukan ISO string
        'createdBy': tx.createdBy,
        'createdByName': tx.createdByName,
        'createdByRole': tx.createdByRole.value,
        if (tx.setoranId != null) 'setoranId': tx.setoranId,
      };
}

// ─── FirebaseSetoranRepository ────────────────────────────────────────────────

class FirebaseSetoranRepository implements SetoranRepository {
  final _col = _db.collection('setorans');

  @override
  Future<List<SetoranModel>> getAll() async {
    final snap = await _col.orderBy('tanggalSetor', descending: true).get();
    return snap.docs.map((d) => _fromDoc(d)).toList();
  }

  @override
  Future<List<SetoranModel>> getByUser(String userId) async {
    final snap = await _col
        .where('fromUserId', isEqualTo: userId)
        .orderBy('tanggalSetor', descending: true)
        .get();
    return snap.docs.map((d) => _fromDoc(d)).toList();
  }

  @override
  Future<String> save(SetoranModel setoran,
      {required UserRole callerRole}) async {
    if (!callerRole.canSubmitSetoran) {
      throw PermissionException(
          'Role ${callerRole.shortLabel} tidak dapat mengirim setoran');
    }
    if (setoran.transactions.isEmpty) {
      throw const ValidationException(
          'Setoran harus mengandung minimal 1 transaksi');
    }
    if (setoran.totalAmount <= 0) {
      throw const ValidationException('Total setoran harus lebih dari 0');
    }
    await _col.doc(setoran.id).set(_toFirestore(setoran));
    return setoran.id;
  }

  @override
  Future<void> update(SetoranModel setoran,
      {required UserRole callerRole}) async {
    final ref = _col.doc(setoran.id);
    final snap = await ref.get();
    if (!snap.exists) {
      throw NotFoundException('Setoran tidak ditemukan: ${setoran.id}');
    }

    final current = _fromDoc(snap);
    final isStatusChange = current.status != setoran.status;

    if (isStatusChange) {
      final isApproveOrReject = setoran.status == SetoranStatus.diterima ||
          setoran.status == SetoranStatus.ditolak;
      if (isApproveOrReject && !callerRole.canApproveSetoran) {
        throw const PermissionException(
            'Hanya Bendahara yang dapat menerima/menolak setoran');
      }
    }

    if (!isStatusChange &&
        !callerRole.canSubmitSetoran &&
        !callerRole.canApproveSetoran) {
      throw const PermissionException('Tidak diizinkan mengubah setoran ini');
    }

    await ref.update(_toFirestore(setoran));
  }

  @override
  Future<void> delete(String setoranId, {required UserRole callerRole}) async {
    final ref = _col.doc(setoranId);
    final snap = await ref.get();
    if (!snap.exists) {
      throw NotFoundException('Setoran tidak ditemukan: $setoranId');
    }

    final setoran = _fromDoc(snap);
    if (setoran.status == SetoranStatus.diterima) {
      throw const PermissionException(
          'Setoran yang sudah diterima tidak dapat dihapus');
    }
    await ref.delete();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  SetoranModel _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final txList = ((data['transactions'] as List<dynamic>?) ?? [])
        .map((e) => _txFromMap(e as Map<String, dynamic>))
        .toList();

    return SetoranModel(
      id: doc.id,
      fromUserId: (data['fromUserId'] as String?) ?? '',
      fromUserName: (data['fromUserName'] as String?) ?? '',
      fromRole: UserRole.fromValue((data['fromRole'] as String?) ?? 'konsumsi'),
      transactions: txList,
      totalAmount: ((data['totalAmount'] as num?) ?? 0).toDouble(),
      tanggalSetor: _fromTs(data['tanggalSetor']),
      catatan: data['catatan'] as String?,
      status: SetoranStatus.fromValue((data['status'] as String?) ?? 'pending'),
      catatanBendahara: data['catatanBendahara'] as String?,
      tanggalKonfirmasi: data['tanggalKonfirmasi'] != null
          ? _fromTs(data['tanggalKonfirmasi'])
          : null,
    );
  }

  TransactionModel _txFromMap(Map<String, dynamic> data) => TransactionModel(
        id: (data['id'] as String?) ?? '',
        type: TransactionType.fromValue((data['type'] as String?) ?? 'keluar'),
        category: TransactionCategory.fromValue(
            (data['category'] as String?) ?? 'lainnya'),
        amount: ((data['amount'] as num?) ?? 0).toDouble(),
        description: (data['description'] as String?) ?? '',
        date: _fromTs(data['date']),
        createdBy: (data['createdBy'] as String?) ?? '',
        createdByName: (data['createdByName'] as String?) ?? '',
        createdByRole: UserRole.fromValue(
            (data['createdByRole'] as String?) ?? 'konsumsi'),
        setoranId: data['setoranId'] as String?,
      );

  Map<String, dynamic> _toFirestore(SetoranModel s) => {
        'fromUserId': s.fromUserId,
        'fromUserName': s.fromUserName,
        'fromRole': s.fromRole.value,
        'transactions': s.transactions.map((t) => _txToMap(t)).toList(),
        'totalAmount': s.totalAmount,
        'tanggalSetor': _toTs(s.tanggalSetor),
        if (s.catatan != null) 'catatan': s.catatan,
        'status': s.status.value,
        if (s.catatanBendahara != null) 'catatanBendahara': s.catatanBendahara,
        if (s.tanggalKonfirmasi != null)
          'tanggalKonfirmasi': _toTs(s.tanggalKonfirmasi!),
      };

  Map<String, dynamic> _txToMap(TransactionModel t) => {
        'id': t.id,
        'type': t.type.value,
        'category': t.category.value,
        'amount': t.amount,
        'description': t.description,
        'date': _toTs(t.date),
        'createdBy': t.createdBy,
        'createdByName': t.createdByName,
        'createdByRole': t.createdByRole.value,
        if (t.setoranId != null) 'setoranId': t.setoranId,
      };
}

// ─── FirebaseAnnouncementRepository ──────────────────────────────────────────

class FirebaseAnnouncementRepository implements AnnouncementRepository {
  final _ref = _db.collection('config').doc('pengumuman');

  @override
  Future<String> get() async {
    try {
      final snap = await _ref.get();
      return (snap.data()?['text'] as String?) ?? '';
    } catch (_) {
      return '';
    }
  }

  @override
  Future<void> set(String text) async {
    await _ref.set({'text': text.trim()}, SetOptions(merge: true));
  }
}

// ─── FirebaseBudgetRepository ─────────────────────────────────────────────────

class FirebaseBudgetRepository implements BudgetRepository {
  final _ref = _db.collection('config').doc('budget');

  @override
  Future<Map<TransactionCategory, double>> getAll() async {
    try {
      final snap = await _ref.get();
      final data = snap.data() ?? {};
      final result = <TransactionCategory, double>{};
      for (final entry in data.entries) {
        try {
          final cat = TransactionCategory.fromValue(entry.key);
          result[cat] = ((entry.value as num?) ?? 0).toDouble();
        } catch (_) {
          // skip key yang tidak dikenal
        }
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> set(TransactionCategory category, double amount) async {
    if (amount <= 0) {
      await clear(category);
      return;
    }
    await _ref.set({category.value: amount}, SetOptions(merge: true));
  }

  @override
  Future<void> clear(TransactionCategory category) async {
    await _ref.update({category.value: FieldValue.delete()});
  }
}

// ─── FirebaseDataRepository ───────────────────────────────────────────────────

class FirebaseDataRepository implements DataRepository {
  @override
  Future<void> clearAllData({required UserRole callerRole}) async {
    if (!callerRole.canExport) {
      throw const PermissionException(
          'Hanya Ketua/Bendahara yang dapat menghapus semua data');
    }

    // Hapus semua dokumen di collection transactions
    await _deleteCollection('transactions');

    // Hapus semua dokumen di collection setorans
    await _deleteCollection('setorans');

    // Reset config (pengumuman + budget)
    final configRef = _db.collection('config');
    await configRef.doc('pengumuman').set({'text': ''});
    await configRef.doc('budget').set({});
  }

  /// Hapus semua dokumen dalam satu collection secara batch.
  Future<void> _deleteCollection(String path) async {
    const batchSize = 100;
    while (true) {
      final snap = await _db.collection(path).limit(batchSize).get();
      if (snap.docs.isEmpty) break;
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (snap.docs.length < batchSize) break;
    }
  }
}
