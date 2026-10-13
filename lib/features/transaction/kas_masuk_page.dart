import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/models.dart';
import '../../data/providers/app_provider.dart';
import '../../data/repositories/repositories.dart';

// ─── Kas Masuk ────────────────────────────────────────────────────────────────
// Supports add mode (default) and edit mode (pass initialTransaction).

class KasMasukPage extends StatefulWidget {
  /// Jika [initialTransaction] diisi, page masuk mode EDIT.
  final TransactionModel? initialTransaction;

  const KasMasukPage({super.key, this.initialTransaction});

  @override
  State<KasMasukPage> createState() => _KasMasukPageState();
}

class _KasMasukPageState extends State<KasMasukPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  TransactionCategory _category = TransactionCategory.lainnya;
  DateTime _date = DateTime.now();
  bool _loading = false;

  bool get _isEditMode => widget.initialTransaction != null;

  @override
  void initState() {
    super.initState();
    // Pre-fill form jika mode edit
    if (_isEditMode) {
      final tx = widget.initialTransaction!;
      _amountCtrl.text = tx.amount.toInt().toString();
      _descCtrl.text = tx.description;
      _category = tx.category;
      _date = tx.date;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final provider = context.read<AppProvider>();
      final user = provider.currentUser;

      if (user == null) {
        _showError('Sesi login habis. Silakan login ulang.');
        return;
      }

      if (!user.role.canModifyMainKas) {
        _showError('Hanya Bendahara yang dapat mencatat kas masuk.');
        return;
      }

      final rawAmount = _amountCtrl.text.replaceAll(RegExp(r'[^\d]'), '');
      final amount = double.tryParse(rawAmount) ?? 0;

      if (amount <= 0) {
        _showError('Jumlah harus lebih dari 0.');
        return;
      }

      if (_isEditMode) {
        // MODE EDIT: update transaksi yang ada
        final updated = widget.initialTransaction!.copyWith(
          category: _category,
          amount: amount,
          description: _descCtrl.text.trim(),
          date: _date,
        );
        await provider.updateTransaction(updated);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kas masuk berhasil diperbarui'),
            backgroundColor: AppColors.income,
          ),
        );
      } else {
        // MODE TAMBAH: buat transaksi baru
        await provider.addTransaction(TransactionModel(
          id: const Uuid().v4(),
          type: TransactionType.masuk,
          category: _category,
          amount: amount,
          description: _descCtrl.text.trim(),
          date: _date,
          createdBy: user.id,
          createdByName: user.name,
          createdByRole: user.role,
        ));

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kas masuk berhasil dicatat'),
            backgroundColor: AppColors.income,
          ),
        );
      }

      if (!mounted) return;
      context.pop();
    } on PermissionException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } on ValidationException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      _showError('Gagal menyimpan: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
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
    return _TransactionForm(
      formKey: _formKey,
      title: _isEditMode ? 'Edit Kas Masuk' : 'Tambah Kas Masuk',
      type: TransactionType.masuk,
      amountCtrl: _amountCtrl,
      descCtrl: _descCtrl,
      selectedCategory: _category,
      selectedDate: _date,
      loading: _loading,
      onCategoryChanged: (c) => setState(() => _category = c),
      onDateChanged: (d) => setState(() => _date = d),
      onSubmit: _submit,
      isEditMode: _isEditMode,
    );
  }
}

// ─── Kas Keluar ───────────────────────────────────────────────────────────────

class KasKeluarPage extends StatefulWidget {
  /// Jika [initialTransaction] diisi, page masuk mode EDIT.
  final TransactionModel? initialTransaction;

  const KasKeluarPage({super.key, this.initialTransaction});

  @override
  State<KasKeluarPage> createState() => _KasKeluarPageState();
}

class _KasKeluarPageState extends State<KasKeluarPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  TransactionCategory _category = TransactionCategory.lainnya;
  DateTime _date = DateTime.now();
  bool _loading = false;

  bool get _isEditMode => widget.initialTransaction != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      // Mode EDIT: pre-fill dari data yang ada
      final tx = widget.initialTransaction!;
      _amountCtrl.text = tx.amount.toInt().toString();
      _descCtrl.text = tx.description;
      _category = tx.category;
      _date = tx.date;
    } else {
      // Mode TAMBAH: auto-set kategori sesuai role divisi
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final role = context.read<AppProvider>().currentUser?.role;
        if (role == UserRole.perlengkapan) {
          setState(() => _category = TransactionCategory.perlengkapan);
        } else if (role == UserRole.konsumsi) {
          setState(() => _category = TransactionCategory.konsumsi);
        }
      });
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final provider = context.read<AppProvider>();
      final user = provider.currentUser;

      if (user == null) {
        _showError('Sesi login habis. Silakan login ulang.');
        return;
      }

      final rawAmount = _amountCtrl.text.replaceAll(RegExp(r'[^\d]'), '');
      final amount = double.tryParse(rawAmount) ?? 0;

      if (amount <= 0) {
        _showError('Jumlah harus lebih dari 0.');
        return;
      }

      if (_isEditMode) {
        // MODE EDIT: hanya bendahara yang bisa edit transaksi
        final updated = widget.initialTransaction!.copyWith(
          category: _category,
          amount: amount,
          description: _descCtrl.text.trim(),
          date: _date,
        );
        await provider.updateTransaction(updated);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kas keluar berhasil diperbarui'),
            backgroundColor: AppColors.income,
          ),
        );
        context.pop();
      } else {
        // MODE TAMBAH: logika divisi vs bendahara tetap sama
        final tx = TransactionModel(
          id: const Uuid().v4(),
          type: TransactionType.keluar,
          category: _category,
          amount: amount,
          description: _descCtrl.text.trim(),
          date: _date,
          createdBy: user.id,
          createdByName: user.name,
          createdByRole: user.role,
        );

        final isDivisi = user.role.canSubmitSetoran;

        if (isDivisi) {
          provider.addDraftTransaction(tx);
        } else {
          await provider.addTransaction(tx);
        }

        if (!mounted) return;

        final msg = isDivisi
            ? 'Transaksi disimpan ke draft setoran'
            : 'Kas keluar berhasil dicatat';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: isDivisi ? AppColors.primaryMid : AppColors.income,
          ),
        );
        context.pop();
      }
    } on ValidationException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } on PermissionException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (e) {
      if (!mounted) return;
      _showError('Gagal menyimpan: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
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
    final role = provider.currentUser?.role;
    final isDivisi = role?.canSubmitSetoran ?? false;
    final allowedCats = role?.allowedCategories;

    return _TransactionForm(
      formKey: _formKey,
      title: _isEditMode
          ? 'Edit Kas Keluar'
          : (isDivisi ? 'Catat Pengeluaran' : 'Tambah Kas Keluar'),
      type: TransactionType.keluar,
      amountCtrl: _amountCtrl,
      descCtrl: _descCtrl,
      selectedCategory: _category,
      selectedDate: _date,
      loading: _loading,
      allowedCategories: allowedCats,
      onCategoryChanged: (c) => setState(() => _category = c),
      onDateChanged: (d) => setState(() => _date = d),
      onSubmit: _submit,
      bottomNote: (!_isEditMode && isDivisi)
          ? 'Transaksi akan masuk ke draft untuk disetor ke bendahara'
          : null,
      currentSaldo:
          (!_isEditMode && !isDivisi) ? provider.summary.totalSaldo : null,
      isEditMode: _isEditMode,
    );
  }
}

