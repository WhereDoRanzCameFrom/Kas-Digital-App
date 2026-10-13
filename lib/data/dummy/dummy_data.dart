import '../models/models.dart';

class DummyData {
  DummyData._();

  static const List<UserModel> users = [
    UserModel(id: 'u1',  name: 'Rangga Saputra', pin: '1111', role: UserRole.ketua),
    UserModel(id: 'u2',  name: 'Fauziah',         pin: '2222', role: UserRole.bendahara),
    UserModel(id: 'u3',  name: 'Belva',            pin: '3333', role: UserRole.wakil),
    UserModel(id: 'u4',  name: 'Chusnul',          pin: '4444', role: UserRole.sekretaris),
    UserModel(id: 'u5',  name: 'Andini',           pin: '5555', role: UserRole.humas),
    UserModel(id: 'u6',  name: 'John',             pin: '6666', role: UserRole.humas),
    UserModel(id: 'u7',  name: 'Annisa',           pin: '7777', role: UserRole.pdd),
    UserModel(id: 'u8',  name: 'Vebri',            pin: '8888', role: UserRole.pdd),
    UserModel(id: 'u9',  name: 'Isna',             pin: '9999', role: UserRole.perlengkapan),
    UserModel(id: 'u10', name: 'Ucup',             pin: '0000', role: UserRole.perlengkapan),
    UserModel(id: 'u11', name: 'Anggi',            pin: '1212', role: UserRole.konsumsi),
    UserModel(id: 'u12', name: 'Anna',             pin: '3434', role: UserRole.konsumsi),
  ];

