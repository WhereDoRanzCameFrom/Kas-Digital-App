import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/models.dart';

/// Mengelola autentikasi berbasis PIN dan sesi login secara lokal.
///
/// Semua data tersimpan di SharedPreferences device:
///   - `pin_hash_{userId}` → SHA-256 dari PIN user
///   - `session_user`      → JSON UserModel yang sedang login
///
/// PIN **tidak pernah** dikirim atau disimpan ke Firestore.
class LocalAuthService {
  LocalAuthService._();
  static final LocalAuthService instance = LocalAuthService._();

  // ── Key constants ────────────────────────────────────────────────────────
  static const _keySession = 'session_user';
  static String _pinKey(String userId) => 'pin_hash_$userId';

  // ── PIN Management ───────────────────────────────────────────────────────

  /// Hash PIN pakai SHA-256.
  static String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  /// Simpan PIN user ke lokal (dipanggil saat setup awal / seed user).
  Future<void> savePin(String userId, String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey(userId), _hashPin(pin));
  }

  /// Verifikasi PIN user. Return true jika cocok.
  Future<bool> verifyPin(String userId, String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_pinKey(userId));
    if (stored == null) return false;
    return stored == _hashPin(pin);
  }

  /// Cek apakah PIN sudah tersimpan untuk user ini.
  Future<bool> hasPinStored(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_pinKey(userId));
  }

  // ── Session Management ───────────────────────────────────────────────────

  /// Simpan sesi login (UserModel tanpa PIN).
  Future<void> saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySession, jsonEncode(user.toJsonSafe()));
  }

  /// Ambil sesi login terakhir. Null kalau belum pernah login.
  Future<UserModel?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySession);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Hapus sesi login (logout).
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySession);
  }

  /// Hapus PIN semua user yang tersimpan.
  /// Dipanggil kalau mau reset total (misal reinstall app manual).
  Future<void> clearAllPins(List<String> userIds) async {
    final prefs = await SharedPreferences.getInstance();
    for (final id in userIds) {
      await prefs.remove(_pinKey(id));
    }
  }
}
