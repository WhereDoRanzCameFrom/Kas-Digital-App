import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/models.dart';
import '../../data/providers/app_provider.dart';

class SetoranMasukPage extends StatelessWidget {
  const SetoranMasukPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    // BUG FIX: role check di level page — ketua hanya bisa lihat (read-only)
    final user = provider.currentUser;
    final canApprove = user?.role.canApproveSetoran ?? false;

    final setorans = provider.allSetorans;
    final pending = provider.pendingSetorans;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: DayakAppBar(
          title: canApprove ? 'Setoran Masuk' : 'Audit Setoran',
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Menunggu (${pending.length})'),
              const Tab(text: 'Semua'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _SetoranList(
              setorans: pending,
              emptyMsg: 'Tidak ada setoran menunggu',
              canApprove: canApprove,
            ),
            _SetoranList(
              setorans: setorans,
              emptyMsg: 'Belum ada setoran masuk',
              canApprove: canApprove,
            ),
          ],
        ),
      ),
    );
  }
}

class _SetoranList extends StatelessWidget {
  final List<SetoranModel> setorans;
  final String emptyMsg;
  final bool canApprove;

  const _SetoranList({
    required this.setorans,
    required this.emptyMsg,
    required this.canApprove,
  });

  @override
  Widget build(BuildContext context) {
    if (setorans.isEmpty) {
      return EmptyState(message: emptyMsg, icon: Icons.inbox_outlined);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingM),
      itemCount: setorans.length,
      itemBuilder: (_, i) =>
          _SetoranCard(setoran: setorans[i], canApprove: canApprove),
    );
  }
}

class _SetoranCard extends StatelessWidget {
  final SetoranModel setoran;
  final bool canApprove;

  const _SetoranCard({required this.setoran, required this.canApprove});

  @override
  Widget build(BuildContext context) {
    final isPending = setoran.status == SetoranStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(
          color: isPending
              ? AppColors.statusPending.withValues(alpha: 0.3)
              : AppColors.divider.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      setoran.fromRole.color.withValues(alpha: 0.12),
                  child: Text(
                    setoran.fromUserName.isNotEmpty
                        ? setoran.fromUserName
                            .substring(
                                0, setoran.fromUserName.length >= 2 ? 2 : 1)
                            .toUpperCase()
                        : '??',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: setoran.fromRole.color),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(setoran.fromUserName,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Row(children: [
                        RoleBadge(role: setoran.fromRole),
                        const SizedBox(width: 6),
                        Text(DateFormatter.relative(setoran.tanggalSetor),
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textHint)),
                      ]),
                    ],
                  ),
                ),
                SetoranStatusBadge(status: setoran.status),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _InfoChip(
                    label: '${setoran.transactions.length} transaksi',
                    icon: Icons.receipt_outlined),
                const SizedBox(width: 8),
                _InfoChip(
                    label: CurrencyFormatter.format(setoran.totalAmount),
                    icon: Icons.payments_outlined),
              ],
            ),
          ),

          if (setoran.catatan != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text('"${setoran.catatan}"',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic)),
            ),

          ExpansionTile(
            title: const Text('Lihat Detail Transaksi',
                style: TextStyle(fontSize: 13, color: AppColors.primary)),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 12),
            children: setoran.transactions
                .map((t) => TransactionTile(transaction: t, showDate: true))
                .toList(),
          ),

          // BUG FIX: tombol aksi hanya muncul jika canApprove == true
          if (isPending && canApprove) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showKonfirmasiDialog(context, setoran, tolak: true),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Tolak'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.expense,
                        side: const BorderSide(color: AppColors.expense),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () =>
                          _showKonfirmasiDialog(context, setoran, tolak: false),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Terima'),
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.income),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Label read-only untuk ketua
          if (isPending && !canApprove) ...[
            const Divider(height: 1),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.visibility_outlined,
                      size: 14, color: AppColors.textHint),
                  SizedBox(width: 6),
                  Text('Mode Audit — hanya Bendahara yang dapat konfirmasi',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.textHint)),
                ],
              ),
            ),
          ],

          if (!isPending && setoran.catatanBendahara != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text('Catatan: ${setoran.catatanBendahara}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ),
        ],
      ),
    );
  }

  Future<void> _showKonfirmasiDialog(BuildContext context, SetoranModel setoran,
      {required bool tolak}) async {
    final catatanCtrl = TextEditingController();
    bool isLoading = false;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setStateDlg) => AlertDialog(
          title: Text(tolak ? 'Tolak Setoran?' : 'Terima Setoran?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tolak
                  ? 'Setoran dari ${setoran.fromUserName} akan ditolak.'
                  : 'Setoran dari ${setoran.fromUserName} akan dikonfirmasi dan masuk ke kas.'),
              const SizedBox(height: 12),
              TextField(
                controller: catatanCtrl,
                enabled: !isLoading,
                decoration: InputDecoration(
                  labelText: tolak ? 'Alasan penolakan' : 'Catatan (opsional)',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: isLoading
                    ? null
                    : () => Navigator.pop(dialogContext, false),
                child: const Text('Batal')),
            FilledButton(
              onPressed:
                  isLoading ? null : () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: tolak ? AppColors.expense : AppColors.income,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(tolak ? 'Tolak' : 'Konfirmasi'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    // BUG FIX: tunjukkan loading state — gunakan snackbar loading sementara
    final messenger = ScaffoldMessenger.of(context);

    final success = await context.read<AppProvider>().konfirmasiSetoran(
          setoran.id,
          catatan:
              catatanCtrl.text.trim().isEmpty ? null : catatanCtrl.text.trim(),
          tolak: tolak,
        );

    if (!context.mounted) return;

    // BUG FIX: snackbar sukses HANYA jika success == true
    if (success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(tolak
              ? 'Setoran ditolak. Pengirim dapat mengirim ulang.'
              : 'Setoran diterima dan masuk ke kas utama.'),
          backgroundColor: tolak ? AppColors.expense : AppColors.income,
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Gagal memproses setoran. Coba lagi.'),
            backgroundColor: AppColors.expense),
      );
    }
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
