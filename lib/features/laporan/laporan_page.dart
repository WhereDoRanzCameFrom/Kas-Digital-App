import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../data/providers/app_provider.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/utils/export_service.dart';

class LaporanPage extends StatelessWidget {
  const LaporanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    // BUG FIX: null-safe currentUser — gunakan `?` bukan `!`
    final user = provider.currentUser;
    if (user == null) return const SizedBox.shrink();

    final weekData    = provider.getLast4WeeksData();
    final weekSummary = provider.weekSummary;
    final canExport   = user.role.canExport;

    // BUG FIX: export menggunakan allTransactions (sudah sorted) bukan myTransactions
    // agar laporan bendahara menampilkan SELURUH transaksi
    final transactions = provider.allTransactions;
    final summary      = provider.summary;
    const kelompok     = AppStrings.appSubtitle;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const DayakAppBar(title: 'Laporan'),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        children: [
          // ── Rekap minggu ini
          _WeeklyRecapCard(weekSummary: weekSummary),
          const SizedBox(height: 16),

          // ── Bar chart 4 minggu
          _BarChartCard(weekData: weekData),
          const SizedBox(height: 16),

          // ── Breakdown kategori minggu ini
          if (weekSummary.perCategory.isNotEmpty) ...[
            _CategoryBreakdownCard(weekSummary: weekSummary),
            const SizedBox(height: 16),
          ],

          // ── Setoran summary (bendahara saja)
          if (user.role == UserRole.bendahara) ...[
            _SetoranSummaryCard(provider: provider),
            const SizedBox(height: 16),
          ],

          // ── Anggaran per kategori
          _BudgetCard(provider: provider, user: user),
          const SizedBox(height: 16),

          // ── Export section — hanya tampil jika canExport
          if (canExport) ...[
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusL),
                border:
                    Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ekspor Laporan',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    '${transactions.length} transaksi · ${CurrencyFormatter.format(summary.totalMasuk)} masuk',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  _ExportItem(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'Export PDF',
                    subtitle: 'Ringkasan + daftar transaksi, siap cetak',
                    color: Colors.red[700]!,
                    // BUG FIX: pastikan transactions & summary diteruskan dengan benar;
                    // tidak ada false success — ExportService melempar exception jika gagal
                    onTap: () => ExportService.exportPdf(
                      context: context,
                      transactions: transactions,
                      summary: summary,
                      kelompok: kelompok,
                    ),
                  ),
                  const Divider(height: 20),
                  _ExportItem(
                    icon: Icons.table_chart_outlined,
                    label: 'Export Excel',
                    subtitle: 'Sheet Ringkasan + Transaksi, bisa diedit',
                    color: Colors.green[700]!,
                    onTap: () => ExportService.exportExcel(
                      context: context,
                      transactions: transactions,
                      summary: summary,
                      kelompok: kelompok,
                    ),
                  ),
                  const Divider(height: 20),
                  _ExportItem(
                    icon: Icons.description_outlined,
                    label: 'Export Word',
                    subtitle: 'Dokumen .doc, bisa dibuka di Word/Google Docs',
                    color: Colors.blue[700]!,
                    onTap: () => ExportService.exportWord(
                      context: context,
                      transactions: transactions,
                      summary: summary,
                      kelompok: kelompok,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Jika tidak bisa export, tampilkan info
          if (!canExport) ...[
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, size: 16, color: AppColors.textHint),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Export laporan hanya tersedia untuk Ketua dan Bendahara.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ── Rekap minggu ──────────────────────────────────────────────────────────────

class _WeeklyRecapCard extends StatelessWidget {
  final SummaryModel weekSummary;
  const _WeeklyRecapCard({required this.weekSummary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rekap Minggu Ini',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(DateFormatter.weekLabel(DateTime.now()),
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _WeekStatItem(
                      label: 'Masuk',
                      amount: weekSummary.totalMasuk,
                      isIncome: true)),
              const SizedBox(width: 12),
              Expanded(
                  child: _WeekStatItem(
                      label: 'Keluar',
                      amount: weekSummary.totalKeluar,
                      isIncome: false)),
              const SizedBox(width: 12),
              Expanded(
                  child: _WeekStatItem(
                      label: 'Saldo',
                      amount: weekSummary.totalSaldo,
                      isIncome: weekSummary.totalSaldo >= 0)),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekStatItem extends StatelessWidget {
  final String label;
  final double amount;
  final bool isIncome;
  const _WeekStatItem(
      {required this.label, required this.amount, required this.isIncome});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isIncome ? AppColors.incomeLight : AppColors.expenseLight,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.formatCompact(amount.abs()),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isIncome ? AppColors.income : AppColors.expense,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bar chart ─────────────────────────────────────────────────────────────────

class _BarChartCard extends StatelessWidget {
  final List<WeeklyData> weekData;
  const _BarChartCard({required this.weekData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tren 4 Minggu Terakhir',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          const Row(
            children: [
              _LegendDot(color: AppColors.income, label: 'Masuk'),
              SizedBox(width: 16),
              _LegendDot(color: AppColors.expense, label: 'Keluar'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(height: 160, child: _BarChart(weekData: weekData)),
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<WeeklyData> weekData;
  const _BarChart({required this.weekData});

  @override
  Widget build(BuildContext context) {
    if (weekData.isEmpty) {
      return const EmptyState(message: 'Belum ada data', icon: Icons.bar_chart);
    }

    // BUG FIX: maxY dihitung dari data aktual supaya chart tidak overflow
    final maxVal = weekData
        .expand((w) => [w.masuk, w.keluar])
        .fold<double>(0, (a, b) => a > b ? a : b);
    final maxY = maxVal == 0 ? 1000000.0 : maxVal * 1.2;

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        barGroups: weekData.asMap().entries.map((e) {
          final i = e.key;
          final w = e.value;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                  toY: w.masuk,
                  color: AppColors.income,
                  width: 10,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(3))),
              BarChartRodData(
                  toY: w.keluar,
                  color: AppColors.expense,
                  width: 10,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(3))),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, m) {
                final idx = v.toInt();
                if (idx < 0 || idx >= weekData.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(weekData[idx].label,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textSecondary)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (v, m) => Text(
                CurrencyFormatter.formatCompact(v),
                style: const TextStyle(
                    fontSize: 9, color: AppColors.textSecondary),
              ),
            ),
          ),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => const FlLine(
              color: AppColors.divider, strokeWidth: 0.8),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ── Breakdown kategori ────────────────────────────────────────────────────────

class _CategoryBreakdownCard extends StatelessWidget {
  final SummaryModel weekSummary;
  const _CategoryBreakdownCard({required this.weekSummary});

  @override
  Widget build(BuildContext context) {
    final sorted = weekSummary.perCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Breakdown Kategori',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...sorted.map((e) => _CategoryBar(
                category: e.key,
                amount: e.value,
                total: weekSummary.totalKeluar,
              )),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final TransactionCategory category;
  final double amount;
  final double total;
  const _CategoryBar(
      {required this.category, required this.amount, required this.total});

  @override
  Widget build(BuildContext context) {
    // BUG FIX: guard division-by-zero
    final pct = total > 0 ? (amount / total).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(category.icon, size: 13, color: category.color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(category.label,
                    style: const TextStyle(fontSize: 12)),
              ),
              Text(
                '${(pct * 100).toStringAsFixed(0)}%  ·  ${CurrencyFormatter.formatCompact(amount)}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: category.color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation(category.color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Setoran summary (bendahara) ───────────────────────────────────────────────

class _SetoranSummaryCard extends StatelessWidget {
  final AppProvider provider;
  const _SetoranSummaryCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final all     = provider.allSetorans.length;
    final pending = provider.pendingSetorans.length;
    final terima  =
        provider.allSetorans.where((s) => s.status == SetoranStatus.diterima).length;
    final tolak   =
        provider.allSetorans.where((s) => s.status == SetoranStatus.ditolak).length;

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inbox_outlined, color: AppColors.primaryMid),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Setoran Divisi',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      '$all total · $pending menunggu · $terima diterima · $tolak ditolak',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.push('/setoran-masuk'),
                child: const Text('Lihat'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Budget card ───────────────────────────────────────────────────────────────

class _BudgetCard extends StatelessWidget {
  final AppProvider provider;
  final UserModel user;
  const _BudgetCard({required this.provider, required this.user});

  bool get _canEdit =>
      user.role == UserRole.ketua || user.role == UserRole.bendahara;

  void _showBudgetDialog(BuildContext context, TransactionCategory cat) {
    final current = provider.getBudget(cat);
    final ctrl = TextEditingController(
      text: current > 0 ? current.toInt().toString() : '',
    );
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Anggaran ${cat.label}'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            prefixText: 'Rp ',
            hintText: '0',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          if (current > 0)
            TextButton(
              onPressed: () {
                provider.clearBudget(cat);
                Navigator.pop(dialogContext);
              },
              child: const Text('Hapus',
                  style: TextStyle(color: AppColors.expense)),
            ),
          FilledButton(
            onPressed: () {
              final raw = ctrl.text.replaceAll('.', '').replaceAll(',', '');
              final val = double.tryParse(raw) ?? 0;
              if (val < 0) return;
              provider.setBudget(cat, val);
              Navigator.pop(dialogContext);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const allCats = TransactionCategory.values;
    final summary = provider.summary;
    final hasBudget = allCats.any((c) => provider.getBudget(c) > 0);

    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Anggaran per Kategori',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const Spacer(),
              if (_canEdit)
                const Text('Ketuk untuk edit',
                    style:
                        TextStyle(fontSize: 11, color: AppColors.textHint)),
            ],
          ),
          if (!hasBudget && !_canEdit) ...[
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.lock_outline, size: 16, color: AppColors.textHint),
                SizedBox(width: 8),
                Text('Belum ada anggaran ditetapkan',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            ...allCats.map((cat) {
              final budget = provider.getBudget(cat);
              final spent  = summary.perCategory[cat] ?? 0;
              if (budget == 0 && spent == 0) return const SizedBox.shrink();

              // BUG FIX: guard division-by-zero
              final pct     = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
              final isOver  = budget > 0 && spent > budget;
              final barColor = isOver
                  ? AppColors.expense
                  : (pct > 0.75 ? AppColors.statusPending : AppColors.income);

              return GestureDetector(
                onTap: _canEdit ? () => _showBudgetDialog(context, cat) : null,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(cat.icon, size: 14, color: cat.color),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(cat.label,
                                style: const TextStyle(fontSize: 13)),
                          ),
                          if (budget > 0) ...[
                            Text(
                              '${CurrencyFormatter.formatCompact(spent)} / ${CurrencyFormatter.formatCompact(budget)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isOver
                                    ? AppColors.expense
                                    : AppColors.textPrimary,
                              ),
                            ),
                            if (isOver) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.warning_amber_rounded,
                                  size: 14, color: AppColors.expense),
                            ],
                          ] else ...[
                            Text(
                              CurrencyFormatter.formatCompact(spent),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                            if (_canEdit) ...[
                              const SizedBox(width: 6),
                              const Text('+ set anggaran',
                                  style: TextStyle(
                                      fontSize: 11, color: AppColors.primary)),
                            ],
                          ],
                        ],
                      ),
                      if (budget > 0) ...[
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: AppColors.divider,
                            valueColor: AlwaysStoppedAnimation(barColor),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ── Export item ───────────────────────────────────────────────────────────────

class _ExportItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ExportItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusM)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textHint),
        ],
      ),
    );
  }
}