  /// Semua tanggal dibuat RELATIF ke DateTime.now() supaya
  /// grafik & pie chart selalu terisi meskipun tanpa Firebase.
  static List<TransactionModel> get transactions {
    final now = DateTime.now();
    return [
      // ── Kas masuk (bendahara)
      TransactionModel(
        id: 't1',
        type: TransactionType.masuk,
        category: TransactionCategory.lainnya,
        amount: 2000000,
        description: 'Dana Kampus',
        date: now.subtract(const Duration(days: 20, hours: 3)),
        createdBy: 'u2',
        createdByName: 'Fauziah',
        createdByRole: UserRole.bendahara,
      ),
      TransactionModel(
        id: 't2',
        type: TransactionType.masuk,
        category: TransactionCategory.lainnya,
        amount: 1500000,
        description: 'Dana Sponsor',
        date: now.subtract(const Duration(days: 3)),
        createdBy: 'u2',
        createdByName: 'Fauziah',
        createdByRole: UserRole.bendahara,
      ),
      TransactionModel(
        id: 't3',
        type: TransactionType.masuk,
        category: TransactionCategory.lainnya,
        amount: 750000,
        description: 'Iuran Anggota',
        date: now.subtract(const Duration(days: 4, hours: 1)),
        createdBy: 'u2',
        createdByName: 'Fauziah',
        createdByRole: UserRole.bendahara,
      ),
      TransactionModel(
        id: 't4',
        type: TransactionType.masuk,
        category: TransactionCategory.lainnya,
        amount: 3500000,
        description: 'Dana Pemda',
        date: now.subtract(const Duration(days: 14)),
        createdBy: 'u2',
        createdByName: 'Fauziah',
        createdByRole: UserRole.bendahara,
      ),
      // ── Kas keluar divisi perlengkapan (sudah diterima bendahara)
      TransactionModel(
        id: 't5',
        type: TransactionType.keluar,
        category: TransactionCategory.perlengkapan,
        amount: 85000,
        description: 'Beli Alat Kebersihan',
        date: now.subtract(const Duration(days: 4, hours: 5)),
        createdBy: 'u3',
        createdByName: 'Isna',
        createdByRole: UserRole.perlengkapan,
        setoranId: 's1',
      ),
      TransactionModel(
        id: 't6',
        type: TransactionType.keluar,
        category: TransactionCategory.perlengkapan,
        amount: 60000,
        description: 'Cetak Banner',
        date: now.subtract(const Duration(days: 5, hours: 2)),
        createdBy: 'u3',
        createdByName: 'Isna',
        createdByRole: UserRole.perlengkapan,
        setoranId: 's1',
      ),
      // ── Kas keluar divisi konsumsi (sudah diterima)
      TransactionModel(
        id: 't7',
        type: TransactionType.keluar,
        category: TransactionCategory.konsumsi,
        amount: 235000,
        description: 'Beli Bahan Makan',
        date: now.subtract(const Duration(days: 2, hours: 3)),
        createdBy: 'u4',
        createdByName: 'Anggi',
        createdByRole: UserRole.konsumsi,
        setoranId: 's2',
      ),
      TransactionModel(
        id: 't9',
        type: TransactionType.keluar,
        category: TransactionCategory.konsumsi,
        amount: 45000,
        description: 'Beli Air Mineral',
        date: now.subtract(const Duration(days: 4, hours: 8)),
        createdBy: 'u4',
        createdByName: 'Anggi',
        createdByRole: UserRole.konsumsi,
        setoranId: 's2',
      ),
      // ── Kas keluar langsung bendahara
      TransactionModel(
        id: 't8',
        type: TransactionType.keluar,
        category: TransactionCategory.transportasi,
        amount: 150000,
        description: 'Transportasi ke Lokasi',
        date: now.subtract(const Duration(days: 3, hours: 6)),
        createdBy: 'u2',
        createdByName: 'Fauziah',
        createdByRole: UserRole.bendahara,
      ),
      // ── Kas keluar perlengkapan (pending setoran)
      TransactionModel(
        id: 't10',
        type: TransactionType.keluar,
        category: TransactionCategory.perlengkapan,
        amount: 120000,
        description: 'Beli Alat Tulis',
        date: now.subtract(const Duration(days: 1, hours: 2)),
        createdBy: 'u5',
        createdByName: 'Ucup',
        createdByRole: UserRole.perlengkapan,
        setoranId: 's3',
      ),
      // ── Tambahan transaksi minggu ini supaya grafik terisi
      TransactionModel(
        id: 't11',
        type: TransactionType.keluar,
        category: TransactionCategory.programKerja,
        amount: 320000,
        description: 'Kebutuhan Program Kerja',
        date: now.subtract(const Duration(days: 1)),
        createdBy: 'u2',
        createdByName: 'Fauziah',
        createdByRole: UserRole.bendahara,
      ),
      TransactionModel(
        id: 't12',
        type: TransactionType.keluar,
        category: TransactionCategory.dokumentasi,
        amount: 75000,
        description: 'Cetak Foto Kegiatan',
        date: now.subtract(const Duration(hours: 5)),
        createdBy: 'u2',
        createdByName: 'Fauziah',
        createdByRole: UserRole.bendahara,
      ),

      // ── Data 3 minggu lalu (W1) — supaya grafik bar chart terisi
      TransactionModel(
        id: 't13',
        type: TransactionType.masuk,
        category: TransactionCategory.lainnya,
        amount: 1000000,
        description: 'Iuran Tambahan',
        date: now.subtract(const Duration(days: 21)),
        createdBy: 'u2',
        createdByName: 'Fauziah',
        createdByRole: UserRole.bendahara,
      ),
      TransactionModel(
        id: 't14',
        type: TransactionType.keluar,
        category: TransactionCategory.konsumsi,
        amount: 180000,
        description: 'Konsumsi Rapat Perdana',
        date: now.subtract(const Duration(days: 20)),
        createdBy: 'u2',
        createdByName: 'Fauziah',
        createdByRole: UserRole.bendahara,
      ),
      TransactionModel(
        id: 't15',
        type: TransactionType.keluar,
        category: TransactionCategory.transportasi,
        amount: 95000,
        description: 'Survei Lokasi KKN',
        date: now.subtract(const Duration(days: 19)),
        createdBy: 'u2',
        createdByName: 'Fauziah',
        createdByRole: UserRole.bendahara,
      ),

      // ── Data 2 minggu lalu (W2)
      TransactionModel(
        id: 't16',
        type: TransactionType.masuk,
        category: TransactionCategory.lainnya,
        amount: 500000,
        description: 'Donasi Warga',
        date: now.subtract(const Duration(days: 14)),
        createdBy: 'u2',
        createdByName: 'Fauziah',
        createdByRole: UserRole.bendahara,
      ),
      TransactionModel(
        id: 't17',
        type: TransactionType.keluar,
        category: TransactionCategory.perlengkapan,
        amount: 250000,
        description: 'Pembelian Alat Tulis Kantor',
        date: now.subtract(const Duration(days: 13)),
        createdBy: 'u2',
        createdByName: 'Fauziah',
        createdByRole: UserRole.bendahara,
      ),
      TransactionModel(
        id: 't18',
        type: TransactionType.keluar,
        category: TransactionCategory.programKerja,
        amount: 400000,
        description: 'Bahan Proker Bersih Desa',
        date: now.subtract(const Duration(days: 12)),
        createdBy: 'u2',
        createdByName: 'Fauziah',
        createdByRole: UserRole.bendahara,
      ),

      // ── Data minggu lalu (W3)
      TransactionModel(
        id: 't19',
        type: TransactionType.masuk,
        category: TransactionCategory.lainnya,
        amount: 750000,
        description: 'Dana Tambahan Pemda',
        date: now.subtract(const Duration(days: 8)),
        createdBy: 'u2',
        createdByName: 'Fauziah',
        createdByRole: UserRole.bendahara,
      ),
      TransactionModel(
        id: 't20',
        type: TransactionType.keluar,
        category: TransactionCategory.konsumsi,
        amount: 310000,
        description: 'Konsumsi Kerja Bakti',
        date: now.subtract(const Duration(days: 7)),
        createdBy: 'u2',
        createdByName: 'Fauziah',
        createdByRole: UserRole.bendahara,
      ),
      TransactionModel(
        id: 't21',
        type: TransactionType.keluar,
        category: TransactionCategory.dokumentasi,
        amount: 120000,
        description: 'Sewa Kamera Dokumentasi',
        date: now.subtract(const Duration(days: 7)),
        createdBy: 'u2',
        createdByName: 'Fauziah',
        createdByRole: UserRole.bendahara,
      ),
    ];
  }

