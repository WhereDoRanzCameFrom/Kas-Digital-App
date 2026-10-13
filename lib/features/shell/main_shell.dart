import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/models.dart';
import '../../data/providers/app_provider.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = ['/beranda', '/transaksi', '/laporan', '/profil'];

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final i = _tabs.indexOf(loc);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final role = provider.currentUser?.role;
    final idx = _currentIndex(context);
    final hasFab = role != null && role.canAddTransaction;

    return Scaffold(
      body: child,
      // FAB hanya muncul jika role bisa tambah transaksi (bukan ketua)
      floatingActionButton: hasFab ? _buildFab(context, role) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(context, idx, role, hasFab),
    );
  }

  Widget _buildFab(BuildContext context, UserRole role) {
    return FloatingActionButton(
      onPressed: () => _onFabPressed(context, role),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 4,
      child: const Icon(Icons.add_rounded, size: 28),
    );
  }

  void _onFabPressed(BuildContext context, UserRole role) {
    if (role == UserRole.bendahara) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXL)),
        ),
        builder: (_) => _FabBottomSheet(),
      );
    } else if (role.canSubmitSetoran) {
      context.push('/kas-keluar');
    }
  }

  Widget _buildBottomNav(
      BuildContext context, int idx, UserRole? role, bool hasFab) {
    // Jika tidak ada FAB (ketua), gunakan NavigationBar biasa tanpa notch
    if (!hasFab) {
      return NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => context.go(_tabs[i]),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primarySurface,
        height: 64,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
            label: 'Beranda',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon:
                Icon(Icons.receipt_long_rounded, color: AppColors.primary),
            label: 'Transaksi',
          ),
          NavigationDestination(
            icon: _BadgeIcon(
              icon: Icons.bar_chart_outlined,
              count: role == UserRole.bendahara
                  ? context.watch<AppProvider>().pendingSetorans.length
                  : 0,
            ),
            selectedIcon:
                const Icon(Icons.bar_chart_rounded, color: AppColors.primary),
            label: 'Laporan',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
            label: 'Profil',
          ),
        ],
      );
    }

    // Dengan FAB: BottomAppBar + notch
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: AppColors.surface,
      elevation: 8,
      child: Row(
        children: [
          _NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Beranda',
              index: 0,
              current: idx),
          _NavItem(
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long_rounded,
              label: 'Transaksi',
              index: 1,
              current: idx),
          const SizedBox(width: 56), // FAB notch space
          _NavItem(
            icon: Icons.bar_chart_outlined,
            activeIcon: Icons.bar_chart_rounded,
            label: 'Laporan',
            index: 2,
            current: idx,
            badge: role == UserRole.bendahara
                ? context.watch<AppProvider>().pendingSetorans.length
                : 0,
          ),
          _NavItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Profil',
              index: 3,
              current: idx),
        ],
      ),
    );
  }
}

// ── Badge icon helper (untuk NavigationDestination) ───────────────────────────
class _BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int count;
  const _BadgeIcon({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return Icon(icon);
    return Badge(
      label: Text('$count'),
      backgroundColor: AppColors.expense,
      child: Icon(icon),
    );
  }
}

// ── Nav item untuk BottomAppBar ───────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final int badge;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    this.badge = 0,
  });

  static const _tabs = ['/beranda', '/transaksi', '/laporan', '/profil'];

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return Expanded(
      child: InkWell(
        onTap: () => context.go(_tabs[index]),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    active ? activeIcon : icon,
                    color: active ? AppColors.primary : AppColors.textSecondary,
                    size: 24,
                  ),
                  if (badge > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                            color: AppColors.expense, shape: BoxShape.circle),
                        child: Center(
                          child: Text('$badge',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FabBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tambah Transaksi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                context.push('/kas-masuk');
              },
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                    color: AppColors.incomeLight, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_upward_rounded,
                    color: AppColors.income),
              ),
              title: const Text('Kas Masuk',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Catat pemasukan kas'),
              trailing: const Icon(Icons.chevron_right),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusM)),
            ),
            const SizedBox(height: 4),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                context.push('/kas-keluar');
              },
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                    color: AppColors.expenseLight, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_downward_rounded,
                    color: AppColors.expense),
              ),
              title: const Text('Kas Keluar',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Catat pengeluaran kas'),
              trailing: const Icon(Icons.chevron_right),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusM)),
            ),
          ],
        ),
      ),
    );
  }
}
