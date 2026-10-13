import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/models.dart';
import '../../data/providers/app_provider.dart';

class SetoranPage extends StatefulWidget {
  const SetoranPage({super.key});

  @override
  State<SetoranPage> createState() => _SetoranPageState();
}

class _SetoranPageState extends State<SetoranPage> {
  final _catatanCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _catatanCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitSetoran() async {
    if (_submitting) return; // BUG FIX: cegah double-submit (race condition)

    final provider = context.read<AppProvider>();

    // BUG FIX: role check sebelum tampilkan dialog
    final user = provider.currentUser;
    if (user == null || !user.role.canSubmitSetoran) {
      _showError('Hanya divisi yang dapat mengirim setoran');
      return;
    }

    if (provider.draftTransactions.isEmpty) {
      _showError('Tambah transaksi terlebih dahulu');
      return;
    }

    final total = provider.draftTransactions.fold(0.0, (s, t) => s + t.amount);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Setor Laporan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jumlah transaksi: ${provider.draftTransactions.length}'),
            Text('Total: ${CurrencyFormatter.format(total)}'),
            const SizedBox(height: 12),
            TextField(
              controller: _catatanCtrl,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                hintText: 'Contoh: Laporan harian 5 Juni',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Kirim Sekarang'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _submitting = true);

    // BUG FIX: await dan tangani false return
    final success = await provider.submitSetoran(
      catatan: _catatanCtrl.text.trim().isEmpty ? null : _catatanCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Setoran berhasil dikirim ke bendahara'),
          backgroundColor: AppColors.income,
        ),
      );
      context.pop();
    } else {
      _showError('Gagal mengirim setoran. Pastikan ada transaksi dan jumlah valid.');
    }
  }

  void _editDraft(TransactionModel tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusL)),
      ),
      builder: (_) => _EditDraftSheet(
        transaction: tx,
        onSave: (updated) {
          context.read<AppProvider>().updateDraftTransaction(updated);
        },
      ),
    );
  }

  Future<void> _deleteDraft(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Draft?'),
        content: const Text('Transaksi ini akan dihapus dari draft.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<AppProvider>().removeDraftTransaction(id);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.expense),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final drafts = provider.draftTransactions;
    final mySetorans = provider.mySetorans;
    final total = drafts.fold(0.0, (s, t) => s + t.amount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const DayakAppBar(title: 'Setor Laporan Harian'),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingM),
            color: AppColors.primarySurface,
            child: Row(
              children: [
                const Icon(Icons.upload_outlined, color: AppColors.primaryMid),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${drafts.length} transaksi draft · ${CurrencyFormatter.format(total)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryMid),
                      ),
                      const Text(
                        'Catat semua pengeluaran hari ini, lalu setor ke bendahara',
                        style:
                            TextStyle(fontSize: 12, color: AppColors.primaryMid),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.push('/kas-keluar'),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Transaksi'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusM)),
                  ),
                ),
                const SizedBox(height: 16),

                if (drafts.isNotEmpty) ...[
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Draft Transaksi',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Hapus Semua Draft?'),
                              content: const Text(
                                  'Semua draft transaksi akan dihapus.'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Batal')),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.expense),
                                  child: const Text('Hapus Semua'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true && mounted) {
                            context
                                .read<AppProvider>()
                                .clearDraftTransactions();
                          }
                        },
                        icon: const Icon(Icons.delete_outline,
                            size: 16, color: AppColors.expense),
                        label: const Text('Hapus Semua',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.expense)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...drafts.map((t) => _DraftTile(
                        transaction: t,
                        onEdit: () => _editDraft(t),
                        onDelete: () => _deleteDraft(t.id),
                      )),
                  const SizedBox(height: 16),
                ],

                if (mySetorans.isNotEmpty) ...[
                  const Text('Riwayat Setoran',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ...mySetorans.map((s) => _SetoranHistoryTile(setoran: s)),
                ],
              ],
            ),
          ),

          // BUG FIX: disable tombol saat sedang submitting (cegah double-submit)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              child: AppButton(
                label: _submitting
                    ? 'Mengirim...'
                    : 'Setor ke Bendahara (${drafts.length} transaksi)',
                onPressed: (drafts.isEmpty || _submitting) ? null : _submitSetoran,
                loading: _submitting,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Draft Tile ────────────────────────────────────────────────────────────────

class _DraftTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DraftTile({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: transaction.category.color.withValues(alpha: 0.12),
          child: Icon(transaction.category.icon,
              size: 16, color: transaction.category.color),
        ),
        title: Text(transaction.description,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${transaction.category.label} · ${DateFormatter.short(transaction.date)}',
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              CurrencyFormatter.format(transaction.amount),
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.expense,
                  fontSize: 13),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  size: 16, color: AppColors.primary),
              onPressed: onEdit,
              visualDensity: VisualDensity.compact,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 16, color: AppColors.expense),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
              tooltip: 'Hapus',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Edit Draft Bottom Sheet ───────────────────────────────────────────────────

