import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum UserRole {
  ketua,
  bendahara,
  wakil,
  sekretaris,
  humas,
  pdd,
  perlengkapan,
  konsumsi;

  String get label {
    switch (this) {
      case UserRole.ketua:        return 'Ketua (Audit)';
      case UserRole.bendahara:    return 'Bendahara';
      case UserRole.wakil:        return 'Wakil Ketua';
      case UserRole.sekretaris:   return 'Sekretaris';
      case UserRole.humas:        return 'Humas';
      case UserRole.pdd:          return 'PDD';
      case UserRole.perlengkapan: return 'Perlengkapan';
      case UserRole.konsumsi:     return 'Konsumsi';
    }
  }

  String get shortLabel {
    switch (this) {
      case UserRole.ketua:        return 'Ketua';
      case UserRole.bendahara:    return 'Bendahara';
      case UserRole.wakil:        return 'Wakil';
      case UserRole.sekretaris:   return 'Sekretaris';
      case UserRole.humas:        return 'Humas';
      case UserRole.pdd:          return 'PDD';
      case UserRole.perlengkapan: return 'Perlengkapan';
      case UserRole.konsumsi:     return 'Konsumsi';
    }
  }

  Color get color {
    switch (this) {
      case UserRole.ketua:        return AppColors.roleKetua;
      case UserRole.bendahara:    return AppColors.roleBendahara;
      case UserRole.wakil:        return AppColors.roleWakil;
      case UserRole.sekretaris:   return AppColors.roleSekretaris;
      case UserRole.humas:        return AppColors.roleHumas;
      case UserRole.pdd:          return AppColors.rolePdd;
      case UserRole.perlengkapan: return AppColors.rolePerlengkapan;
      case UserRole.konsumsi:     return AppColors.roleKonsumsi;
    }
  }

  bool get canAddTransaction =>
      this == UserRole.bendahara ||
      this == UserRole.wakil ||
      this == UserRole.sekretaris ||
      this == UserRole.humas ||
      this == UserRole.pdd ||
      this == UserRole.perlengkapan ||
      this == UserRole.konsumsi;

  bool get canViewAllTransactions =>
      this == UserRole.ketua ||
      this == UserRole.bendahara ||
      this == UserRole.wakil ||
      this == UserRole.sekretaris ||
      this == UserRole.humas ||
      this == UserRole.pdd ||
      this == UserRole.perlengkapan ||
      this == UserRole.konsumsi;

  bool get canSubmitSetoran =>
      this == UserRole.wakil ||
      this == UserRole.sekretaris ||
      this == UserRole.humas ||
      this == UserRole.pdd ||
      this == UserRole.perlengkapan ||
      this == UserRole.konsumsi;

  // BUG FIX: hanya bendahara yang boleh manage setoran
  bool get canManageSetoran => this == UserRole.bendahara;

  // BUG FIX: hanya bendahara yang boleh approve/reject setoran
  bool get canApproveSetoran => this == UserRole.bendahara;

  // BUG FIX: hanya bendahara yang boleh mengubah kas utama (masuk/keluar langsung)
  bool get canModifyMainKas => this == UserRole.bendahara;

  bool get canExport =>
      this == UserRole.ketua || this == UserRole.bendahara;

  bool get canDelete => this == UserRole.ketua || this == UserRole.bendahara;

  List<TransactionCategory>? get allowedCategories {
    switch (this) {
      case UserRole.perlengkapan:
        return [TransactionCategory.perlengkapan, TransactionCategory.lainnya];
      case UserRole.konsumsi:
        return [TransactionCategory.konsumsi, TransactionCategory.lainnya];
      case UserRole.wakil:
      case UserRole.sekretaris:
      case UserRole.humas:
      case UserRole.pdd:
        return null; // semua kategori boleh
      default:
        return null;
    }
  }

  String get value => name;

  static UserRole fromValue(String v) =>
      UserRole.values.firstWhere((e) => e.name == v, orElse: () => UserRole.konsumsi);
}

enum TransactionType {
  masuk,
  keluar;

  String get label => this == TransactionType.masuk ? 'Kas Masuk' : 'Kas Keluar';

