import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../utils/password_hash.dart';
import 'storage_service.dart';

class AuthService {
  final StorageService _storage;
  static const String _sessionKey = 'irritrack_logged_in_email';

  AuthService(this._storage);

  // Public getter for storage (used by UI screens)
  StorageService get storage => _storage;

  User? currentUser;

  bool isAccountLocked(String email) {
    final attempts = _storage.failedAttempts[email] ?? 0;
    return attempts >= 3;
  }

  int getRemainingAttempts(String email) {
    final attempts = _storage.failedAttempts[email] ?? 0;
    return 3 - attempts;
  }

  void addFailedAttempt(String email) {
    _storage.failedAttempts[email] = (_storage.failedAttempts[email] ?? 0) + 1;
    _storage.saveData();
  }

  void resetFailedAttempts(String email) {
    _storage.failedAttempts[email] = 0;
    _storage.saveData();
  }

  Future<LoginResult> login(String email, String password) async {
    // Check if account is locked
    if (isAccountLocked(email)) {
      return LoginResult(
        success: false,
        message: 'Account locked. Please contact your manager to reset.',
      );
    }

    // Check if email exists
    if (!_storage.users.containsKey(email)) {
      addFailedAttempt(email);
      final remaining = getRemainingAttempts(email);
      return LoginResult(
        success: false,
        message: 'Email not found. Attempts remaining: $remaining',
      );
    }

    // Check if user is archived
    final user = _storage.users[email]!;
    if (user.isArchived) {
      return LoginResult(
        success: false,
        message: 'Account is deactivated. Contact your manager.',
      );
    }

    // Check password (supports both hashed and legacy plaintext)
    if (!PasswordHash.verifyPassword(password, user.password)) {
      addFailedAttempt(email);
      final remaining = getRemainingAttempts(email);
      return LoginResult(
        success: false,
        message: 'Incorrect password. Attempts remaining: $remaining',
      );
    }

    // Login successful
    resetFailedAttempts(email);

    // Migration: if password was stored in plaintext, hash it now
    if (!PasswordHash.isHashed(user.password)) {
      final hashedUser = user.copyWith(
        password: PasswordHash.hashPassword(password),
      );
      _storage.users[email] = hashedUser;
      _storage.saveData();
      currentUser = hashedUser;
    } else {
      currentUser = user;
    }

    await saveSession(email);
    return LoginResult(
      success: true,
      message: 'Welcome, ${currentUser!.name}!',
      user: currentUser,
    );
  }

  Future<void> logout() async {
    currentUser = null;
    await _clearSession();
  }

  Future<void> saveSession(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, email);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<bool> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_sessionKey);
    if (email != null && _storage.users.containsKey(email)) {
      currentUser = _storage.users[email];
      return true;
    }
    return false;
  }

  bool get isLoggedIn => currentUser != null;
  bool get isManager => currentUser?.role == 'manager';
  bool get isTechnician => currentUser?.role == 'technician';
}

class LoginResult {
  final bool success;
  final String message;
  final User? user;

  LoginResult({
    required this.success,
    required this.message,
    this.user,
  });
}
