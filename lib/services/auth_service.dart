import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_functions/cloud_functions.dart';
import '../models/user.dart';
import 'firestore_service.dart';
import 'storage_service.dart';

/// Authentication is handled entirely by Firebase Auth.
/// Firestore user documents (keyed by uid) hold profile data only —
/// no credentials. Role and companyId are carried as custom claims on
/// the ID token, assigned server-side by Cloud Functions.
class AuthService {
  final StorageService _storage;
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  AuthService(this._storage);

  // Public getter for storage (used by UI screens)
  StorageService get storage => _storage;

  User? currentUser;

  Future<LoginResult> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final fbUser = cred.user;
      if (fbUser == null) {
        return LoginResult(success: false, message: 'Login failed. Please try again.');
      }
      return await _completeSignIn(fbUser);
    } on fb.FirebaseAuthException catch (e) {
      return LoginResult(success: false, message: _friendlyAuthError(e));
    }
  }

  /// First-time company signup: creates the Firebase Auth account, then a
  /// Cloud Function assigns the manager role + a new companyId as custom
  /// claims and creates the profile document server-side.
  Future<LoginResult> registerCompany({
    required String companyName,
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      fb.UserCredential cred;
      try {
        cred = await _auth.createUserWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );
      } on fb.FirebaseAuthException catch (e) {
        if (e.code != 'email-already-in-use') rethrow;
        // A previous signup attempt may have created the Auth account but
        // failed before company setup completed. Sign in and resume.
        try {
          cred = await _auth.signInWithEmailAndPassword(
            email: normalizedEmail,
            password: password,
          );
        } on fb.FirebaseAuthException {
          return LoginResult(
            success: false,
            message: 'An account with this email already exists. '
                'Sign in instead, or use "Forgot Password".',
          );
        }
      }
      final fbUser = cred.user;
      if (fbUser == null) {
        return LoginResult(success: false, message: 'Signup failed. Please try again.');
      }

      // Only bootstrap a company if this account doesn't belong to one yet
      final token = await fbUser.getIdTokenResult(true);
      if (token.claims?['companyId'] == null) {
        await _functions.httpsCallable('bootstrapCompany').call({
          'companyName': companyName,
          'name': name,
        });
      }
      return await _completeSignIn(fbUser);
    } on fb.FirebaseAuthException catch (e) {
      return LoginResult(success: false, message: _friendlyAuthError(e));
    } on FirebaseFunctionsException catch (e) {
      // Don't leave a half-signed-in session with no company claims
      await _auth.signOut();
      if (e.code == 'not-found' || e.code == 'internal' || e.code == 'unavailable') {
        return LoginResult(
          success: false,
          message: 'Account setup service is unavailable right now. '
              'Your email and password are saved — try again later.',
        );
      }
      return LoginResult(success: false, message: e.message ?? 'Account setup failed.');
    }
  }

  /// Manager-only: create a technician/manager account within the company.
  /// Runs server-side so the manager's own session is untouched and the
  /// new user's claims are set atomically.
  Future<void> createUser({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    await _functions.httpsCallable('createUser').call({
      'email': email.trim().toLowerCase(),
      'password': password,
      'name': name,
      'role': role,
    });
  }

  /// Manager-only: change another user's role (updates claims server-side).
  Future<void> setUserRole(String uid, String role) async {
    await _functions.httpsCallable('setUserRole').call({'uid': uid, 'role': role});
  }

  /// Manager-only: archive/unarchive a user. Archiving also disables the
  /// Firebase Auth account so the user cannot sign in.
  Future<void> setUserArchived(String uid, bool archived) async {
    await _functions
        .httpsCallable('setUserArchived')
        .call({'uid': uid, 'archived': archived});
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }

  Future<void> logout() async {
    currentUser = null;
    await _auth.signOut();
    FirestoreService().clearClaims();
  }

  /// Restore a persisted Firebase Auth session (if any) and load the profile.
  Future<bool> restoreSession() async {
    final fbUser = await _auth.authStateChanges().first;
    if (fbUser == null) return false;
    try {
      final result = await _completeSignIn(fbUser, syncData: false);
      return result.success;
    } catch (_) {
      return false;
    }
  }

  Future<LoginResult> _completeSignIn(fb.User fbUser, {bool syncData = true}) async {
    // Force-refresh so newly assigned custom claims are on the token
    await fbUser.getIdToken(true);
    await FirestoreService().refreshClaims();

    final profile = await FirestoreService().getUserProfile(fbUser.uid);
    if (profile == null) {
      // No profile doc. If there's also no company claim, this is an
      // interrupted company signup — the owner can resume it themselves.
      final hasCompany = FirestoreService().companyId != null;
      await _auth.signOut();
      return LoginResult(
        success: false,
        message: hasCompany
            ? 'Your account is not fully set up. Contact your manager.'
            : 'Your company setup is incomplete. Tap "Create Account" and '
              'sign up again with this email and password to finish it.',
      );
    }
    if (profile.isArchived) {
      await _auth.signOut();
      return LoginResult(
        success: false,
        message: 'Account is deactivated. Contact your manager.',
      );
    }

    currentUser = profile;
    _storage.users[profile.email] = profile;

    if (syncData && _storage.firestoreSyncEnabled) {
      try {
        await _storage.downloadFromFirestore();
      } catch (_) {}
    }

    return LoginResult(
      success: true,
      message: 'Welcome, ${profile.name}!',
      user: profile,
    );
  }

  String _friendlyAuthError(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'Account is deactivated. Contact your manager.';
      case 'too-many-requests':
        return 'Too many failed attempts. Try again later or use "Forgot Password".';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return e.message ?? 'Authentication error (${e.code}).';
    }
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
