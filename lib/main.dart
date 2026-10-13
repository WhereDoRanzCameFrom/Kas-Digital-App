import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/constants/app_constants.dart';
import 'data/providers/app_provider.dart';
import 'data/repositories/firebase_repositories.dart';
import 'app_theme.dart';
import 'app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi Firebase hanya kalau flag aktif
  if (kUseFirebase) {
    await Firebase.initializeApp();
  }

  runApp(const KasDigitar85App());
}

class KasDigitar85App extends StatefulWidget {
  const KasDigitar85App({super.key});

  @override
  State<KasDigitar85App> createState() => _KasDigitar85AppState();
}

class _KasDigitar85AppState extends State<KasDigitar85App> {
  late final AppProvider _provider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    // Inject repository berdasarkan flag kUseFirebase
    _provider = kUseFirebase
        ? AppProvider(
            authRepo: FirebaseAuthRepository(),
            txRepo: FirebaseTransactionRepository(),
            setoranRepo: FirebaseSetoranRepository(),
            announcementRepo: FirebaseAnnouncementRepository(),
            budgetRepo: FirebaseBudgetRepository(),
            dataRepo: FirebaseDataRepository(),
          )
        : AppProvider(); // pakai DummyRepositories secara default

    _router = buildRouter(_provider);
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: MaterialApp.router(
        title: 'Kas Digital 85',
        theme: buildAppTheme(),
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
