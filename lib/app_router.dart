import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'data/providers/app_provider.dart';
import 'data/models/models.dart';
import 'features/auth/login_page.dart';
import 'features/shell/main_shell.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/transaction/history_page.dart';
import 'features/transaction/kas_masuk_page.dart';
import 'features/laporan/laporan_page.dart';
import 'features/profile/profile_page.dart';
import 'features/setoran/setoran_page.dart';
import 'features/setoran/setoran_masuk_page.dart';

final _rootNavKey = GlobalKey<NavigatorState>();
final _shellNavKey = GlobalKey<NavigatorState>();

GoRouter buildRouter(AppProvider provider) {
  return GoRouter(
    navigatorKey: _rootNavKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final loggedIn = provider.isLoggedIn;
      final onLogin = state.matchedLocation == '/login';
      if (!loggedIn && !onLogin) return '/login';
      if (loggedIn && onLogin) return '/beranda';
      return null;
    },
    refreshListenable: provider,
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginPage(),
      ),

      ShellRoute(
        navigatorKey: _shellNavKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/beranda', builder: (_, __) => const DashboardPage()),
          GoRoute(path: '/transaksi', builder: (_, __) => const HistoryPage()),
          GoRoute(path: '/laporan', builder: (_, __) => const LaporanPage()),
          GoRoute(path: '/profil', builder: (_, __) => const ProfilePage()),
        ],
      ),

      // ── Tambah transaksi (mode baru) ──────────────────────────────────────
      GoRoute(
        path: '/kas-masuk',
        builder: (_, __) => const KasMasukPage(),
        redirect: (context, state) {
          final role = provider.currentUser?.role;
          if (role == null) return '/login';
          if (!role.canModifyMainKas) return '/beranda';
          return null;
        },
      ),

      GoRoute(
        path: '/kas-keluar',
        builder: (_, __) => const KasKeluarPage(),
        redirect: (context, state) {
          final role = provider.currentUser?.role;
          if (role == null) return '/login';
          if (!role.canAddTransaction) return '/beranda';
          return null;
        },
      ),

      // ── Edit transaksi (mode edit) ─────────────────────────────────────────
      // extra: TransactionModel yang akan diedit
      GoRoute(
        path: '/edit-kas-masuk',
        builder: (_, state) {
          final tx = state.extra as TransactionModel;
          return KasMasukPage(initialTransaction: tx);
        },
        redirect: (context, state) {
          final role = provider.currentUser?.role;
          if (role == null) return '/login';
          // Hanya bendahara yang bisa edit kas masuk
          if (!role.canModifyMainKas) return '/transaksi';
          return null;
        },
      ),

      GoRoute(
        path: '/edit-kas-keluar',
        builder: (_, state) {
          final tx = state.extra as TransactionModel;
          return KasKeluarPage(initialTransaction: tx);
        },
        redirect: (context, state) {
          final role = provider.currentUser?.role;
          if (role == null) return '/login';
          // Hanya bendahara yang bisa edit kas keluar
          if (!role.canModifyMainKas) return '/transaksi';
          return null;
        },
      ),

      // ── Setoran ───────────────────────────────────────────────────────────
      GoRoute(
        path: '/setoran',
        builder: (_, __) => const SetoranPage(),
        redirect: (context, state) {
          final role = provider.currentUser?.role;
          if (role == null) return '/login';
          if (!role.canSubmitSetoran) return '/beranda';
          return null;
        },
      ),

      GoRoute(
        path: '/setoran-masuk',
        builder: (_, __) => const SetoranMasukPage(),
        redirect: (context, state) {
          final role = provider.currentUser?.role;
          if (role == null) return '/login';
          final canView = role == UserRole.ketua || role == UserRole.bendahara;
          if (!canView) return '/beranda';
          return null;
        },
      ),
    ],
  );
}