  static List<SetoranModel> get setorans {
    final now = DateTime.now();
    final txAll = transactions;

    final txS1 = txAll.where((t) => t.setoranId == 's1').toList();
    final txS2 = txAll.where((t) => t.setoranId == 's2').toList();
    final txS3 = txAll.where((t) => t.setoranId == 's3').toList();

    return [
      SetoranModel(
        id: 's1',
        fromUserId: 'u3',
        fromUserName: 'Isna',
        fromRole: UserRole.perlengkapan,
        transactions: txS1,
        totalAmount: txS1.fold(0, (s, t) => s + t.amount),
        tanggalSetor: now.subtract(const Duration(days: 4)),
        catatan: 'Laporan perlengkapan harian',
        status: SetoranStatus.diterima,
        catatanBendahara: 'OK, sudah dicatat',
        tanggalKonfirmasi: now.subtract(const Duration(days: 3, hours: 22)),
      ),
      SetoranModel(
        id: 's2',
        fromUserId: 'u4',
        fromUserName: 'Anggi',
        fromRole: UserRole.konsumsi,
        transactions: txS2,
        totalAmount: txS2.fold(0, (s, t) => s + t.amount),
        tanggalSetor: now.subtract(const Duration(days: 2)),
        catatan: 'Pengeluaran konsumsi minggu ini',
        status: SetoranStatus.diterima,
        tanggalKonfirmasi: now.subtract(const Duration(days: 1, hours: 20)),
      ),
      SetoranModel(
        id: 's3',
        fromUserId: 'u5',
        fromUserName: 'Ucup',
        fromRole: UserRole.perlengkapan,
        transactions: txS3,
        totalAmount: txS3.fold(0, (s, t) => s + t.amount),
        tanggalSetor: now.subtract(const Duration(hours: 3)),
        catatan: 'ATK kemarin',
        status: SetoranStatus.pending,
      ),
    ];
  }
}
