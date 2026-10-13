import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/models.dart';
import '../../data/providers/app_provider.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TransactionCategory? _selectedCategory;
  String _searchQuery = '';
  bool _showSearch = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  TransactionType? get _selectedType {
    switch (_tabController.index) {
      case 1:
        return TransactionType.masuk;
      case 2:
        return TransactionType.keluar;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    final filtered = provider.filterTransactions(
      type: _selectedType,
      category: _selectedCategory,
      query: _searchQuery.isEmpty ? null : _searchQuery,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DayakAppBar(
        titleWidget: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: 'Cari keterangan, kategori, nama...',
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : const Text('Transaksi',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchCtrl.clear();
                _searchQuery = '';
              }
            }),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Kas Masuk'),
            Tab(text: 'Kas Keluar'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter bar kategori
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _CategoryChip(
                    label: 'Semua Kategori',
                    selected: _selectedCategory == null,
                    onTap: () => setState(() => _selectedCategory = null),
                  ),
                  const SizedBox(width: 6),
                  ...TransactionCategory.values.map((cat) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _CategoryChip(
                          label: cat.label,
                          selected: _selectedCategory == cat,
                          color: cat.color,
                          onTap: () => setState(() => _selectedCategory =
                              _selectedCategory == cat ? null : cat),
                        ),
                      )),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text('${filtered.length} transaksi',
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? const EmptyState(
                    message: 'Tidak ada transaksi ditemukan',
                    icon: Icons.search_off_outlined)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final t = filtered[i];
                      final role = provider.currentUser?.role;

                      // Hanya bendahara yang bisa edit
                      final canEdit =
                          role?.canModifyMainKas == true && t.setoranId == null;

                      final canDelete = role?.canDelete == true &&
                          provider.canDeleteTransaction(t.id);

                      return TransactionTile(
                        transaction: t,
                        onEdit: canEdit ? () => _openEdit(context, t) : null,
                        onDelete: canDelete
                            ? () => _confirmDelete(context, provider, t.id)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Buka halaman edit sesuai tipe transaksi (masuk/keluar).
  void _openEdit(BuildContext context, TransactionModel t) {
    if (t.type == TransactionType.masuk) {
      context.push('/edit-kas-masuk', extra: t);
    } else {
      context.push('/edit-kas-keluar', extra: t);
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, AppProvider provider, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: const Text('Yakin ingin menghapus transaksi ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final success = await provider.deleteTransaction(id);
    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi berhasil dihapus'),
          backgroundColor: AppColors.income,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Tidak dapat menghapus. Transaksi terkait setoran yang sudah diterima.'),
          backgroundColor: AppColors.expense,
        ),
      );
    }
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? c : AppColors.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? c : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
