import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'storage_service.dart';
import 'revenuecat_service.dart';

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
    // Check if email exists
    if (!_storage.users.containsKey(email)) {
      addFailedAttempt(email);
      final remaining = getRemainingAttempts(email);
      return LoginResult(
        success: false,
        message: 'Email not found. Attempts remaining: $remaining',
      );
    }

    final user = _storage.users[email]!;

    // Check local password first
    if (user.password == password) {
      resetFailedAttempts(email);
      currentUser = user;
      await saveSession(email);
      if (!kIsWeb) await RevenueCatService.login(email);
      return LoginResult(success: true, message: 'Welcome, ${user.name}!', user: user);
    }

    // Local password didn't match — try Firebase Auth regardless of lock status.
    // A successful Firebase Auth proves identity and clears the lock.
    try {
      await fb.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Firebase Auth succeeded — sync new password and unlock
      resetFailedAttempts(email);
      _storage.users[email] = user.copyWith(password: password);
      _storage.saveData();
      currentUser = _storage.users[email];
      await saveSession(email);
      if (!kIsWeb) await RevenueCatService.login(email);
      return LoginResult(
        success: true,
        message: 'Welcome, ${user.name}!',
        user: currentUser,
      );
    } catch (_) {
      // Both local and Firebase Auth failed
      if (isAccountLocked(email)) {
        return LoginResult(
          success: false,
          message: 'Account locked. Use "Forgot Password?" to reset via email.',
        );
      }
      addFailedAttempt(email);
      final remaining = getRemainingAttempts(email);
      return LoginResult(
        success: false,
        message: remaining <= 0
            ? 'Account locked. Use "Forgot Password?" to reset via email.'
            : 'Incorrect password. Attempts remaining: $remaining',
      );
    }
  }

  Future<void> logout() async {
    currentUser = null;
    await _clearSession();

    // Logout from RevenueCat (mobile only)
    if (!kIsWeb) {
      await RevenueCatService.logout();
    }
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

  /// Sends a Firebase password reset email. Returns null on success, error message on failure.
  Future<String?> sendPasswordResetEmail(String email) async {
    // Look up user — local cache first, then Firestore (handles fresh web loads)
    User? user = _storage.users[email];
    if (user == null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(email)
            .get();
        if (!doc.exists || doc.data() == null) {
          return 'No account found with that email.';
        }
        user = User.fromJson(email, doc.data()!);
      } catch (_) {
        return 'No account found with that email.';
      }
    }

    try {
      // Ensure user exists in Firebase Auth before sending reset email.
      // Use a placeholder if the stored password is unusable (e.g. a legacy hash).
      final initialPassword = user.password.length >= 6
          ? user.password
          : 'irritrack_placeholder_pw';
      try {
        await fb.FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: initialPassword,
        );
      } on fb.FirebaseAuthException catch (e) {
        if (e.code != 'email-already-in-use') rethrow;
      }
      await fb.FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return null;
    } on fb.FirebaseAuthException catch (e) {
      print('FirebaseAuth error during password reset: ${e.code} — ${e.message}');
      switch (e.code) {
        case 'operation-not-allowed':
          return 'Email sign-in is not enabled. Contact your admin.';
        case 'user-not-found':
          return 'No account found with that email.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a few minutes and try again.';
        default:
          return 'Reset failed (${e.code}). Please try again.';
      }
    } catch (e) {
      print('Unexpected error during password reset: $e');
      return 'Failed to send reset email. Please try again.';
    }
  }
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
