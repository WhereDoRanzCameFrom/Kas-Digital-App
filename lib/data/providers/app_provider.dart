import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../repositories/dummy_repositories.dart';
import '../../core/utils/formatters.dart';

class AppProvider extends ChangeNotifier {
  // ── Dependency Injection ───────────────────────────────────────────────────
  final AuthRepository _authRepo;
  final TransactionRepository _txRepo;
  final SetoranRepository _setoranRepo;
  final AnnouncementRepository _announcementRepo;
  final BudgetRepository _budgetRepo;
  final DataRepository _dataRepo;

  AppProvider({
    AuthRepository? authRepo,
    TransactionRepository? txRepo,
    SetoranRepository? setoranRepo,
    AnnouncementRepository? announcementRepo,
    BudgetRepository? budgetRepo,
    DataRepository? dataRepo,
  })  : _authRepo = authRepo ?? DummyAuthRepository(),
        _txRepo = txRepo ?? DummyTransactionRepository(),
        _setoranRepo = setoranRepo ?? DummySetoranRepository(),
        _announcementRepo = announcementRepo ?? DummyAnnouncementRepository(),
        _budgetRepo = budgetRepo ?? DummyBudgetRepository(),
        _dataRepo = dataRepo ?? DummyDataRepository();

  // ── Auth ──────────────────────────────────────────────────────────────────
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  List<UserModel> _allUsers = [];
  List<UserModel> get allUsers => _allUsers;

  bool _authLoading = false;
  bool get authLoading => _authLoading;

  String? _authError;
  String? get authError => _authError;

  Future<void> loadUsers() async {
    _allUsers = await _authRepo.getAllUsers();
    notifyListeners();
  }

  Future<bool> login(String userId, String pin) async {
    _authLoading = true;
    _authError = null;
    notifyListeners();

    final user = await _authRepo.login(userId, pin);

    _authLoading = false;
    if (user == null) {
      _authError = 'ID atau PIN salah';
      notifyListeners();
      return false;
    }

    _currentUser = user;
    await _loadTransactions();
    await _loadSetorans();
    await _loadAnnouncement();
    await _loadBudgets();
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    await _authRepo.logout();
    _currentUser = null;
    _draftTransactions.clear();
    notifyListeners();
  }

  // ── Transactions ──────────────────────────────────────────────────────────
  List<TransactionModel> _transactions = [];
  bool _txLoading = false;
  bool get txLoading => _txLoading;

  Future<void> _loadTransactions() async {
    _txLoading = true;
    _transactions = await _txRepo.getAll();
    _txLoading = false;
  }

