import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Utility class for password hashing using SHA-256.
/// Provides hashing, verification, and migration support.
class PasswordHash {
  /// Hash a plaintext password using SHA-256.
  /// Returns a 64-character lowercase hex string.
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify a plaintext password against a stored hash.
  /// Supports both hashed and legacy plaintext passwords for migration.
  static bool verifyPassword(String password, String storedPassword) {
    if (isHashed(storedPassword)) {
      // Stored password is already hashed — compare hashes
      return hashPassword(password) == storedPassword;
    } else {
      // Legacy plaintext password — direct comparison
      return password == storedPassword;
    }
  }

  /// Check if a value looks like a SHA-256 hash (64-char hex string).
  /// Used to detect whether a password has already been hashed
  /// for migration from plaintext to hashed passwords.
  static bool isHashed(String value) {
    if (value.length != 64) return false;
    return RegExp(r'^[0-9a-f]{64}$').hasMatch(value);
  }
}
