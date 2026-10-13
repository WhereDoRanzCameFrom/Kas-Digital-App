import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/models.dart';
import '../../data/providers/app_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _scrollController = ScrollController();
  bool _isCollapsed = false;

  late final Stream<DateTime> _clockStream;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _clockStream = Stream.periodic(
      const Duration(minutes: 1),
      (_) => DateTime.now(),
    ).asBroadcastStream();
  }

  void _onScroll() {
    final collapsed = _scrollController.offset > (200 - kToolbarHeight);
    if (collapsed != _isCollapsed) setState(() => _isCollapsed = collapsed);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    // BUG FIX: null-safe guard — jika currentUser null (edge case redirect belum
    // selesai), tampilkan loading daripada crash dengan `!`
    final user = provider.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final summary      = provider.summary;
    final weekSummary  = provider.weekSummary;
    // BUG FIX: displayTransactions bukan allTransactions untuk menjaga konsistensi
    // dengan peran: ketua/bendahara lihat semua, divisi lihat milik sendiri
    final recent       = provider.displayTransactions.take(3).toList();
    final pendingCount = provider.pendingSetorans.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.transparent,
            scrolledUnderElevation: 0,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/images/kkn.jpeg', fit: BoxFit.cover),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x66000000),
                          Colors.transparent,
                          Color(0xDD000000),
                        ],
                        stops: [0.0, 0.35, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 16,
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 2))
                            ],
                          ),
                          padding: const EdgeInsets.all(3),
                          child: ClipOval(
                              child: Image.asset('assets/images/icon.png',
                                  fit: BoxFit.cover)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(AppStrings.appName,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                              StreamBuilder<DateTime>(
                                stream: _clockStream,
                                initialData: DateTime.now(),
                                builder: (_, snap) {
                                  final now = snap.data ?? DateTime.now();
                                  final jam =
                                      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
                                  return Text(
                                    '${DateFormatter.full(now)}  •  $jam',
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.white70),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        // Notif bell — hanya aktif untuk bendahara jika ada pending
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined,
                                  color: Colors.white),
                              onPressed: () {
                                // BUG FIX: ketua juga bisa buka halaman audit
                                final canView = user.role == UserRole.bendahara ||
                                    user.role == UserRole.ketua;
                                if (canView && pendingCount > 0) {
                                  context.push('/setoran-masuk');
                                }
                              },
                            ),
                            if (pendingCount > 0 &&
                                (user.role == UserRole.bendahara ||
                                    user.role == UserRole.ketua))
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                      color: AppColors.expense,
                                      shape: BoxShape.circle),
                                  child: Center(
                                      child: Text('$pendingCount',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700))),
                                ),
                              ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => context.go('/profil'),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.25),
                            child: Text(user.initials,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SaldoCard(summary: summary),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                        child: SummaryCard(
                            title: AppStrings.kasMasuk,
                            amount: summary.totalMasuk,
                            isIncome: true)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: SummaryCard(
                            title: AppStrings.kasKeluar,
                            amount: summary.totalKeluar,
                            isIncome: false)),
                  ],
                ),
                const SizedBox(height: 16),

                _PengumumanCard(provider: provider, user: user),
                const SizedBox(height: 16),

                // Banner setoran pending — bendahara
                if (user.role == UserRole.bendahara && pendingCount > 0) ...[
                  _SetoranPendingBanner(count: pendingCount),
                  const SizedBox(height: 16),
                ],

                // Banner audit — ketua
                if (user.role == UserRole.ketua) ...[
                  _KetuaAuditBanner(provider: provider),
                  const SizedBox(height: 16),
                ],

                // Banner setor — divisi
                if (user.role.canSubmitSetoran) ...[
                  _SetoranDivisionBanner(provider: provider),
                  const SizedBox(height: 16),
                ],

                _RingkasanCard(summary: weekSummary),
                const SizedBox(height: 16),

                Row(
                  children: [
                    const Text(AppStrings.transaksiTerbaru,
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go('/transaksi'),
                      child: const Text(AppStrings.lihatSemua,
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (recent.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: EmptyState(message: 'Belum ada transaksi'),
                  )
                else
                  ...recent.map((t) => TransactionTile(transaction: t)),

                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pengumuman card ───────────────────────────────────────────────────────────

class _PengumumanCard extends StatelessWidget {
  final AppProvider provider;
  final UserModel user;
  const _PengumumanCard({required this.provider, required this.user});

  bool get _canEdit =>
      user.role == UserRole.ketua || user.role == UserRole.bendahara;

  void _showEditDialog(BuildContext context) {
    final ctrl = TextEditingController(text: provider.pengumuman);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Pengumuman'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          maxLength: 200,
          decoration: const InputDecoration(
            hintText: 'Tulis pengumuman untuk anggota...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal')),
          TextButton(
            onPressed: () {
              provider.setPengumuman('');
              Navigator.pop(dialogContext);
            },
            child: const Text('Hapus', style: TextStyle(color: AppColors.expense)),
          ),
          FilledButton(
            onPressed: () {
              provider.setPengumuman(ctrl.text);
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
    final teks    = provider.pengumuman;
    final isEmpty = teks.isEmpty;

    if (isEmpty && !_canEdit) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _canEdit ? () => _showEditDialog(context) : null,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: isEmpty ? AppColors.background : const Color(0xFFFFFDE7),
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(
            color: isEmpty
                ? AppColors.divider
                : const Color(0xFFF9A825).withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isEmpty ? Icons.campaign_outlined : Icons.campaign_rounded,
              color: isEmpty ? AppColors.textHint : const Color(0xFFF57F17),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: isEmpty
                  ? const Text('Ketuk untuk tambah pengumuman...',
                      style:
                          TextStyle(fontSize: 13, color: AppColors.textHint))
                  : Text(teks,
                      style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF5D4037),
                          height: 1.4)),
            ),
            if (_canEdit) ...[
              const SizedBox(width: 8),
              Icon(Icons.edit_outlined,
                  size: 16,
                  color: isEmpty
                      ? AppColors.textHint
                      : const Color(0xFFF57F17)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Saldo card ────────────────────────────────────────────────────────────────

class _SaldoCard extends StatelessWidget {
  final SummaryModel summary;
  const _SaldoCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    // BUG FIX: tampilkan warna merah jika saldo negatif
    final isNegative = summary.totalSaldo < 0;
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(
            color: isNegative
                ? AppColors.expense.withValues(alpha: 0.4)
                : AppColors.divider.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.totalSaldo,
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text(
                  CurrencyFormatter.format(summary.totalSaldo),
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      // BUG FIX: merah jika saldo negatif
                      color: isNegative
                          ? AppColors.expense
                          : AppColors.textPrimary),
                ),
                if (isNegative) ...[
                  const SizedBox(height: 4),
                  const Row(children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 13, color: AppColors.expense),
                    SizedBox(width: 4),
                    Text('Saldo negatif!',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.expense,
                            fontWeight: FontWeight.w600)),
                  ]),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isNegative
                  ? AppColors.expenseLight
                  : AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: isNegative ? AppColors.expense : AppColors.primaryMid,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ringkasan pie chart ───────────────────────────────────────────────────────

class _RingkasanCard extends StatelessWidget {
  final SummaryModel summary;
  const _RingkasanCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final cats = summary.perCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (cats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(AppStrings.ringkasanPengeluaran,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              Spacer(),
              Text(AppStrings.mingguIni,
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
            ]),
            SizedBox(height: 32),
            EmptyState(
                message: 'Belum ada pengeluaran minggu ini',
                icon: Icons.pie_chart_outline),
            SizedBox(height: 16),
          ],
        ),
      );
    }

    final sections = cats.asMap().entries.map((e) {
      // BUG FIX: guard division-by-zero di pie chart
      final pct = summary.totalKeluar > 0
          ? e.value.value / summary.totalKeluar
          : 0.0;
      return PieChartSectionData(
        value: e.value.value,
        color: AppColors.chartPalette[e.key % AppColors.chartPalette.length],
        radius: 52,
        showTitle: pct > 0.10,
        title: '${(pct * 100).toStringAsFixed(0)}%',
        titleStyle: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
      );
    }).toList();

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
          const Row(children: [
            Text(AppStrings.ringkasanPengeluaran,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Spacer(),
            Text(AppStrings.mingguIni,
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: PieChart(PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              startDegreeOffset: -90,
            )),
          ),
          const SizedBox(height: 16),
          ...cats.asMap().entries.map((e) {
            final color =
                AppColors.chartPalette[e.key % AppColors.chartPalette.length];
            // BUG FIX: guard division-by-zero di legend
            final pct = summary.totalKeluar > 0
                ? (e.value.value / summary.totalKeluar * 100).toStringAsFixed(0)
                : '0';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                      width: 10,
                      height: 10,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(e.value.key.label,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text('$pct%',
                      style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    child: Text(
                      CurrencyFormatter.formatCompact(e.value.value),
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Banners ───────────────────────────────────────────────────────────────────

class _SetoranPendingBanner extends StatelessWidget {
  final int count;
  const _SetoranPendingBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/setoran-masuk'),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: AppColors.statusPendingBg,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border:
              Border.all(color: AppColors.statusPending.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.inbox_outlined, color: AppColors.statusPending),
            const SizedBox(width: 12),
            Expanded(
              child: Text('$count laporan setoran menunggu konfirmasi',
                  style: const TextStyle(
                      color: AppColors.statusPending,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
            const Icon(Icons.chevron_right, color: AppColors.statusPending),
          ],
        ),
      ),
    );
  }
}

class _KetuaAuditBanner extends StatelessWidget {
  final AppProvider provider;
  const _KetuaAuditBanner({required this.provider});

  @override
  Widget build(BuildContext context) {
    final pending = provider.pendingSetorans.length;
    final all     = provider.allSetorans.length;
    return GestureDetector(
      onTap: () => context.push('/setoran-masuk'),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border:
              Border.all(color: AppColors.roleKetua.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.admin_panel_settings_outlined,
                color: AppColors.roleKetua),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Audit: $all setoran masuk · $pending menunggu',
                style: const TextStyle(
                    color: AppColors.roleKetua,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.roleKetua),
          ],
        ),
      ),
    );
  }
}

class _SetoranDivisionBanner extends StatelessWidget {
  final AppProvider provider;
  const _SetoranDivisionBanner({required this.provider});

  @override
  Widget build(BuildContext context) {
    final draftCount = provider.draftTransactions.length;
    return GestureDetector(
      onTap: () => context.push('/setoran'),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(color: AppColors.primaryBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.upload_outlined, color: AppColors.primaryMid),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                draftCount > 0
                    ? '$draftCount transaksi siap disetor ke bendahara'
                    : 'Tambah & setor laporan harian ke bendahara',
                style: const TextStyle(
                    color: AppColors.primaryMid,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.primaryMid),
          ],
        ),
      ),
    );
  }
}