  List<TransactionModel> get allTransactions {
    final sorted = List<TransactionModel>.from(_transactions);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  List<TransactionModel> get myTransactions {
    if (_currentUser == null) return [];
    if (_currentUser!.role.canViewAllTransactions) return allTransactions;
    return _transactions.where((t) => t.createdBy == _currentUser!.id).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<TransactionModel> get displayTransactions =>
      _currentUser?.role.canViewAllTransactions == true
          ? allTransactions
          : myTransactions;

  List<TransactionModel> filterTransactions({
    TransactionType? type,
    TransactionCategory? category,
    DateTime? from,
    DateTime? to,
    String? query,
  }) {
    return displayTransactions.where((t) {
      if (type != null && t.type != type) return false;
      if (category != null && t.category != category) return false;
      if (from != null && t.date.isBefore(from)) return false;
      if (to != null) {
        final toEndOfDay = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
        if (t.date.isAfter(toEndOfDay)) return false;
      }
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase().trim();
        final matchDesc = t.description.toLowerCase().contains(q);
        final matchCat = t.category.label.toLowerCase().contains(q);
        final matchName = t.createdByName.toLowerCase().contains(q);
        final matchRole = t.createdByRole.shortLabel.toLowerCase().contains(q);
        if (!matchDesc && !matchCat && !matchName && !matchRole) return false;
      }
      return true;
    }).toList();
  }

  Future<void> addTransaction(TransactionModel t) async {
    final caller = _currentUser;
    if (caller == null) {
      throw const PermissionException('Tidak ada user yang login');
    }

    if (!caller.role.canAddTransaction) {
      throw PermissionException(
          'Role ${caller.role.shortLabel} tidak dapat menambah transaksi');
    }

    if (t.type == TransactionType.keluar) {
      final currentSaldo = summary.totalSaldo;
      if (currentSaldo - t.amount < 0) {
        throw ValidationException(
          'Saldo tidak cukup. Saldo saat ini: ${currentSaldo.toStringAsFixed(0)}, '
          'dibutuhkan: ${t.amount.toStringAsFixed(0)}',
        );
      }
    }

    await _txRepo.add(t, callerRole: caller.role);
    _transactions.add(t);
    notifyListeners();
  }

  Future<void> updateTransaction(TransactionModel t) async {
    final caller = _currentUser;
    if (caller == null) {
      throw const PermissionException('Tidak ada user yang login');
    }
    await _txRepo.update(t, callerRole: caller.role);
    final idx = _transactions.indexWhere((e) => e.id == t.id);
    if (idx != -1) {
      _transactions[idx] = t;
    }
    notifyListeners();
  }

  Future<bool> deleteTransaction(String id) async {
    final caller = _currentUser;
    if (caller == null) return false;

    if (!canDeleteTransaction(id)) return false;

    try {
      await _txRepo.delete(id, callerRole: caller.role);
    } on PermissionException {
      return false;
    } on NotFoundException {
      _transactions.removeWhere((t) => t.id == id);
      notifyListeners();
      return true;
    }

    _transactions.removeWhere((t) => t.id == id);
    notifyListeners();
    return true;
  }

  bool canDeleteTransaction(String id) {
    final caller = _currentUser;
    if (caller == null || !caller.role.canDelete) return false;

    final tx = _transactions.firstWhere(
      (t) => t.id == id,
      orElse: () => _emptyTx(),
    );
    if (tx.id.isEmpty) return false;
    if (tx.setoranId == null) return true;

    final setoran = _setorans.firstWhere(
      (s) => s.id == tx.setoranId,
      orElse: () => _emptySetoran(),
    );
    return setoran.id.isEmpty || setoran.status != SetoranStatus.diterima;
  }

  // ── Summary ───────────────────────────────────────────────────────────────
  SummaryModel get summary => SummaryModel.fromTransactions(allTransactions);
  SummaryModel get mySummary => SummaryModel.fromTransactions(myTransactions);

  SummaryModel get weekSummary {
    final now = DateTime.now();
    final start = DateFormatter.startOfWeek(now);
    final end = DateFormatter.endOfWeek(now);
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
    final weekly = allTransactions
        .where((t) => !t.date.isBefore(start) && !t.date.isAfter(endOfDay))
        .toList();
    return SummaryModel.fromTransactions(weekly);
  }

  // ── Chart data ────────────────────────────────────────────────────────────
  List<WeeklyData> getLast4WeeksData() {
    final now = DateTime.now();
    return List.generate(4, (i) {
      final weekStart =
          DateFormatter.startOfWeek(now).subtract(Duration(days: 7 * (3 - i)));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final weekEndOfDay =
          DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59, 999);
      final weekTx = allTransactions.where(
          (t) => !t.date.isBefore(weekStart) && !t.date.isAfter(weekEndOfDay));
      double masuk = 0;
      double keluar = 0;
      for (final t in weekTx) {
        if (t.type == TransactionType.masuk) {
          masuk += t.amount;
        } else {
          keluar += t.amount;
        }
      }
      return WeeklyData(
        label: 'W${i + 1}',
        masuk: masuk,
        keluar: keluar,
        weekStart: weekStart,
      );
    });
  }

  // ── Setoran ───────────────────────────────────────────────────────────────
  List<SetoranModel> _setorans = [];

  Future<void> _loadSetorans() async {
    _setorans = await _setoranRepo.getAll();
  }

  List<SetoranModel> get allSetorans {
    final sorted = List<SetoranModel>.from(_setorans);
    sorted.sort((a, b) => b.tanggalSetor.compareTo(a.tanggalSetor));
    return sorted;
  }

  List<SetoranModel> get pendingSetorans =>
      allSetorans.where((s) => s.status == SetoranStatus.pending).toList();

  List<SetoranModel> get mySetorans {
    if (_currentUser == null) return [];
    return allSetorans.where((s) => s.fromUserId == _currentUser!.id).toList();
  }