// ─── Shared form widget ───────────────────────────────────────────────────────

class _TransactionForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final String title;
  final TransactionType type;
  final TextEditingController amountCtrl;
  final TextEditingController descCtrl;
  final TransactionCategory selectedCategory;
  final DateTime selectedDate;
  final bool loading;
  final List<TransactionCategory>? allowedCategories;
  final ValueChanged<TransactionCategory> onCategoryChanged;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onSubmit;
  final String? bottomNote;
  final double? currentSaldo;
  final bool isEditMode;

  const _TransactionForm({
    required this.formKey,
    required this.title,
    required this.type,
    required this.amountCtrl,
    required this.descCtrl,
    required this.selectedCategory,
    required this.selectedDate,
    required this.loading,
    required this.onCategoryChanged,
    required this.onDateChanged,
    required this.onSubmit,
    this.allowedCategories,
    this.bottomNote,
    this.currentSaldo,
    this.isEditMode = false,
  });

  bool get isIncome => type == TransactionType.masuk;
  Color get accentColor => isIncome ? AppColors.income : AppColors.expense;

  @override
  Widget build(BuildContext context) {
    final cats = allowedCategories ?? TransactionCategory.values;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DayakAppBar(
        title: title,
        backgroundColor: accentColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingM),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info mode edit
              if (isEditMode) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.edit_outlined,
                          size: 16, color: AppColors.primaryMid),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mode edit — perubahan langsung tersimpan ke Firestore',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.primaryMid),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Saldo tersedia (hanya kas keluar tambah baru, bendahara)
              if (!isIncome && currentSaldo != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: currentSaldo! < 0
                        ? AppColors.expenseLight
                        : AppColors.incomeLight,
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                    border: Border.all(
                      color: currentSaldo! < 0
                          ? AppColors.expense.withValues(alpha: 0.3)
                          : AppColors.income.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 16,
                        color: currentSaldo! < 0
                            ? AppColors.expense
                            : AppColors.income,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Saldo tersedia: ${CurrencyFormatter.format(currentSaldo!)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: currentSaldo! < 0
                              ? AppColors.expense
                              : AppColors.income,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Jumlah
              TextFormField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  labelText: AppStrings.jumlah,
                  prefixText: 'Rp ',
                  prefixStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: accentColor),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusM)),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Jumlah wajib diisi';
                  final parsed = double.tryParse(v);
                  if (parsed == null || parsed <= 0) {
                    return 'Jumlah tidak valid';
                  }
                  if (!isIncome &&
                      currentSaldo != null &&
                      parsed > currentSaldo!) {
                    return 'Jumlah melebihi saldo (${CurrencyFormatter.format(currentSaldo!)})';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Kategori
              const Text(AppStrings.kategori,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cats.map((cat) {
                  final selected = selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => onCategoryChanged(cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? cat.color.withValues(alpha: 0.12)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: selected ? cat.color : AppColors.divider,
                            width: selected ? 1.5 : 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.icon,
                              size: 14,
                              color: selected
                                  ? cat.color
                                  : AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(cat.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: selected
                                    ? cat.color
                                    : AppColors.textSecondary,
                              )),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Keterangan
              TextFormField(
                controller: descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: AppStrings.deskripsi,
                  hintText: 'Contoh: Beli nasi kotak rapat',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusM)),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Keterangan wajib diisi'
                    : null,
              ),
              const SizedBox(height: 16),

              // Tanggal
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: ColorScheme.light(primary: accentColor),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) onDateChanged(picked);
                },
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(AppStrings.tanggal,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                            Text(DateFormatter.full(selectedDate),
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: AppColors.textHint),
                    ],
                  ),
                ),
              ),

              if (bottomNote != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: AppColors.primaryMid),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(bottomNote!,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.primaryMid))),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              AppButton(
                label: isEditMode ? 'Simpan Perubahan' : AppStrings.simpan,
                onPressed: onSubmit,
                loading: loading,
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
