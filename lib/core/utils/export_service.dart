import 'dart:io';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import '../../data/models/models.dart';

final _currFmt =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
final _dateFmt = DateFormat('dd MMM yyyy', 'id_ID');
final _dateTimeFmt = DateFormat('dd MMM yyyy HH:mm', 'id_ID');

String _rp(double v) => _currFmt.format(v);
String _tgl(DateTime d) => _dateFmt.format(d);
String _tglWaktu(DateTime d) => _dateTimeFmt.format(d);

class ExportService {
  ExportService._();

  // ── PDF ────────────────────────────────────────────────────────────────────
  static Future<void> exportPdf({
    required BuildContext context,
    required List<TransactionModel> transactions,
    required SummaryModel summary,
    required String kelompok,
  }) async {
    // BUG FIX: guard context.mounted sebelum showDialog
    if (!context.mounted) return;
    _showLoading(context, 'Membuat PDF...');

    try {
      final doc = pw.Document();
      final now = DateTime.now();

      final sorted = List<TransactionModel>.from(transactions)
        ..sort((a, b) => b.date.compareTo(a.date));

      const hijau = PdfColor.fromInt(0xFF1B5E20);
      const hijauMid = PdfColor.fromInt(0xFF2E7D32);
      const hijauSurface = PdfColor.fromInt(0xFFE8F5E9);
      const merah = PdfColor.fromInt(0xFFC62828);
      const abu = PdfColor.fromInt(0xFF757575);
      const abuLight = PdfColor.fromInt(0xFFF5F5F5);

      // Halaman 1: Ringkasan
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: hijau,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('LAPORAN KEUANGAN KKN',
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text(kelompok,
                        style: pw.TextStyle(
                            color: PdfColor.fromHex('#B3FFFFFF'), fontSize: 12)),
                    pw.SizedBox(height: 2),
                    pw.Text('Digenerate: ${_tglWaktu(now)}',
                        style: pw.TextStyle(
                            color: PdfColor.fromHex('#B3FFFFFF'), fontSize: 10)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('RINGKASAN KEUANGAN',
                  style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: hijauMid)),
              pw.SizedBox(height: 8),
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Table(
                  children: [
                    _pdfSummaryRow(
                        'Total Kas Masuk', _rp(summary.totalMasuk), hijauMid, hijauSurface),
                    _pdfSummaryRow('Total Kas Keluar', _rp(summary.totalKeluar),
                        merah, const PdfColor.fromInt(0xFFFFEBEE)),
                    _pdfSummaryRow(
                        'Saldo Akhir',
                        _rp(summary.totalSaldo),
                        summary.totalSaldo >= 0 ? hijauMid : merah,
                        summary.totalSaldo >= 0
                            ? hijauSurface
                            : const PdfColor.fromInt(0xFFFFEBEE)),
                    _pdfSummaryRow('Total Transaksi',
                        '${summary.totalTransaksi} transaksi', abu, abuLight),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              if (summary.perCategory.isNotEmpty) ...[
                pw.Text('PENGELUARAN PER KATEGORI',
                    style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: hijauMid)),
                pw.SizedBox(height: 8),
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Table(
                    columnWidths: {
                      0: const pw.FlexColumnWidth(3),
                      1: const pw.FlexColumnWidth(2),
                      2: const pw.FlexColumnWidth(1.5),
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: hijauSurface),
                        children: [
                          _pdfCell('Kategori', bold: true),
                          _pdfCell('Jumlah', bold: true, align: pw.TextAlign.right),
                          _pdfCell('%', bold: true, align: pw.TextAlign.right),
                        ],
                      ),
                      ...summary.perCategory.entries
                          .toList()
                          .sorted((a, b) => b.value.compareTo(a.value))
                          .map((e) {
                        final pct = summary.totalKeluar > 0
                            ? (e.value / summary.totalKeluar * 100)
                                .toStringAsFixed(1)
                            : '0';
                        return pw.TableRow(children: [
                          _pdfCell(e.key.label),
                          _pdfCell(_rp(e.value),
                              align: pw.TextAlign.right, color: merah),
                          _pdfCell('$pct%', align: pw.TextAlign.right),
                        ]);
                      }),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );

      // Halaman 2+: Daftar Transaksi
      const perPage = 25;
      for (int page = 0; page < (sorted.length / perPage).ceil(); page++) {
        final slice = sorted.skip(page * perPage).take(perPage).toList();
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(36),
            build: (ctx) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                    'DAFTAR TRANSAKSI${(sorted.length / perPage).ceil() > 1 ? ' (hal. ${page + 2})' : ''}',
                    style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: hijauMid)),
                pw.SizedBox(height: 8),
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Table(
                    columnWidths: {
                      0: const pw.FlexColumnWidth(2),
                      1: const pw.FlexColumnWidth(3),
                      2: const pw.FlexColumnWidth(2),
                      3: const pw.FlexColumnWidth(2.2),
                      4: const pw.FlexColumnWidth(1.2),
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: hijauSurface),
                        children: [
                          _pdfCell('Tanggal', bold: true),
                          _pdfCell('Keterangan', bold: true),
                          _pdfCell('Kategori', bold: true),
                          _pdfCell('Jumlah', bold: true, align: pw.TextAlign.right),
                          _pdfCell('Jenis', bold: true, align: pw.TextAlign.center),
                        ],
                      ),
                      ...slice.asMap().entries.map((e) {
                        final t = e.value;
                        final isIn = t.type == TransactionType.masuk;
                        final bg = e.key % 2 == 0
                            ? PdfColors.white
                            : const PdfColor.fromInt(0xFFFAFAFA);
                        return pw.TableRow(
                          decoration: pw.BoxDecoration(color: bg),
                          children: [
                            _pdfCell(_tgl(t.date), size: 9),
                            _pdfCell(t.description, size: 9),
                            _pdfCell(t.category.label, size: 9),
                            _pdfCell(
                              '${isIn ? '+' : '-'}${_rp(t.amount)}',
                              align: pw.TextAlign.right,
                              color: isIn ? hijauMid : merah,
                              size: 9,
                            ),
                            _pdfCell(
                              isIn ? 'Masuk' : 'Keluar',
                              align: pw.TextAlign.center,
                              color: isIn ? hijauMid : merah,
                              size: 9,
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
                pw.Spacer(),
                pw.Divider(color: PdfColors.grey300),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('$kelompok · Laporan Keuangan KKN',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey)),
                    pw.Text('Halaman ${page + 2}',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey)),
                  ],
                ),
              ],
            ),
          ),
        );
      }

      // BUG FIX: simpan bytes dan verifikasi file sebelum tutup loading
      final bytes = await doc.save();

      // BUG FIX: verifikasi bytes tidak kosong sebelum tulis file
      if (bytes.isEmpty) throw Exception('PDF kosong — tidak ada data untuk diekspor');

      final dir = await getTemporaryDirectory();
      final filename = 'laporan_kkn_${DateFormat('yyyyMMdd_HHmm').format(now)}.pdf';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);

      // BUG FIX: verifikasi file benar-benar ada dan ukurannya > 0
      if (!await file.exists() || await file.length() == 0) {
        throw Exception('File PDF gagal dibuat');
      }

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // tutup loading

      await _showSaveDialog(
        context: context,
        file: file,
        filename: filename,
        mimeType: 'application/pdf',
        shareText: 'Laporan Keuangan KKN - $kelompok',
      );
    } catch (e) {
      if (context.mounted) {
        // BUG FIX: pastikan loading dialog tertutup sebelum error
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
        _showError(context, 'Gagal export PDF: $e');
      }
    }
  }

  // ── Excel ──────────────────────────────────────────────────────────────────
  static Future<void> exportExcel({
    required BuildContext context,
    required List<TransactionModel> transactions,
    required SummaryModel summary,
    required String kelompok,
  }) async {
    if (!context.mounted) return;
    _showLoading(context, 'Membuat Excel...');

    try {
      final now = DateTime.now();
      final excel = Excel.createExcel();

      final sheetRingkasan = excel['Ringkasan'];
      excel.setDefaultSheet('Ringkasan');

      CellStyle headerStyle() => CellStyle(
            bold: true,
            backgroundColorHex: ExcelColor.fromHexString('#1B5E20'),
            fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
          );
      CellStyle labelStyle() => CellStyle(bold: true);
      CellStyle incomeStyle() => CellStyle(
            fontColorHex: ExcelColor.fromHexString('#2E7D32'),
            bold: true,
          );
      CellStyle expenseStyle() => CellStyle(
            fontColorHex: ExcelColor.fromHexString('#C62828'),
            bold: true,
          );

      sheetRingkasan.cell(CellIndex.indexByString('A1')).value =
          TextCellValue('LAPORAN KEUANGAN KKN');
      sheetRingkasan.cell(CellIndex.indexByString('A1')).cellStyle =
          CellStyle(bold: true, fontSize: 14);
      sheetRingkasan.cell(CellIndex.indexByString('A2')).value =
          TextCellValue(kelompok);
      sheetRingkasan.cell(CellIndex.indexByString('A3')).value =
          TextCellValue('Digenerate: ${_tglWaktu(now)}');

      sheetRingkasan.cell(CellIndex.indexByString('A5')).value =
          TextCellValue('RINGKASAN KEUANGAN');
      sheetRingkasan.cell(CellIndex.indexByString('A5')).cellStyle =
          CellStyle(bold: true, fontSize: 12);

      final ringkasanHeaders = ['Keterangan', 'Jumlah'];
      for (var i = 0; i < ringkasanHeaders.length; i++) {
        final cell = sheetRingkasan
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 6));
        cell.value = TextCellValue(ringkasanHeaders[i]);
        cell.cellStyle = headerStyle();
      }

      final ringkasanData = [
        ['Total Kas Masuk', summary.totalMasuk],
        ['Total Kas Keluar', summary.totalKeluar],
        ['Saldo Akhir', summary.totalSaldo],
        ['Total Transaksi', summary.totalTransaksi.toDouble()],
      ];

      for (var r = 0; r < ringkasanData.length; r++) {
        final row = ringkasanData[r];
        sheetRingkasan
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 7 + r))
            .value = TextCellValue(row[0] as String);
        final valCell = sheetRingkasan
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 7 + r));

        if (r == 3) {
          valCell.value = IntCellValue((row[1] as double).toInt());
        } else {
          valCell.value = DoubleCellValue(row[1] as double);
          valCell.cellStyle = r == 0
              ? incomeStyle()
              : r == 1
                  ? expenseStyle()
                  : (summary.totalSaldo >= 0 ? incomeStyle() : expenseStyle());
        }
      }

      int rowKat = 13;
      sheetRingkasan.cell(CellIndex.indexByString('A$rowKat')).value =
          TextCellValue('PENGELUARAN PER KATEGORI');
      sheetRingkasan.cell(CellIndex.indexByString('A$rowKat')).cellStyle =
          CellStyle(bold: true, fontSize: 12);
      rowKat++;

      final katHeaders = ['Kategori', 'Jumlah', 'Persentase'];
      for (var i = 0; i < katHeaders.length; i++) {
        final cell = sheetRingkasan
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowKat));
        cell.value = TextCellValue(katHeaders[i]);
        cell.cellStyle = headerStyle();
      }
      rowKat++;

      final sortedCats = summary.perCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (final e in sortedCats) {
        final pct = summary.totalKeluar > 0 ? e.value / summary.totalKeluar : 0.0;
        sheetRingkasan
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowKat))
            .value = TextCellValue(e.key.label);
        final amtCell = sheetRingkasan
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowKat));
        amtCell.value = DoubleCellValue(e.value);
        amtCell.cellStyle = expenseStyle();
        sheetRingkasan
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowKat))
            .value = TextCellValue('${(pct * 100).toStringAsFixed(1)}%');
        rowKat++;
      }

      sheetRingkasan.setColumnWidth(0, 30);
      sheetRingkasan.setColumnWidth(1, 20);
      sheetRingkasan.setColumnWidth(2, 15);

      final sheetTx = excel['Transaksi'];
      final txHeaders = [
        'No', 'Tanggal', 'Waktu', 'Keterangan', 'Kategori', 'Jenis', 'Jumlah',
        'Dibuat Oleh', 'Role'
      ];
      for (var i = 0; i < txHeaders.length; i++) {
        final cell =
            sheetTx.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(txHeaders[i]);
        cell.cellStyle = headerStyle();
      }

      final sorted = List<TransactionModel>.from(transactions)
        ..sort((a, b) => b.date.compareTo(a.date));

      for (var r = 0; r < sorted.length; r++) {
        final t = sorted[r];
        final isIn = t.type == TransactionType.masuk;
        final rowData = [
          IntCellValue(r + 1),
          TextCellValue(_tgl(t.date)),
          TextCellValue(
              '${t.date.hour.toString().padLeft(2, '0')}:${t.date.minute.toString().padLeft(2, '0')}'),
          TextCellValue(t.description),
          TextCellValue(t.category.label),
          TextCellValue(isIn ? 'Kas Masuk' : 'Kas Keluar'),
          DoubleCellValue(t.amount),
          TextCellValue(t.createdByName),
          TextCellValue(t.createdByRole.shortLabel),
        ];
        for (var c = 0; c < rowData.length; c++) {
          final cell = sheetTx.cell(
              CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1));
          cell.value = rowData[c];
          if (c == 6) {
            cell.cellStyle = isIn ? incomeStyle() : expenseStyle();
          }
        }
      }

      final totalRow = sorted.length + 2;
      sheetTx
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: totalRow))
          .value = TextCellValue('TOTAL MASUK');
      sheetTx
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: totalRow))
          .cellStyle = labelStyle();
      final totalMasukCell = sheetTx
          .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: totalRow));
      totalMasukCell.value = DoubleCellValue(summary.totalMasuk);
      totalMasukCell.cellStyle = incomeStyle();

      sheetTx
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: totalRow + 1))
          .value = TextCellValue('TOTAL KELUAR');
      sheetTx
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: totalRow + 1))
          .cellStyle = labelStyle();
      final totalKeluarCell = sheetTx
          .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: totalRow + 1));
      totalKeluarCell.value = DoubleCellValue(summary.totalKeluar);
      totalKeluarCell.cellStyle = expenseStyle();

      sheetTx
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: totalRow + 2))
          .value = TextCellValue('SALDO');
      sheetTx
          .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: totalRow + 2))
          .cellStyle = CellStyle(bold: true);
      final saldoCell = sheetTx
          .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: totalRow + 2));
      saldoCell.value = DoubleCellValue(summary.totalSaldo);
      saldoCell.cellStyle = summary.totalSaldo >= 0 ? incomeStyle() : expenseStyle();

      sheetTx.setColumnWidth(0, 5);
      sheetTx.setColumnWidth(1, 15);
      sheetTx.setColumnWidth(2, 8);
      sheetTx.setColumnWidth(3, 30);
      sheetTx.setColumnWidth(4, 15);
      sheetTx.setColumnWidth(5, 12);
      sheetTx.setColumnWidth(6, 18);
      sheetTx.setColumnWidth(7, 18);
      sheetTx.setColumnWidth(8, 14);

      excel.delete('Sheet1');

      // BUG FIX: cek bytes tidak null sebelum tulis
      final bytes = excel.save();
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Gagal generate Excel — bytes kosong');
      }

      final dir = await getTemporaryDirectory();
      final filename = 'laporan_kkn_${DateFormat('yyyyMMdd_HHmm').format(now)}.xlsx';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);

      // BUG FIX: verifikasi file ada dan berukuran > 0
      if (!await file.exists() || await file.length() == 0) {
        throw Exception('File Excel gagal dibuat');
      }

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      await _showSaveDialog(
        context: context,
        file: file,
        filename: filename,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        shareText: 'Laporan Keuangan KKN (Excel) - $kelompok',
      );
    } catch (e) {
      if (context.mounted) {
        try { Navigator.of(context, rootNavigator: true).pop(); } catch (_) {}
        _showError(context, 'Gagal export Excel: $e');
      }
    }
  }

  // ── Word (HTML → .doc) ────────────────────────────────────────────────────
  static Future<void> exportWord({
    required BuildContext context,
    required List<TransactionModel> transactions,
    required SummaryModel summary,
    required String kelompok,
  }) async {
    if (!context.mounted) return;
    _showLoading(context, 'Membuat dokumen Word...');

    try {
      final now = DateTime.now();
      final sorted = List<TransactionModel>.from(transactions)
        ..sort((a, b) => b.date.compareTo(a.date));

      final sortedCats = summary.perCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final txRows = StringBuffer();
      for (var i = 0; i < sorted.length; i++) {
        final t = sorted[i];
        final isIn = t.type == TransactionType.masuk;
        final warna = isIn ? '#2E7D32' : '#C62828';
        final prefix = isIn ? '+' : '-';
        final bg = i % 2 == 0 ? '#FFFFFF' : '#FAFAFA';
        txRows.write('''
          <tr style="background:$bg">
            <td style="padding:5px 8px;border:1px solid #E0E0E0;font-size:11px">${i + 1}</td>
            <td style="padding:5px 8px;border:1px solid #E0E0E0;font-size:11px">${_tgl(t.date)}</td>
            <td style="padding:5px 8px;border:1px solid #E0E0E0;font-size:11px">${_escHtml(t.description)}</td>
            <td style="padding:5px 8px;border:1px solid #E0E0E0;font-size:11px">${t.category.label}</td>
            <td style="padding:5px 8px;border:1px solid #E0E0E0;font-size:11px;color:$warna;font-weight:bold">$prefix${_rp(t.amount)}</td>
            <td style="padding:5px 8px;border:1px solid #E0E0E0;font-size:11px">${_escHtml(t.createdByName)}</td>
          </tr>
        ''');
      }

      final katRows = StringBuffer();
      for (final e in sortedCats) {
        final pct = summary.totalKeluar > 0
            ? (e.value / summary.totalKeluar * 100).toStringAsFixed(1)
            : '0';
        katRows.write('''
          <tr>
            <td style="padding:5px 8px;border:1px solid #E0E0E0">${e.key.label}</td>
            <td style="padding:5px 8px;border:1px solid #E0E0E0;color:#C62828;font-weight:bold">${_rp(e.value)}</td>
            <td style="padding:5px 8px;border:1px solid #E0E0E0">$pct%</td>
          </tr>
        ''');
      }

      final saldoColor = summary.totalSaldo >= 0 ? '#2E7D32' : '#C62828';

      final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: "Times New Roman", Times, serif; margin: 2cm; color: #1A1A1A; }
    h1 { color: #1B5E20; font-size: 18pt; margin-bottom: 4px; }
    h2 { color: #2E7D32; font-size: 13pt; margin-top: 20px; margin-bottom: 8px; border-bottom: 2px solid #2E7D32; padding-bottom: 4px; }
    p.sub { color: #757575; font-size: 10pt; margin: 2px 0; }
    table { border-collapse: collapse; width: 100%; margin-top: 8px; }
    th { background: #1B5E20; color: white; padding: 7px 10px; text-align: left; font-size: 11pt; }
    .summary-label { padding: 6px 10px; border: 1px solid #E0E0E0; font-size: 11pt; font-weight: bold; }
    .summary-value { padding: 6px 10px; border: 1px solid #E0E0E0; font-size: 11pt; }
    .footer { margin-top: 40px; font-size: 10pt; color: #757575; border-top: 1px solid #E0E0E0; padding-top: 10px; }
    @page { margin: 2cm; }
  </style>
</head>
<body>

<h1>LAPORAN KEUANGAN KKN</h1>
<p class="sub">$kelompok</p>
<p class="sub">Digenerate: ${_tglWaktu(now)}</p>

<h2>RINGKASAN KEUANGAN</h2>
<table>
  <tr>
    <td class="summary-label" style="width:50%">Total Kas Masuk</td>
    <td class="summary-value" style="color:#2E7D32;font-weight:bold">${_rp(summary.totalMasuk)}</td>
  </tr>
  <tr style="background:#FAFAFA">
    <td class="summary-label">Total Kas Keluar</td>
    <td class="summary-value" style="color:#C62828;font-weight:bold">${_rp(summary.totalKeluar)}</td>
  </tr>
  <tr>
    <td class="summary-label">Saldo Akhir</td>
    <td class="summary-value" style="color:$saldoColor;font-weight:bold">${_rp(summary.totalSaldo)}</td>
  </tr>
  <tr style="background:#FAFAFA">
    <td class="summary-label">Total Transaksi</td>
    <td class="summary-value">${summary.totalTransaksi} transaksi</td>
  </tr>
</table>

${sortedCats.isNotEmpty ? '''
<h2>PENGELUARAN PER KATEGORI</h2>
<table>
  <tr>
    <th>Kategori</th>
    <th>Jumlah</th>
    <th>Persentase</th>
  </tr>
  $katRows
</table>
''' : ''}

<h2>DAFTAR TRANSAKSI (${sorted.length} transaksi)</h2>
<table>
  <tr>
    <th style="width:4%">No</th>
    <th style="width:13%">Tanggal</th>
    <th style="width:30%">Keterangan</th>
    <th style="width:14%">Kategori</th>
    <th style="width:20%">Jumlah</th>
    <th style="width:19%">Dibuat Oleh</th>
  </tr>
  $txRows
</table>

<div class="footer">
  <strong>$kelompok</strong> &nbsp;·&nbsp; Laporan Keuangan KKN &nbsp;·&nbsp; ${_tgl(now)}
</div>

</body>
</html>
''';

      // BUG FIX: gunakan UTF-8 encoding, bukan codeUnits (yang hanya benar untuk ASCII)
      final bytes = utf8.encode(html);

      final dir = await getTemporaryDirectory();
      final filename = 'laporan_kkn_${DateFormat('yyyyMMdd_HHmm').format(now)}.doc';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);

      // BUG FIX: verifikasi file ada dan berukuran > 0
      if (!await file.exists() || await file.length() == 0) {
        throw Exception('File Word gagal dibuat');
      }

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      await _showSaveDialog(
        context: context,
        file: file,
        filename: filename,
        mimeType: 'application/msword',
        shareText: 'Laporan Keuangan KKN (Word) - $kelompok',
      );
    } catch (e) {
      if (context.mounted) {
        try { Navigator.of(context, rootNavigator: true).pop(); } catch (_) {}
        _showError(context, 'Gagal export Word: $e');
      }
    }
  }

  // ── Save dialog ───────────────────────────────────────────────────────────
  static Future<void> _showSaveDialog({
    required BuildContext context,
    required File file,
    required String filename,
    required String mimeType,
    required String shareText,
  }) async {
    // BUG FIX: pastikan file ada sebelum tampilkan dialog
    if (!await file.exists()) {
      if (context.mounted) _showError(context, 'File tidak ditemukan');
      return;
    }

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Simpan File',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(filename,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              ListTile(
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await Share.shareXFiles(
                    [XFile(file.path, mimeType: mimeType)],
                    text: shareText,
                  );
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.share_rounded, color: Colors.blue.shade700),
                ),
                title: const Text('Bagikan',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('WhatsApp, Drive, Email, dll'),
                trailing: const Icon(Icons.chevron_right),
              ),
              const SizedBox(height: 4),
              ListTile(
                onTap: () async {
                  Navigator.pop(sheetContext);
                  if (!context.mounted) return;
                  await _saveToDownloads(
                    context: context,
                    file: file,
                    filename: filename,
                  );
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.download_rounded,
                      color: Colors.green.shade700),
                ),
                title: const Text('Simpan ke Downloads',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Folder Downloads di HP'),
                trailing: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _saveToDownloads({
    required BuildContext context,
    required File file,
    required String filename,
  }) async {
    try {
      PermissionStatus status;
      if (Platform.isAndroid) {
        status = await Permission.manageExternalStorage.status;
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
        }
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
      } else {
        status = PermissionStatus.granted;
      }

      if (!status.isGranted) {
        if (!context.mounted) return;
        _showError(context,
            'Izin penyimpanan ditolak. Buka Pengaturan → Aplikasi → izinkan Storage.');
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Izin Diperlukan'),
            content: const Text(
                'Aplikasi perlu izin Storage untuk menyimpan file ke Downloads. Buka pengaturan sekarang?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal')),
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  openAppSettings();
                },
                child: const Text('Buka Pengaturan'),
              ),
            ],
          ),
        );
        return;
      }

      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          downloadsDir = await getExternalStorageDirectory();
        }
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (downloadsDir == null) {
        if (!context.mounted) return;
        _showError(context, 'Tidak bisa menemukan folder Downloads');
        return;
      }

      final destPath = '${downloadsDir.path}/$filename';
      await file.copy(destPath);

      // BUG FIX: verifikasi file berhasil disalin
      final destFile = File(destPath);
      if (!await destFile.exists() || await destFile.length() == 0) {
        throw Exception('Gagal menyalin file ke Downloads');
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File disimpan ke Downloads/$filename'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Bagikan',
            textColor: Colors.white,
            onPressed: () async {
              await Share.shareXFiles([XFile(destPath)]);
            },
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, 'Gagal simpan ke Downloads: $e');
    }
  }

  static void _showLoading(BuildContext context, String pesan) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(strokeWidth: 3),
            const SizedBox(width: 20),
            Text(pesan),
          ],
        ),
      ),
    );
  }

  static void _showError(BuildContext context, String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static pw.TableRow _pdfSummaryRow(
      String label, String value, PdfColor valueColor, PdfColor bg) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: bg),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: pw.Text(label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: pw.Text(value,
              style: pw.TextStyle(
                  color: valueColor,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10)),
        ),
      ],
    );
  }

  static pw.Widget _pdfCell(
    String text, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? color,
    double size = 10,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: size,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  static String _escHtml(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}

extension _ListSortEx<T> on List<T> {
  List<T> sorted(int Function(T, T) compare) {
    final l = List<T>.from(this);
    l.sort(compare);
    return l;
  }
}
