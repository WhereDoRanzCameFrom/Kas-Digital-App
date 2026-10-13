import '../models/models.dart';

// ─── Auth Repository ──────────────────────────────────────────────────────────
// Firebase-prep: implementasi Firebase akan menggunakan signInWithEmailAndPassword
// atau signInAnonymously + custom claims untuk role.

abstract class AuthRepository {
  /// Login dengan userId + PIN. Return UserModel jika sukses, null jika gagal.
  Future<UserModel?> login(String userId, String pin);

  /// Logout user saat ini.
  Future<void> logout();

  /// Ambil semua user (untuk UI pilih akun).
  Future<List<UserModel>> getAllUsers();
}

// ─── Transaction Repository ───────────────────────────────────────────────────
// Firebase-prep: implementasi Firestore akan menggunakan:
//   - collection('transactions').doc(id)
//   - transaction.createdAt sebagai Timestamp Firestore
//   - realtime listener via snapshots()

abstract class TransactionRepository {
  /// Ambil semua transaksi (untuk bendahara/ketua).
  Future<List<TransactionModel>> getAll();

  /// Ambil transaksi milik user tertentu.
  Future<List<TransactionModel>> getByUser(String userId);

  /// Tambah transaksi baru. Return id transaksi yang tersimpan.
  /// [callerRole] digunakan untuk validasi permission di level repository.
  Future<String> add(TransactionModel transaction, {required UserRole callerRole});

  /// Update transaksi yang sudah ada.
  Future<void> update(TransactionModel transaction, {required UserRole callerRole});

  /// Hapus transaksi. Melempar [PermissionException] jika tidak diizinkan.
  Future<void> delete(String transactionId, {required UserRole callerRole});
}

// ─── Setoran Repository ───────────────────────────────────────────────────────
// Firebase-prep: implementasi Firestore akan menggunakan:
//   - collection('setorans').doc(id)
//   - subcollection('transactions') atau embed sebagai array
//   - status sebagai string field yang mudah di-query

abstract class SetoranRepository {
  /// Ambil semua setoran (untuk bendahara & ketua).
  Future<List<SetoranModel>> getAll();

  /// Ambil setoran milik user tertentu.
  Future<List<SetoranModel>> getByUser(String userId);

  /// Simpan setoran baru (status draft atau langsung pending).
  /// [callerRole] harus canSubmitSetoran untuk sukses.
  Future<String> save(SetoranModel setoran, {required UserRole callerRole});

  /// Update status/catatan setoran (konfirmasi/tolak/revisi).
  /// Approve/reject hanya untuk [callerRole] == bendahara.
  Future<void> update(SetoranModel setoran, {required UserRole callerRole});

  /// Hapus setoran (hanya yang masih draft/ditolak).
  Future<void> delete(String setoranId, {required UserRole callerRole});
}

// ─── Announcement Repository ─────────────────────────────────────────────────
// Firebase-prep: simpan di collection('config').doc('pengumuman').field('text')

abstract class AnnouncementRepository {
  Future<String> get();

  /// Hanya ketua & bendahara yang boleh set — validasi di AppProvider.
  Future<void> set(String text);
}

// ─── Budget Repository ────────────────────────────────────────────────────────
// Firebase-prep: simpan di collection('config').doc('budget') sebagai map

abstract class BudgetRepository {
  Future<Map<TransactionCategory, double>> getAll();

  /// Hanya bendahara/ketua yang boleh set — validasi di AppProvider.
  Future<void> set(TransactionCategory category, double amount);

  Future<void> clear(TransactionCategory category);
}

// ─── Exceptions ──────────────────────────────────────────────────────────────

class PermissionException implements Exception {
  final String message;
  const PermissionException(this.message);
  @override
  String toString() => 'PermissionException: $message';
}

class NotFoundException implements Exception {
  final String message;
  const NotFoundException(this.message);
  @override
  String toString() => 'NotFoundException: $message';
}

class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);
  @override
  String toString() => 'ValidationException: $message';
}

// ─── Data Repository ──────────────────────────────────────────────────────────
// Firebase-prep: hapus semua data operasional (transaksi, setoran, config)
// User tidak ikut dihapus.

abstract class DataRepository {
  /// Hapus semua transaksi, setoran, dan config (budget + announcement).
  /// Hanya boleh dipanggil oleh Ketua atau Bendahara.
  Future<void> clearAllData({required UserRole callerRole});
}
