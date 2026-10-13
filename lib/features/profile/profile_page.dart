import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/models.dart';
import '../../data/providers/app_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    // BUG FIX: null-safe — pakai `?` bukan `!`
    final user = provider.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // BUG FIX: tampilkan statistik milik user sendiri (mySummary), bukan summary global
    // kecuali ketua/bendahara yang memang lihat semua
    final summary = user.role.canViewAllTransactions
        ? provider.summary
        : provider.mySummary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const DayakAppBar(title: 'Profil'),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        children: [
          // ── Avatar & info
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingL),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
              border:
                  Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: user.role.color.withValues(alpha: 0.12),
                  child: Text(
                    user.initials,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: user.role.color,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                RoleBadge(role: user.role),
                const SizedBox(height: 4),
                const Text(AppStrings.appSubtitle,
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Statistik personal
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
                Row(
                  children: [
                    const Text('Statistik',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    if (!user.role.canViewAllTransactions)
                      const Text('Transaksi saya',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textHint)),
                  ],
                ),
                const SizedBox(height: 12),
                _StatRow(
                  label: 'Total Transaksi',
                  value: '${summary.totalTransaksi} transaksi',
                  icon: Icons.receipt_long_outlined,
                ),
                const Divider(height: 20),
                _StatRow(
                  label: 'Total Kas Masuk',
                  value: CurrencyFormatter.format(summary.totalMasuk),
                  icon: Icons.arrow_upward_rounded,
                  color: AppColors.income,
                ),
                const Divider(height: 20),
                _StatRow(
                  label: 'Total Kas Keluar',
                  value: CurrencyFormatter.format(summary.totalKeluar),
                  icon: Icons.arrow_downward_rounded,
                  color: AppColors.expense,
                ),
                const Divider(height: 20),
                _StatRow(
                  label: 'Saldo',
                  value: CurrencyFormatter.format(summary.totalSaldo),
                  icon: Icons.account_balance_wallet_outlined,
                  color: summary.totalSaldo >= 0
                      ? AppColors.income
                      : AppColors.expense,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Menu akses cepat sesuai role
          if (user.role.canSubmitSetoran) ...[
            _MenuTile(
              icon: Icons.upload_outlined,
              label: 'Setor Laporan Harian',
              subtitle:
                  '${provider.draftTransactions.length} transaksi draft',
              onTap: () => context.push('/setoran'),
              badge: provider.draftTransactions.length,
            ),
            const SizedBox(height: 8),
          ],

          // BUG FIX: ketua juga bisa lihat setoran masuk (read-only audit)
          if (user.role == UserRole.bendahara ||
              user.role == UserRole.ketua) ...[
            _MenuTile(
              icon: Icons.inbox_outlined,
              label: user.role == UserRole.bendahara
                  ? 'Setoran Masuk'
                  : 'Audit Setoran',
              subtitle: user.role == UserRole.bendahara
                  ? 'Konfirmasi laporan dari divisi'
                  : 'Monitor laporan divisi (read-only)',
              onTap: () => context.push('/setoran-masuk'),
              badge: provider.pendingSetorans.length,
            ),
            const SizedBox(height: 8),
          ],

          // ── Info hak akses
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
              border: Border.all(color: AppColors.primaryBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_outlined,
                        size: 16, color: AppColors.primaryMid),
                    const SizedBox(width: 6),
                    Text('Hak Akses — ${user.role.label}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.primaryMid)),
                  ],
                ),
                const SizedBox(height: 8),
                _AccessItem(
                    'Lihat semua transaksi',
                    user.role.canViewAllTransactions),
                _AccessItem('Tambah transaksi', user.role.canAddTransaction),
                _AccessItem(
                    'Setor laporan ke bendahara', user.role.canSubmitSetoran),
                // BUG FIX: label "Approve/reject setoran" lebih akurat untuk bendahara
                _AccessItem(
                    'Approve / reject setoran', user.role.canApproveSetoran),
                // BUG FIX: ketua bisa LIHAT setoran (audit), bukan manage
                _AccessItem(
                    'Lihat semua setoran (audit)',
                    user.role == UserRole.ketua ||
                        user.role == UserRole.bendahara),
                _AccessItem('Export laporan', user.role.canExport),
                _AccessItem('Hapus transaksi', user.role.canDelete),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Clear All Data (Ketua & Bendahara)
          if (user.role.canExport) ...[
            OutlinedButton.icon(
              onPressed: provider.clearLoading
                  ? null
                  : () => _confirmClearData(context, provider),
              icon: provider.clearLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_sweep_outlined),
              label: Text(
                  provider.clearLoading ? 'Menghapus...' : 'Hapus Semua Data'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange.shade800,
                side: BorderSide(color: Colors.orange.shade800),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusM)),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // ── Logout
          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context, provider),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Keluar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.expense,
              side: const BorderSide(color: AppColors.expense),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusM)),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, provider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // BUG FIX: logout async — tidak perlu await di sini karena
              // GoRouter akan redirect ke /login via refreshListenable
              provider.logout();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  void _confirmClearData(BuildContext context, AppProvider provider) {
    // Dialog konfirmasi tahap 1
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.orange.shade800, size: 22),
            const SizedBox(width: 8),
            const Text('Hapus Semua Data'),
          ],
        ),
        content: const Text(
          'Tindakan ini akan menghapus SEMUA transaksi, setoran, '
          'budget, dan pengumuman secara permanen.\n\n'
          'Data pengguna (nama & role) tetap aman.\n\n'
          'Yakin ingin melanjutkan?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Dialog konfirmasi tahap 2 — ketik HAPUS
              _confirmClearDataFinal(context, provider);
            },
            style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade800),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
  }

  void _confirmClearDataFinal(BuildContext context, AppProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Konfirmasi Akhir'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ketik HAPUS untuk mengkonfirmasi penghapusan semua data:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'HAPUS',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusS),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller.dispose();
                Navigator.pop(dialogContext);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: controller.text.trim() == 'HAPUS'
                  ? () async {
                      Navigator.pop(dialogContext);
                      final ok = await provider.clearAllData();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok
                                ? 'Semua data berhasil dihapus'
                                : 'Gagal menghapus data'),
                            backgroundColor:
                                ok ? AppColors.income : AppColors.expense,
                          ),
                        );
                      }
                    }
                  : null,
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange.shade800),
              child: const Text('Hapus Sekarang'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color ?? AppColors.textPrimary)),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final int badge;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border:
              Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: Icon(icon, size: 20, color: AppColors.primaryMid),
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
            if (badge > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.statusPending,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('$badge',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              )
            else
              const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _AccessItem extends StatelessWidget {
  final String label;
  final bool allowed;

  const _AccessItem(this.label, this.allowed);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            allowed
                ? Icons.check_circle_outline_rounded
                : Icons.cancel_outlined,
            size: 14,
            color: allowed ? AppColors.income : AppColors.textHint,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: allowed ? AppColors.primaryMid : AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
