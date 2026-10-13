import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/models/models.dart';
import '../../data/providers/app_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  UserModel? _selectedUser;
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscurePin = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    // Load daftar user saat halaman dibuka (siap untuk swicth ke Firestore nanti)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadUsers();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_selectedUser == null) {
      setState(() => _errorMsg = 'Pilih pengguna terlebih dahulu');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    if (!mounted) return;

    // Login sekarang async — data tidak di-reset, hanya di-load
    final ok = await context.read<AppProvider>().login(
          _selectedUser!.id,
          _pinController.text,
        );

    if (!mounted) return;

    setState(() => _loading = false);

    if (ok) {
      context.go('/beranda');
    } else {
      final authError =
          context.read<AppProvider>().authError ?? AppStrings.pinSalah;
      setState(() => _errorMsg = authError);
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    // watch supaya list user ter-refresh setelah loadUsers() selesai
    final users = context.watch<AppProvider>().allUsers;
    final headerHeight = MediaQuery.of(context).size.height * 0.30;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          // ── Header hijau (fixed height)
          SizedBox(
            height: headerHeight,
            child: SafeArea(
              bottom: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(6),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/icon.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      AppStrings.appName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.appSubtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Form card putih
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppSizes.radiusXL),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.paddingL,
                    AppSizes.paddingL,
                    AppSizes.paddingL,
                    AppSizes.paddingL,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Masuk ke Akun',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Pilih nama dan masukkan PIN kamu',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Pilih pengguna
                        DropdownButtonFormField<UserModel>(
                          initialValue: _selectedUser,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: AppStrings.pilihPengguna,
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusM),
                            ),
                            filled: true,
                            fillColor: AppColors.surface,
                          ),
                          items: users
                              .map(
                                (u) => DropdownMenuItem(
                                  value: u,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          u.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      RoleBadge(role: u.role),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (u) => setState(() {
                            _selectedUser = u;
                            _errorMsg = null;
                          }),
                        ),
                        const SizedBox(height: 16),

                        // PIN
                        TextFormField(
                          controller: _pinController,
                          obscureText: _obscurePin,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          decoration: InputDecoration(
                            labelText: AppStrings.masukkanPin,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePin
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePin = !_obscurePin),
                            ),
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusM),
                            ),
                            filled: true,
                            fillColor: AppColors.surface,
                            errorText: _errorMsg,
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'PIN tidak boleh kosong'
                              : null,
                          onFieldSubmitted: (_) => _login(),
                        ),
                        const SizedBox(height: 24),

                        AppButton(
                          label: AppStrings.login,
                          onPressed: _login,
                          loading: _loading,
                          icon: Icons.login_rounded,
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