  String get value => name;
  static TransactionType fromValue(String v) =>
      TransactionType.values.firstWhere((e) => e.name == v, orElse: () => TransactionType.keluar);
}

enum TransactionCategory {
  konsumsi,
  perlengkapan,
  transportasi,
  dokumentasi,
  programKerja,
  lainnya;

  String get label {
    switch (this) {
      case TransactionCategory.konsumsi:     return 'Konsumsi';
      case TransactionCategory.perlengkapan: return 'Perlengkapan';
      case TransactionCategory.transportasi: return 'Transportasi';
      case TransactionCategory.dokumentasi:  return 'Dokumentasi';
      case TransactionCategory.programKerja: return 'Program Kerja';
      case TransactionCategory.lainnya:      return 'Lainnya';
    }
  }

  Color get color {
    switch (this) {
      case TransactionCategory.konsumsi:     return AppColors.catKonsumsi;
      case TransactionCategory.perlengkapan: return AppColors.catPerlengkapan;
      case TransactionCategory.transportasi: return AppColors.catTransportasi;
      case TransactionCategory.dokumentasi:  return AppColors.catDokumentasi;
      case TransactionCategory.programKerja: return AppColors.catProgramKerja;
      case TransactionCategory.lainnya:      return AppColors.catLainnya;
    }
  }

  IconData get icon {
    switch (this) {
      case TransactionCategory.konsumsi:     return Icons.restaurant_outlined;
      case TransactionCategory.perlengkapan: return Icons.inventory_2_outlined;
      case TransactionCategory.transportasi: return Icons.directions_car_outlined;
      case TransactionCategory.dokumentasi:  return Icons.photo_camera_outlined;
      case TransactionCategory.programKerja: return Icons.assignment_outlined;
      case TransactionCategory.lainnya:      return Icons.more_horiz;
    }
  }

  String get value => name;
  static TransactionCategory fromValue(String v) =>
      TransactionCategory.values.firstWhere((e) => e.name == v, orElse: () => TransactionCategory.lainnya);
}

enum SetoranStatus {
  draft,
  pending,
  diterima,
  ditolak;

  String get label {
    switch (this) {
      case SetoranStatus.draft:    return 'Draft';
      case SetoranStatus.pending:  return 'Menunggu';
      case SetoranStatus.diterima: return 'Diterima';
      case SetoranStatus.ditolak:  return 'Ditolak';
    }
  }

  Color get color {
    switch (this) {
      case SetoranStatus.draft:    return AppColors.textSecondary;
      case SetoranStatus.pending:  return AppColors.statusPending;
      case SetoranStatus.diterima: return AppColors.income;
      case SetoranStatus.ditolak:  return AppColors.expense;
    }
  }

  String get value => name;
  static SetoranStatus fromValue(String v) =>
      SetoranStatus.values.firstWhere((e) => e.name == v, orElse: () => SetoranStatus.pending);
}

// ─── Models ───────────────────────────────────────────────────────────────────

class UserModel {
  final String id;
  final String name;
  // BUG FIX: pin tidak dikirim ke Firestore dalam kondisi production
  // Gunakan Firebase Auth untuk autentikasi — pin hanya untuk dummy
  final String pin;
  final UserRole role;

  const UserModel({
    required this.id,
    required this.name,
    required this.pin,
    required this.role,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty
        ? (name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase())
        : '??';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: (json['id'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        // BUG FIX: pin tidak disimpan di Firestore, default empty
        pin: (json['pin'] as String?) ?? '',
        role: UserRole.fromValue((json['role'] as String?) ?? 'konsumsi'),
      );

  // BUG FIX (Firebase-prep): jangan simpan pin ke Firestore
  // gunakan toJsonSafe() untuk Firestore dan toJson() hanya untuk dummy
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'pin': pin,
        'role': role.value,
      };

  /// Firestore-safe: PIN tidak disimpan ke cloud
  Map<String, dynamic> toJsonSafe() => {
        'id': id,
        'name': name,
        'role': role.value,
      };

  UserModel copyWith({
    String? id,
    String? name,
    String? pin,
    UserRole? role,
  }) =>
      UserModel(
        id: id ?? this.id,
        name: name ?? this.name,
        pin: pin ?? this.pin,
        role: role ?? this.role,
      );
}

class TransactionModel {
  final String id;
  final TransactionType type;
  final TransactionCategory category;
  final double amount;
  final String description;
  final DateTime date;
  final String createdBy;
  final String createdByName;
  final UserRole createdByRole;
  final String? setoranId;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
    required this.createdBy,
    required this.createdByName,
    required this.createdByRole,
    this.setoranId,
  });