  List<SetoranModel> filterSetorans({
    SetoranStatus? status,
    String? query,
  }) {
    return allSetorans.where((s) {
      if (status != null && s.status != status) return false;
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase().trim();
        final matchName = s.fromUserName.toLowerCase().contains(q);
        final matchRole = s.fromRole.shortLabel.toLowerCase().contains(q);
        final matchStatus = s.status.label.toLowerCase().contains(q);
        final matchCatatan = s.catatan?.toLowerCase().contains(q) ?? false;
        if (!matchName && !matchRole && !matchStatus && !matchCatatan) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  // ── Draft transactions ────────────────────────────────────────────────────
  final List<TransactionModel> _draftTransactions = [];
  List<TransactionModel> get draftTransactions => List.from(_draftTransactions);

  void addDraftTransaction(TransactionModel t) {
    final caller = _currentUser;
    if (caller == null || !caller.role.canSubmitSetoran) return;
    if (t.amount <= 0) return;
    _draftTransactions.add(t);
    notifyListeners();
  }

  void updateDraftTransaction(TransactionModel updated) {
    final idx = _draftTransactions.indexWhere((t) => t.id == updated.id);
    if (idx == -1) return;
    if (updated.amount <= 0) return;
    _draftTransactions[idx] = updated;
    notifyListeners();
  }

  void removeDraftTransaction(String id) {
    _draftTransactions.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void clearDraftTransactions() {
    _draftTransactions.clear();
    notifyListeners();
  }

  // ── Submit setoran ────────────────────────────────────────────────────────
  Future<bool> submitSetoran({String? catatan}) async {
    final caller = _currentUser;
    if (caller == null) return false;
    if (!caller.role.canSubmitSetoran) return false;
    if (_draftTransactions.isEmpty) return false;

    for (final t in _draftTransactions) {
      if (t.amount <= 0) return false;
    }

    final total =
        _draftTransactions.fold<double>(0, (sum, t) => sum + t.amount);
    if (total <= 0) return false;

    final catatanFinal =
        (catatan == null || catatan.trim().isEmpty) ? null : catatan.trim();

    final setoran = SetoranModel(
      id: 'setoran_${const Uuid().v4()}',
      fromUserId: caller.id,
      fromUserName: caller.name,
      fromRole: caller.role,
      transactions: List.from(_draftTransactions),
      totalAmount: total,
      tanggalSetor: DateTime.now(),
      catatan: catatanFinal,
      status: SetoranStatus.pending,
    );

    try {
      await _setoranRepo.save(setoran, callerRole: caller.role);
    } on PermissionException {
      return false;
    } on ValidationException {
      return false;
    }

    _setorans.add(setoran);
    _draftTransactions.clear();
    notifyListeners();
    return true;
  }

  // ── Konfirmasi / Tolak setoran (Bendahara) ────────────────────────────────
  Future<bool> konfirmasiSetoran(
    String setoranId, {
    String? catatan,
    bool tolak = false,
  }) async {
    final caller = _currentUser;
    if (caller == null) return false;
    if (!caller.role.canApproveSetoran) return false;

    final idx = _setorans.indexWhere((s) => s.id == setoranId);
    if (idx == -1) return false;

    final current = _setorans[idx];
    if (current.status != SetoranStatus.pending) return false;

    if (!tolak) {
      final newSaldo = summary.totalSaldo - current.totalAmount;
      if (newSaldo < 0) {
        debugPrint(
            'WARNING: Menerima setoran akan membuat saldo negatif: $newSaldo');
      }
    }

    final catatanFinal =
        (catatan == null || catatan.trim().isEmpty) ? null : catatan.trim();

    final updated = current.copyWith(
      status: tolak ? SetoranStatus.ditolak : SetoranStatus.diterima,
      catatanBendahara: catatanFinal,
      tanggalKonfirmasi: DateTime.now(),
    );

    try {
      await _setoranRepo.update(updated, callerRole: caller.role);
    } catch (_) {
      return false;
    }

    _setorans[idx] = updated;

    if (!tolak) {
      final addedIds = <String>[];
      try {
        for (final t in updated.transactions) {
          if (!_transactions.any((e) => e.id == t.id)) {
            await _txRepo.add(t, callerRole: caller.role);
            addedIds.add(t.id);
            _transactions.add(t);
          }
        }
      } catch (_) {
        // Rollback transaksi yang sudah masuk
        for (final id in addedIds) {
          _transactions.removeWhere((t) => t.id == id);
        }
        // Rollback status setoran ke pending
        _setorans[idx] = current;
        try {
          await _setoranRepo.update(current, callerRole: caller.role);
        } catch (_) {}
        notifyListeners();
        return false;
      }
    }

    notifyListeners();
    return true;
  }

  // ── Resubmit setoran yang ditolak ─────────────────────────────────────────
  Future<bool> resubmitSetoran(
    String setoranId, {
    List<TransactionModel>? updatedTransactions,
    String? catatan,
  }) async {
    final caller = _currentUser;
    if (caller == null) return false;
    if (!caller.role.canSubmitSetoran) return false;

    final idx = _setorans.indexWhere((s) => s.id == setoranId);
    if (idx == -1) return false;

    final current = _setorans[idx];
    if (!current.isEditable) return false;
    if (current.fromUserId != caller.id) return false;

    final txList = updatedTransactions ?? current.transactions;
    if (txList.isEmpty) return false;

    for (final t in txList) {
      if (t.amount <= 0) return false;
    }

    final total = txList.fold<double>(0, (sum, t) => sum + t.amount);

    final catatanFinal =
        (catatan == null || catatan.trim().isEmpty) ? null : catatan.trim();

    // Buat objek baru langsung agar catatanBendahara & tanggalKonfirmasi
    // benar-benar null (bukan sekadar tidak diubah lewat copyWith)
    final updated = SetoranModel(
      id: current.id,
      fromUserId: current.fromUserId,
      fromUserName: current.fromUserName,
      fromRole: current.fromRole,
      transactions: txList,
      totalAmount: total,
      tanggalSetor: DateTime.now(),
      catatan: catatanFinal,
      status: SetoranStatus.pending,
      catatanBendahara: null,
      tanggalKonfirmasi: null,
    );

    try {
      await _setoranRepo.update(updated, callerRole: caller.role);
    } catch (_) {
      return false;
    }

    _setorans[idx] = updated;
    notifyListeners();
    return true;
  }

  // ── Announcement ──────────────────────────────────────────────────────────
  String _pengumuman = '';
  String get pengumuman => _pengumuman;

  Future<void> _loadAnnouncement() async {
    _pengumuman = await _announcementRepo.get();
  }

  Future<void> setPengumuman(String teks) async {
    final caller = _currentUser;
    if (caller == null) return;
    if (!caller.role.canExport) return;
    await _announcementRepo.set(teks);
    _pengumuman = teks.trim();
    notifyListeners();
  }

  // ── Budget ────────────────────────────────────────────────────────────────
  Map<TransactionCategory, double> _budget = {};
  Map<TransactionCategory, double> get budget => Map.unmodifiable(_budget);

  Future<void> _loadBudgets() async {
    final loaded = await _budgetRepo.getAll();
    _budget = Map.from(loaded);
  }

  double getBudget(TransactionCategory cat) => _budget[cat] ?? 0;

  Future<void> setBudget(TransactionCategory cat, double amount) async {
    final caller = _currentUser;
    if (caller == null) return;
    if (!caller.role.canExport) return;
    await _budgetRepo.set(cat, amount);
    if (amount <= 0) {
      _budget.remove(cat);
    } else {
      _budget[cat] = amount;
    }
    notifyListeners();
  }

  Future<void> clearBudget(TransactionCategory cat) async {
    final caller = _currentUser;
    if (caller == null) return;
    if (!caller.role.canExport) return;
    await _budgetRepo.clear(cat);
    _budget.remove(cat);
    notifyListeners();
  }

  // ── Clear All Data ───────────────────────────────────────────────────────────
  bool _clearLoading = false;
  bool get clearLoading => _clearLoading;

  /// Hapus semua transaksi, setoran, dan config.
  /// User tidak ikut dihapus. Hanya Ketua/Bendahara yang bisa.
  Future<bool> clearAllData() async {
    final caller = _currentUser;
    if (caller == null) return false;
    if (!caller.role.canExport) return false;

    _clearLoading = true;
    notifyListeners();

    try {
      await _dataRepo.clearAllData(callerRole: caller.role);
      // Reset state lokal
      _transactions = [];
      _setorans = [];
      _draftTransactions.clear();
      _pengumuman = '';
      _budget = {};
      _clearLoading = false;
      notifyListeners();
      return true;
    } catch (_) {
      _clearLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static TransactionModel _emptyTx() => TransactionModel(
        id: '',
        type: TransactionType.masuk,
        category: TransactionCategory.lainnya,
        amount: 0,
        description: '',
        date: DateTime.now(),
        createdBy: '',
        createdByName: '',
        createdByRole: UserRole.konsumsi,
      );

  static SetoranModel _emptySetoran() => SetoranModel(
        id: '',
        fromUserId: '',
        fromUserName: '',
        fromRole: UserRole.konsumsi,
        transactions: [],
        totalAmount: 0,
        tanggalSetor: DateTime.now(),
      );
}
