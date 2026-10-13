import 'package:flutter/material.dart';

// ─── Firebase Toggle ──────────────────────────────────────────────────────────
/// Set ke `true` untuk pakai Firebase (Firestore + local PIN session).
/// Set ke `false` untuk pakai data dummy lokal (mode testing/demo).
const bool kUseFirebase = true;

class AppColors {
  AppColors._();

  // Brand — hijau tua sesuai desain
  static const primary = Color(0xFF1B5E20);
  static const primaryMid = Color(0xFF2E7D32);
  static const primaryLight = Color(0xFF43A047);
  static const primarySurface = Color(0xFFE8F5E9);
  static const primaryBorder = Color(0xFFA5D6A7);

  // Semantic
  static const income = Color(0xFF2E7D32);
  static const incomeLight = Color(0xFFE8F5E9);
  static const expense = Color(0xFFC62828);
  static const expenseLight = Color(0xFFFFEBEE);

  // Status setoran
  static const statusPending = Color(0xFFF57C00);
  static const statusPendingBg = Color(0xFFFFF3E0);

  // Role badge colors
  static const roleKetua = Color(0xFF1565C0);
  static const roleBendahara = Color(0xFF2E7D32);
  static const roleWakil = Color(0xFF00838F);
  static const roleSekretaris = Color(0xFF4527A0);
  static const roleHumas = Color(0xFFC62828);
  static const rolePdd = Color(0xFF558B2F);
  static const rolePerlengkapan = Color(0xFF6A1B9A);
  static const roleKonsumsi = Color(0xFFE65100);

  // Neutral
  static const background = Color(0xFFF5F5F5);
  static const surface = Colors.white;
  static const divider = Color(0xFFE0E0E0);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF757575);
  static const textHint = Color(0xFFBDBDBD);

  // Category
  static const catKonsumsi = Color(0xFFE65100);
  static const catPerlengkapan = Color(0xFF1565C0);
  static const catTransportasi = Color(0xFF00695C);
  static const catDokumentasi = Color(0xFF6A1B9A);
  static const catProgramKerja = Color(0xFF558B2F);
  static const catLainnya = Color(0xFF546E7A);

  // Pie chart palette (urut sesuai kategori)
  static const List<Color> chartPalette = [
    Color(0xFF43A047), // konsumsi
    Color(0xFF1E88E5), // perlengkapan
    Color(0xFFFB8C00), // transportasi
    Color(0xFF8E24AA), // dokumentasi
    Color(0xFF00ACC1), // program kerja
    Color(0xFF78909C), // lainnya
  ];
}

class AppSizes {
  AppSizes._();

  static const double paddingXS = 4;
  static const double paddingS = 8;
  static const double paddingM = 16;
  static const double paddingL = 24;
  static const double paddingXL = 32;

  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 16;
  static const double radiusXL = 24;

  static const double iconS = 18;
  static const double iconM = 24;
  static const double iconL = 32;

  static const double bottomNavHeight = 72;
  static const double fabSize = 56;
}

class AppStrings {
  AppStrings._();

  static const appName = 'Kas Digital 85';
  static const appSubtitle = 'Kelompok KKN 85';
  static const login = 'Masuk';
  static const logout = 'Keluar';
  static const beranda = 'Beranda';
  static const transaksi = 'Transaksi';
  static const laporan = 'Laporan';
  static const profil = 'Profil';
  static const kasMasuk = 'Kas Masuk';
  static const kasKeluar = 'Kas Keluar';
  static const riwayat = 'Riwayat';
  static const rekap = 'Rekap';
  static const setor = 'Setor Laporan';
  static const totalSaldo = 'Saldo Saat Ini';
  static const tambahTransaksi = 'Tambah Transaksi';
  static const simpan = 'Simpan';
  static const batal = 'Batal';
  static const jumlah = 'Jumlah';
  static const kategori = 'Kategori';
  static const deskripsi = 'Keterangan';
  static const tanggal = 'Tanggal';
  static const pilihPengguna = 'Pilih pengguna';
  static const masukkanPin = 'Masukkan PIN';
  static const pinSalah = 'PIN salah, coba lagi';
  static const semuaTransaksi = 'Semua';
  static const semuaTanggal = 'Semua Tanggal';
  static const semuaKategori = 'Semua Kategori';
  static const transaksiTerbaru = 'Transaksi Terbaru';
  static const lihatSemua = 'Lihat Semua';
  static const ringkasanPengeluaran = 'Ringkasan Pengeluaran';
  static const mingguIni = 'Minggu Ini';
}