  // BUG FIX: null safety — semua field dicast dengan fallback
  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: (json['id'] as String?) ?? '',
        type: TransactionType.fromValue((json['type'] as String?) ?? 'keluar'),
        category: TransactionCategory.fromValue((json['category'] as String?) ?? 'lainnya'),
        // BUG FIX: amount bisa datang sebagai int dari Firestore
        amount: ((json['amount'] as num?) ?? 0).toDouble(),
        description: (json['description'] as String?) ?? '',
        // BUG FIX: Firestore mungkin simpan Timestamp, parse dari millis jika perlu
        date: _parseDate(json['date']),
        createdBy: (json['createdBy'] as String?) ?? '',
        createdByName: (json['createdByName'] as String?) ?? '',
        createdByRole: UserRole.fromValue((json['createdByRole'] as String?) ?? 'konsumsi'),
        setoranId: json['setoranId'] as String?,
      );

  /// Parse tanggal dari ISO string atau epoch millis (Firestore Timestamp.toMillis())
  static DateTime _parseDate(dynamic raw) {
    if (raw == null) return DateTime.now();
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    return DateTime.now();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.value,
        'category': category.value,
        'amount': amount,
        'description': description,
        // BUG FIX (Firebase-prep): simpan sebagai ISO string; saat pakai Firestore
        // ganti dengan Timestamp.fromDate(date)
        'date': date.toIso8601String(),
        'createdBy': createdBy,
        'createdByName': createdByName,
        'createdByRole': createdByRole.value,
        if (setoranId != null) 'setoranId': setoranId,
      };

  // BUG FIX: copyWith bisa null-kan setoranId dengan sentinel
  TransactionModel copyWith({
    String? id,
    TransactionType? type,
    TransactionCategory? category,
    double? amount,
    String? description,
    DateTime? date,
    String? createdBy,
    String? createdByName,
    UserRole? createdByRole,
    Object? setoranId = _sentinel,
  }) =>
      TransactionModel(
        id: id ?? this.id,
        type: type ?? this.type,
        category: category ?? this.category,
        amount: amount ?? this.amount,
        description: description ?? this.description,
        date: date ?? this.date,
        createdBy: createdBy ?? this.createdBy,
        createdByName: createdByName ?? this.createdByName,
        createdByRole: createdByRole ?? this.createdByRole,
        setoranId: setoranId == _sentinel
            ? this.setoranId
            : setoranId as String?,
      );
}

/// Sentinel untuk membedakan "tidak di-pass" vs "di-pass null" di copyWith
const Object _sentinel = Object();

class SetoranModel {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final UserRole fromRole;
  final List<TransactionModel> transactions;
  final double totalAmount;
  final DateTime tanggalSetor;
  final String? catatan;
  final SetoranStatus status;
  final String? catatanBendahara;
  final DateTime? tanggalKonfirmasi;

  const SetoranModel({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.fromRole,
    required this.transactions,
    required this.totalAmount,
    required this.tanggalSetor,
    this.catatan,
    this.status = SetoranStatus.pending,
    this.catatanBendahara,
    this.tanggalKonfirmasi,
  });

