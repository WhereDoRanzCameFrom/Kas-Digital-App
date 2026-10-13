import '../models/models.dart';
import '../dummy/dummy_data.dart';
import 'repositories.dart';

// ─── DummyAuthRepository ──────────────────────────────────────────────────────

class DummyAuthRepository implements AuthRepository {
  @override
  Future<UserModel?> login(String userId, String pin) async {
    try {
      return DummyData.users.firstWhere(
        (u) => u.id == userId && u.pin == pin,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> logout() async {}

  @override
  Future<List<UserModel>> getAllUsers() async => DummyData.users;
}

// ─── DummyTransactionRepository ──────────────────────────────────────────────

class DummyTransactionRepository implements TransactionRepository {
  static List<TransactionModel>? _store;

  static List<TransactionModel> get _data {
    _store ??= List.from(DummyData.transactions);
    return _store!;
  }

  static void resetForTest() => _store = null;

  @override
  Future<List<TransactionModel>> getAll() async => List.from(_data);

  @override
  Future<List<TransactionModel>> getByUser(String userId) async =>
      _data.where((t) => t.createdBy == userId).toList();

  @override
  Future<String> add(TransactionModel transaction,
      {required UserRole callerRole}) async {
    // BUG FIX: validasi role di level repository
    if (!callerRole.canAddTransaction) {
      throw PermissionException(
          'Role ${callerRole.shortLabel} tidak dapat menambah transaksi');
    }
    // BUG FIX: validasi amount positif
    if (transaction.amount <= 0) {
      throw const ValidationException('Jumlah transaksi harus lebih dari 0');
    }
    // BUG FIX: validasi kas masuk hanya untuk bendahara
    if (transaction.type == TransactionType.masuk &&
        !callerRole.canModifyMainKas) {
      throw const PermissionException(
          'Hanya Bendahara yang dapat mencatat kas masuk langsung');
    }
    // BUG FIX: kas keluar langsung ke kas utama hanya untuk bendahara
    // (divisi harus lewat setoran)
    if (transaction.type == TransactionType.keluar &&
        transaction.setoranId == null &&
        !callerRole.canModifyMainKas) {
      throw const PermissionException(
          'Divisi tidak dapat menambah kas keluar langsung. Gunakan setoran.');
    }
    // BUG FIX: cek duplikasi ID
    if (_data.any((t) => t.id == transaction.id)) {
      throw ValidationException(
          'Transaksi dengan ID ${transaction.id} sudah ada');
    }
    _data.add(transaction);
    return transaction.id;
  }

  @override
  Future<void> update(TransactionModel transaction,
      {required UserRole callerRole}) async {
    if (!callerRole.canModifyMainKas) {
      throw const PermissionException(
          'Hanya Bendahara yang dapat mengubah transaksi');
    }
    final idx = _data.indexWhere((t) => t.id == transaction.id);
    if (idx == -1) {
      throw NotFoundException('Transaksi tidak ditemukan: ${transaction.id}');
    }
    _data[idx] = transaction;
  }

  @override
  Future<void> delete(String transactionId,
      {required UserRole callerRole}) async {
    if (!callerRole.canDelete) {
      throw PermissionException(
          'Role ${callerRole.shortLabel} tidak dapat menghapus transaksi');
    }
    final exists = _data.any((t) => t.id == transactionId);
    if (!exists) {
      throw NotFoundException('Transaksi tidak ditemukan: $transactionId');
    }
    _data.removeWhere((t) => t.id == transactionId);
  }
}

// ─── DummySetoranRepository ───────────────────────────────────────────────────

class DummySetoranRepository implements SetoranRepository {
  static List<SetoranModel>? _store;

  static List<SetoranModel> get _data {
    _store ??= List.from(DummyData.setorans);
    return _store!;
  }

  static void resetForTest() => _store = null;

  @override
  Future<List<SetoranModel>> getAll() async => List.from(_data);

  @override
  Future<List<SetoranModel>> getByUser(String userId) async =>
      _data.where((s) => s.fromUserId == userId).toList();

  @override
  Future<String> save(SetoranModel setoran,
      {required UserRole callerRole}) async {
    // BUG FIX: hanya divisi yang bisa submit setoran
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
    final existingIdx = _data.indexWhere((s) => s.id == setoran.id);
    if (existingIdx != -1) {
      _data[existingIdx] = setoran;
    } else {
      _data.add(setoran);
    }
    return setoran.id;
  }

  @override
  Future<void> update(SetoranModel setoran,
      {required UserRole callerRole}) async {
    final idx = _data.indexWhere((s) => s.id == setoran.id);
    if (idx == -1) {
      throw NotFoundException('Setoran tidak ditemukan: ${setoran.id}');
    }

    final current = _data[idx];

    // BUG FIX: approve/reject hanya bendahara
    final isStatusChange = current.status != setoran.status;
    if (isStatusChange) {
      final isApproveOrReject = setoran.status == SetoranStatus.diterima ||
          setoran.status == SetoranStatus.ditolak;
      if (isApproveOrReject && !callerRole.canApproveSetoran) {
        throw const PermissionException(
            'Hanya Bendahara yang dapat menerima/menolak setoran');
      }
    }

    // BUG FIX: hanya pemilik setoran atau bendahara yang bisa update
    if (!isStatusChange &&
        !callerRole.canSubmitSetoran &&
        !callerRole.canApproveSetoran) {
      throw const PermissionException('Tidak diizinkan mengubah setoran ini');
    }

    _data[idx] = setoran;
  }

  @override
  Future<void> delete(String setoranId, {required UserRole callerRole}) async {
    final setoran = _data.firstWhere(
      (s) => s.id == setoranId,
      orElse: () =>
          throw NotFoundException('Setoran tidak ditemukan: $setoranId'),
    );
    // BUG FIX: hanya bisa hapus draft/ditolak
    if (setoran.status == SetoranStatus.diterima) {
      throw const PermissionException(
          'Setoran yang sudah diterima tidak dapat dihapus');
    }
    _data.removeWhere((s) => s.id == setoranId);
  }
}

// ─── DummyAnnouncementRepository ─────────────────────────────────────────────

class DummyAnnouncementRepository implements AnnouncementRepository {
  static String _text = '';

  @override
  Future<String> get() async => _text;

  @override
  Future<void> set(String text) async => _text = text.trim();
}

// ─── DummyBudgetRepository ────────────────────────────────────────────────────

class DummyBudgetRepository implements BudgetRepository {
  static final Map<TransactionCategory, double> _budgets = {};

  @override
  Future<Map<TransactionCategory, double>> getAll() async =>
      Map.unmodifiable(_budgets);

  @override
  Future<void> set(TransactionCategory category, double amount) async {
    if (amount <= 0) {
      _budgets.remove(category);
    } else {
      _budgets[category] = amount;
    }
  }

  @override
  Future<void> clear(TransactionCategory category) async =>
      _budgets.remove(category);
}

// ─── DummyDataRepository ──────────────────────────────────────────────────────

class DummyDataRepository implements DataRepository {
  @override
  Future<void> clearAllData({required UserRole callerRole}) async {
    if (!callerRole.canExport) {
      throw const PermissionException(
          'Hanya Ketua/Bendahara yang dapat menghapus semua data');
    }
    DummyTransactionRepository.resetForTest();
    DummySetoranRepository.resetForTest();
    DummyAnnouncementRepository._text = '';
    DummyBudgetRepository._budgets.clear();
  }
}