class _EditDraftSheet extends StatefulWidget {
  final TransactionModel transaction;
  final ValueChanged<TransactionModel> onSave;

  const _EditDraftSheet({required this.transaction, required this.onSave});

  @override
  State<_EditDraftSheet> createState() => _EditDraftSheetState();
}

class _EditDraftSheetState extends State<_EditDraftSheet> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _descCtrl;
  late TransactionCategory _category;
  late DateTime _date;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
        text: widget.transaction.amount.toInt().toString());
    _descCtrl = TextEditingController(text: widget.transaction.description);
    _category = widget.transaction.category;
    _date = widget.transaction.date;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final raw = _amountCtrl.text.replaceAll(RegExp(r'[^\d]'), '');
    final amount = double.tryParse(raw) ?? 0;
    if (amount <= 0) return;

    // BUG FIX: validasi kategori yang diizinkan untuk role pengguna
    final provider = context.read<AppProvider>();
    final allowed = provider.currentUser?.role.allowedCategories;
    final finalCategory =
        (allowed != null && !allowed.contains(_category)) ? allowed.first : _category;

    final updated = widget.transaction.copyWith(
      amount: amount,
      description: _descCtrl.text.trim(),
      category: finalCategory,
      date: _date,
    );
    widget.onSave(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final allowedCats = provider.currentUser?.role.allowedCategories ??
        TransactionCategory.values.toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSizes.paddingM,
        right: AppSizes.paddingM,
        top: AppSizes.paddingM,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Draft Transaksi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Jumlah',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Wajib diisi';
                  if ((double.tryParse(v) ?? 0) <= 0) return 'Jumlah harus > 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Keterangan',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              const Text('Kategori',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              // BUG FIX: hanya tampilkan kategori yang diizinkan untuk role
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allowedCats.map((cat) {
                  final selected = _category == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _category = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? cat.color.withValues(alpha: 0.12)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: selected ? cat.color : AppColors.divider),
                      ),
                      child: Text(cat.label,
                          style: TextStyle(
                              fontSize: 12,
                              color: selected
                                  ? cat.color
                                  : AppColors.textSecondary)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      child: const Text('Simpan'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Riwayat Setoran Tile ──────────────────────────────────────────────────────

class _SetoranHistoryTile extends StatelessWidget {
  final SetoranModel setoran;
  const _SetoranHistoryTile({required this.setoran});

  @override
  Widget build(BuildContext context) {
    final isDitolak = setoran.status == SetoranStatus.ditolak;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(AppSizes.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border: Border.all(
          color: isDitolak
              ? AppColors.expense.withValues(alpha: 0.4)
              : AppColors.divider.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormatter.full(setoran.tanggalSetor),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    if (setoran.catatan != null)
                      Text(setoran.catatan!,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(
                      '${setoran.transactions.length} transaksi · ${CurrencyFormatter.format(setoran.totalAmount)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              SetoranStatusBadge(status: setoran.status),
            ],
          ),

          if (setoran.catatanBendahara != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDitolak
                    ? AppColors.expense.withValues(alpha: 0.06)
                    : AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppSizes.radiusS),
              ),
              child: Row(
                children: [
                  Icon(
                    isDitolak ? Icons.info_outline : Icons.check_circle_outline,
                    size: 14,
                    color: isDitolak ? AppColors.expense : AppColors.primaryMid,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Bendahara: ${setoran.catatanBendahara}',
                      style: TextStyle(
                          fontSize: 12,
                          color: isDitolak
                              ? AppColors.expense
                              : AppColors.primaryMid),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (isDitolak) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _resubmit(context, setoran),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Kirim Ulang Setoran'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _resubmit(BuildContext context, SetoranModel setoran) async {
    final catatanCtrl = TextEditingController(text: setoran.catatan ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Kirim Ulang Setoran?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${setoran.transactions.length} transaksi · ${CurrencyFormatter.format(setoran.totalAmount)}'),
            const SizedBox(height: 12),
            TextField(
              controller: catatanCtrl,
              decoration: const InputDecoration(
                labelText: 'Catatan revisi (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kirim Ulang'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    // BUG FIX: catatan null jika kosong (resubmit tidak menghapus catatan lama jika tidak diisi)
    final newCatatan = catatanCtrl.text.trim().isEmpty ? null : catatanCtrl.text.trim();

    final success = await context.read<AppProvider>().resubmitSetoran(
          setoran.id,
          catatan: newCatatan,
        );

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Setoran berhasil dikirim ulang'),
            backgroundColor: AppColors.income),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Gagal mengirim ulang. Coba lagi.'),
            backgroundColor: AppColors.expense),
      );
    }
  }
}