  // BUG FIX: null safety lengkap di fromJson
  factory SetoranModel.fromJson(Map<String, dynamic> json) => SetoranModel(
        id: (json['id'] as String?) ?? '',
        fromUserId: (json['fromUserId'] as String?) ?? '',
        fromUserName: (json['fromUserName'] as String?) ?? '',
        fromRole: UserRole.fromValue((json['fromRole'] as String?) ?? 'konsumsi'),
        transactions: ((json['transactions'] as List<dynamic>?) ?? [])
            .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalAmount: ((json['totalAmount'] as num?) ?? 0).toDouble(),
        tanggalSetor: TransactionModel._parseDate(json['tanggalSetor']),
        catatan: json['catatan'] as String?,
        status: SetoranStatus.fromValue((json['status'] as String?) ?? 'pending'),
        catatanBendahara: json['catatanBendahara'] as String?,
        tanggalKonfirmasi: json['tanggalKonfirmasi'] != null
            ? TransactionModel._parseDate(json['tanggalKonfirmasi'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fromUserId': fromUserId,
        'fromUserName': fromUserName,
        'fromRole': fromRole.value,
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'totalAmount': totalAmount,
        'tanggalSetor': tanggalSetor.toIso8601String(),
        if (catatan != null) 'catatan': catatan,
        'status': status.value,
        if (catatanBendahara != null) 'catatanBendahara': catatanBendahara,
        if (tanggalKonfirmasi != null)
          'tanggalKonfirmasi': tanggalKonfirmasi!.toIso8601String(),
      };

  // BUG FIX: copyWith bisa null-kan catatanBendahara & tanggalKonfirmasi
  SetoranModel copyWith({
    String? id,
    String? fromUserId,
    String? fromUserName,
    UserRole? fromRole,
    List<TransactionModel>? transactions,
    double? totalAmount,
    DateTime? tanggalSetor,
    Object? catatan = _sentinel,
    SetoranStatus? status,
    Object? catatanBendahara = _sentinel,
    Object? tanggalKonfirmasi = _sentinel,
  }) =>
      SetoranModel(
        id: id ?? this.id,
        fromUserId: fromUserId ?? this.fromUserId,
        fromUserName: fromUserName ?? this.fromUserName,
        fromRole: fromRole ?? this.fromRole,
        transactions: transactions ?? this.transactions,
        totalAmount: totalAmount ?? this.totalAmount,
        tanggalSetor: tanggalSetor ?? this.tanggalSetor,
        catatan: catatan == _sentinel ? this.catatan : catatan as String?,
        status: status ?? this.status,
        catatanBendahara: catatanBendahara == _sentinel
            ? this.catatanBendahara
            : catatanBendahara as String?,
        tanggalKonfirmasi: tanggalKonfirmasi == _sentinel
            ? this.tanggalKonfirmasi
            : tanggalKonfirmasi as DateTime?,
      );

  bool get isEditable =>
      status == SetoranStatus.draft || status == SetoranStatus.ditolak;
}

class SummaryModel {
  final double totalSaldo;
  final double totalMasuk;
  final double totalKeluar;
  final Map<TransactionCategory, double> perCategory;
  final int totalTransaksi;

  const SummaryModel({
    required this.totalSaldo,
    required this.totalMasuk,
    required this.totalKeluar,
    required this.perCategory,
    required this.totalTransaksi,
  });

  factory SummaryModel.fromTransactions(List<TransactionModel> transactions) {
    double masuk = 0;
    double keluar = 0;
    final Map<TransactionCategory, double> perCat = {};

    for (final t in transactions) {
      // BUG FIX: validasi amount positif sebelum diakumulasi
      final amount = t.amount < 0 ? 0.0 : t.amount;
      if (t.type == TransactionType.masuk) {
        masuk += amount;
      } else {
        keluar += amount;
        perCat[t.category] = (perCat[t.category] ?? 0) + amount;
      }
    }

    return SummaryModel(
      totalSaldo: masuk - keluar,
      totalMasuk: masuk,
      totalKeluar: keluar,
      perCategory: perCat,
      totalTransaksi: transactions.length,
    );
  }

  static SummaryModel empty() => const SummaryModel(
        totalSaldo: 0,
        totalMasuk: 0,
        totalKeluar: 0,
        perCategory: {},
        totalTransaksi: 0,
      );
}

class WeeklyData {
  final String label;
  final double masuk;
  final double keluar;
  final DateTime weekStart;

  const WeeklyData({
    required this.label,
    required this.masuk,
    required this.keluar,
    required this.weekStart,
  });
}
