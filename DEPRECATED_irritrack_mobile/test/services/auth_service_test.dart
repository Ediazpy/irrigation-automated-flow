import 'package:flutter_test/flutter_test.dart';
import 'package:irritrack_mobile/services/auth_service.dart';
import 'package:irritrack_mobile/services/storage_service.dart';
import 'package:irritrack_mobile/models/user.dart';

void main() {
  group('AuthService', () {
    late StorageService storage;
    late AuthService authService;

    setUp(() {
      storage = StorageService();
      authService = AuthService(storage);
    });

    tearDown(() {
      // Reset storage state to prevent test pollution
      storage.users.clear();
      storage.failedAttempts.clear();
      storage.properties.clear();
      storage.inspections.clear();
      // Re-initialize defaults for next test
      storage = StorageService();
    });

    group('Login', () {
      test('should successfully login with correct credentials', () async {
        // Arrange
        final email = 'admin@thriveoutdoor.com';
        final password = 'temp1234';

        // Act
        final result = await authService.login(email, password);

        // Assert
        expect(result.success, true);
        expect(result.user, isNotNull);
        expect(result.user!.email, email);
        expect(result.user!.role, 'manager');
        expect(result.message, 'Welcome, Admin!');
        expect(authService.currentUser, isNotNull);
        expect(authService.isLoggedIn, true);
      });

      test('should fail login with incorrect password', () async {
        // Arrange
        final email = 'admin@thriveoutdoor.com';
        final password = 'wrongpassword';

        // Act
        final result = await authService.login(email, password);

        // Assert
        expect(result.success, false);
        expect(result.user, isNull);
        expect(result.message, contains('Incorrect password'));
        expect(result.message, contains('Attempts remaining: 2'));
        expect(authService.currentUser, isNull);
        expect(authService.isLoggedIn, false);
      });

      test('should fail login with non-existent email', () async {
        // Arrange
        final email = 'nonexistent@example.com';
        final password = 'anypassword';

        // Act
        final result = await authService.login(email, password);

        // Assert
        expect(result.success, false);
        expect(result.user, isNull);
        expect(result.message, contains('Email not found'));
        expect(result.message, contains('Attempts remaining: 2'));
        expect(authService.currentUser, isNull);
      });

      test('should handle empty credentials', () async {
        // Arrange
        final email = '';
        final password = '';

        // Act
        final result = await authService.login(email, password);

        // Assert
        expect(result.success, false);
        expect(result.user, isNull);
      });
    });

    group('Account Lockout', () {
      test('should lock account after 3 failed attempts', () async {
        // Arrange
        final email = 'admin@thriveoutdoor.com';
        final wrongPassword = 'wrongpassword';

        // Act - Make 3 failed login attempts
        await authService.login(email, wrongPassword);
        await authService.login(email, wrongPassword);
        await authService.login(email, wrongPassword);

        // Assert - Account should now be locked
        expect(authService.isAccountLocked(email), true);
        expect(authService.getRemainingAttempts(email), 0);
      });

      test('should prevent login when account is locked', () async {
        // Arrange
        final email = 'admin@thriveoutdoor.com';
        final correctPassword = 'temp1234';
        final wrongPassword = 'wrongpassword';

        // Lock the account with 3 failed attempts
        await authService.login(email, wrongPassword);
        await authService.login(email, wrongPassword);
        await authService.login(email, wrongPassword);

        // Act - Try to login with correct password
        final result = await authService.login(email, correctPassword);

        // Assert
        expect(result.success, false);
        expect(result.message, contains('Account locked'));
        expect(result.message, contains('contact your manager'));
        expect(authService.currentUser, isNull);
      });

      test('should track remaining attempts correctly', () async {
        // Arrange
        final email = 'admin@thriveoutdoor.com';
        final wrongPassword = 'wrongpassword';

        // Assert initial state
        expect(authService.getRemainingAttempts(email), 3);

        // Act & Assert - First failed attempt
        await authService.login(email, wrongPassword);
        expect(authService.getRemainingAttempts(email), 2);

        // Act & Assert - Second failed attempt
        await authService.login(email, wrongPassword);
        expect(authService.getRemainingAttempts(email), 1);

        // Act & Assert - Third failed attempt
        await authService.login(email, wrongPassword);
        expect(authService.getRemainingAttempts(email), 0);
        expect(authService.isAccountLocked(email), true);
      });

      test('should reset failed attempts after successful login', () async {
        // Arrange
        final email = 'admin@thriveoutdoor.com';
        final correctPassword = 'temp1234';
        final wrongPassword = 'wrongpassword';

        // Make 2 failed attempts
        await authService.login(email, wrongPassword);
        await authService.login(email, wrongPassword);
        expect(authService.getRemainingAttempts(email), 1);

        // Act - Login successfully
        await authService.login(email, correctPassword);

        // Assert - Failed attempts should be reset
        expect(authService.getRemainingAttempts(email), 3);
        expect(storage.failedAttempts[email], 0);
      });

      test('should allow manual reset of failed attempts', () async {
        // Arrange
        final email = 'admin@thriveoutdoor.com';
        final wrongPassword = 'wrongpassword';

        // Lock the account
        await authService.login(email, wrongPassword);
        await authService.login(email, wrongPassword);
        await authService.login(email, wrongPassword);
        expect(authService.isAccountLocked(email), true);

        // Act - Manager resets the account
        authService.resetFailedAttempts(email);

        // Assert
        expect(authService.isAccountLocked(email), false);
        expect(authService.getRemainingAttempts(email), 3);
      });

      test('should track failed attempts separately per email', () async {
        // Arrange
        final email1 = 'admin@thriveoutdoor.com';
        final email2 = 'tech@example.com';
        final wrongPassword = 'wrongpassword';

        // Add second user
        storage.users[email2] = User(
          email: email2,
          password: 'correct123',
          role: 'technician',
          name: 'Tech User',
        );

        // Act - Fail login for email1 twice
        await authService.login(email1, wrongPassword);
        await authService.login(email1, wrongPassword);

        // Assert - Each email has independent attempt tracking
        expect(authService.getRemainingAttempts(email1), 1);
        expect(authService.getRemainingAttempts(email2), 3);
        expect(authService.isAccountLocked(email1), false);
        expect(authService.isAccountLocked(email2), false);
      });
    });

    group('Logout', () {
      test('should logout user successfully', () async {
        // Arrange - Login first
        await authService.login('admin@thriveoutdoor.com', 'temp1234');
        expect(authService.isLoggedIn, true);

        // Act
        authService.logout();

        // Assert
        expect(authService.currentUser, isNull);
        expect(authService.isLoggedIn, false);
      });

      test('should handle logout when not logged in', () {
        // Arrange
        expect(authService.isLoggedIn, false);

        // Act
        authService.logout();

        // Assert
        expect(authService.currentUser, isNull);
        expect(authService.isLoggedIn, false);
      });
    });

    group('Role Checking', () {
      test('should correctly identify manager role', () async {
        // Arrange & Act
        await authService.login('admin@thriveoutdoor.com', 'temp1234');

        // Assert
        expect(authService.isManager, true);
        expect(authService.isTechnician, false);
      });

      test('should correctly identify technician role', () async {
        // Arrange - Add technician user
        final techEmail = 'tech@example.com';
        storage.users[techEmail] = User(
          email: techEmail,
          password: 'tech123',
          role: 'technician',
          name: 'Tech User',
        );

        // Act
        await authService.login(techEmail, 'tech123');

        // Assert
        expect(authService.isManager, false);
        expect(authService.isTechnician, true);
      });

      test('should return false for role checks when not logged in', () {
        // Assert
        expect(authService.isLoggedIn, false);
        expect(authService.isManager, false);
        expect(authService.isTechnician, false);
      });
    });

    group('Failed Attempt Management', () {
      test('should add failed attempt correctly', () {
        // Arrange
        final email = 'test@example.com';
        expect(storage.failedAttempts[email], isNull);

        // Act
        authService.addFailedAttempt(email);

        // Assert
        expect(storage.failedAttempts[email], 1);

        // Act again
        authService.addFailedAttempt(email);

        // Assert
        expect(storage.failedAttempts[email], 2);
      });

      test('should check account lock status correctly', () {
        // Arrange
        final email = 'test@example.com';
        storage.failedAttempts[email] = 2;

        // Assert - Not locked yet
        expect(authService.isAccountLocked(email), false);

        // Act - Add one more attempt to reach 3
        storage.failedAttempts[email] = 3;

        // Assert - Now locked
        expect(authService.isAccountLocked(email), true);
      });
    });

    group('Storage Integration', () {
      test('should have access to storage service', () {
        // Assert
        expect(authService.storage, same(storage));
      });

      test('should persist failed attempts to storage', () async {
        // Arrange
        final email = 'admin@thriveoutdoor.com';
        final wrongPassword = 'wrongpassword';

        // Act
        await authService.login(email, wrongPassword);

        // Assert - Failed attempts should be in storage
        expect(storage.failedAttempts[email], 1);
      });
    });

    group('Edge Cases', () {
      test('should handle case-sensitive emails', () async {
        // Arrange
        final lowerEmail = 'admin@thriveoutdoor.com';
        final upperEmail = 'ADMIN@thriveoutdoor.com';

        // Act
        final result = await authService.login(upperEmail, 'temp1234');

        // Assert - Email is case-sensitive, so this should fail
        expect(result.success, false);
      });

      test('should handle special characters in password', () async {
        // Arrange
        final email = 'special@example.com';
        final complexPassword = 'P@ssw0rd!#$%^&*()';
        storage.users[email] = User(
          email: email,
          password: complexPassword,
          role: 'manager',
          name: 'Special User',
        );

        // Act
        final result = await authService.login(email, complexPassword);

        // Assert
        expect(result.success, true);
      });

      test('should handle whitespace in credentials', () async {
        // Arrange
        final email = ' admin@thriveoutdoor.com ';
        final password = ' temp1234 ';

        // Act
        final result = await authService.login(email, password);

        // Assert - Should fail due to whitespace (not trimmed)
        expect(result.success, false);
      });
    });

    group('Additional Edge Cases', () {
      test('should handle null email gracefully', () async {
        // Arrange
        final email = '';
        final password = 'temp1234';

        // Act
        final result = await authService.login(email, password);

        // Assert
        expect(result.success, false);
        expect(authService.isLoggedIn, false);
      });

      test('should handle null password gracefully', () async {
        // Arrange
        final email = 'admin@thriveoutdoor.com';
        final password = '';

        // Act
        final result = await authService.login(email, password);

        // Assert
        expect(result.success, false);
        expect(authService.isLoggedIn, false);
      });

      test('should handle extremely long email', () async {
        // Arrange
        final email = 'a' * 1000 + '@example.com';
        final password = 'password';

        // Act
        final result = await authService.login(email, password);

        // Assert
        expect(result.success, false);
      });

      test('should handle extremely long password', () async {
        // Arrange
        final email = 'admin@thriveoutdoor.com';
        final password = 'a' * 10000;

        // Act
        final result = await authService.login(email, password);

        // Assert
        expect(result.success, false);
      });

      test('should handle SQL injection attempt in email', () async {
        // Arrange
        final email = "admin@thriveoutdoor.com'; DROP TABLE users; --";
        final password = 'temp1234';

        // Act
        final result = await authService.login(email, password);

        // Assert
        expect(result.success, false);
        // Verify users map is still intact
        expect(storage.users.isNotEmpty, true);
      });

      test('should handle SQL injection attempt in password', () async {
        // Arrange
        final email = 'admin@thriveoutdoor.com';
        final password = "' OR '1'='1";

        // Act
        final result = await authService.login(email, password);

        // Assert
        expect(result.success, false);
      });

      test('should handle unicode characters in email', () async {
        // Arrange
        final email = 'tëst@éxample.com';
        final password = 'password';

        // Act
        final result = await authService.login(email, password);

        // Assert
        expect(result.success, false); // User doesn't exist
      });

      test('should handle unicode characters in password', () async {
        // Arrange
        final email = 'unicode@example.com';
        final password = 'pássw0rd™';
        storage.users[email] = User(
          email: email,
          password: password,
          role: 'manager',
          name: 'Unicode User',
        );

        // Act
        final result = await authService.login(email, password);

        // Assert
        expect(result.success, true);
      });

      test('should handle emoji in credentials', () async {
        // Arrange
        final email = 'emoji@example.com';
        final password = 'password😀🔒';
        storage.users[email] = User(
          email: email,
          password: password,
          role: 'manager',
          name: 'Emoji User',
        );

        // Act
        final result = await authService.login(email, password);

        // Assert
        expect(result.success, true);
      });

      test('should handle newline characters in credentials', () async {
        // Arrange
        final email = 'admin@thriveoutdoor.com\n';
        final password = 'temp1234\n';

        // Act
        final result = await authService.login(email, password);

        // Assert
        expect(result.success, false);
      });

      test('should handle tab characters in credentials', () async {
        // Arrange
        final email = 'admin@thriveoutdoor.com\t';
        final password = 'temp1234\t';

        // Act
        final result = await authService.login(email, password);

        // Assert
        expect(result.success, false);
      });

      test('should prevent concurrent login attempts from interfering', () async {
        // Arrange
        final email1 = 'admin@thriveoutdoor.com';
        final email2 = 'tech@example.com';
        storage.users[email2] = User(
          email: email2,
          password: 'tech123',
          role: 'technician',
          name: 'Tech',
        );

        // Act - Login with different users concurrently
        final result1Future = authService.login(email1, 'temp1234');
        final result2Future = authService.login(email2, 'tech123');

        final results = await Future.wait([result1Future, result2Future]);

        // Assert - At least one should succeed (last one wins)
        expect(results.any((r) => r.success), true);
        expect(authService.isLoggedIn, true);
      });

      test('should handle rapid failed login attempts', () async {
        // Arrange
        final email = 'admin@thriveoutdoor.com';
        final wrongPassword = 'wrongpassword';

        // Act - Make rapid failed attempts
        final futures = List.generate(
          5,
          (i) => authService.login(email, wrongPassword),
        );
        await Future.wait(futures);

        // Assert - Account should be locked
        expect(authService.isAccountLocked(email), true);
      });

      test('should maintain failed attempts state after logout', () async {
        // Arrange
        final email = 'admin@thriveoutdoor.com';

        // Make 2 failed attempts
        await authService.login(email, 'wrong1');
        await authService.login(email, 'wrong2');
        expect(authService.getRemainingAttempts(email), 1);

        // Login successfully and logout
        await authService.login(email, 'temp1234');
        authService.logout();

        // Act - Failed attempts should be reset after successful login
        // Assert
        expect(authService.getRemainingAttempts(email), 3);
      });

      test('should handle multiple users with different failed attempt counts', () async {
        // Arrange
        final email1 = 'admin@thriveoutdoor.com';
        final email2 = 'tech@example.com';
        final email3 = 'manager@example.com';

        storage.users[email2] = User(email: email2, password: 'tech123', role: 'technician', name: 'Tech');
        storage.users[email3] = User(email: email3, password: 'mgr123', role: 'manager', name: 'Manager');

        // Act - Different fail counts for each user
        await authService.login(email1, 'wrong');
        await authService.login(email2, 'wrong');
        await authService.login(email2, 'wrong');
        await authService.login(email3, 'wrong');
        await authService.login(email3, 'wrong');
        await authService.login(email3, 'wrong');

        // Assert - Each user has independent tracking
        expect(authService.getRemainingAttempts(email1), 2);
        expect(authService.getRemainingAttempts(email2), 1);
        expect(authService.getRemainingAttempts(email3), 0);
        expect(authService.isAccountLocked(email1), false);
        expect(authService.isAccountLocked(email2), false);
        expect(authService.isAccountLocked(email3), true);
      });
    });

    group('Password Security', () {
      test('should treat passwords as case-sensitive', () async {
        // Arrange
        final email = 'admin@thriveoutdoor.com';
        final password = 'TEMP1234'; // Uppercase

        // Act
        final result = await authService.login(email, password);

        // Assert
        expect(result.success, false);
      });

      test('should not expose password in error messages', () async {
        // Arrange
        final email = 'admin@thriveoutdoor.com';
        final wrongPassword = 'wrongpassword';

        // Act
        final result = await authService.login(email, wrongPassword);

        // Assert
        expect(result.message, isNot(contains(wrongPassword)));
        expect(result.message, isNot(contains('temp1234'))); // Real password
      });

      test('should handle empty string password differently from null', () async {
        // Arrange
        final email = 'empty@example.com';
        storage.users[email] = User(
          email: email,
          password: '',
          role: 'technician',
          name: 'Empty Password User',
        );

        // Act
        final result = await authService.login(email, '');

        // Assert
        expect(result.success, false); // Empty passwords should fail validation
      });
    });

    group('State Management', () {
      test('should clear current user on logout', () async {
        // Arrange
        await authService.login('admin@thriveoutdoor.com', 'temp1234');
        final userBeforeLogout = authService.currentUser;
        expect(userBeforeLogout, isNotNull);

        // Act
        authService.logout();

        // Assert
        expect(authService.currentUser, isNull);
        expect(authService.isLoggedIn, false);
      });

      test('should maintain role getters after login', () async {
        // Arrange & Act
        await authService.login('admin@thriveoutdoor.com', 'temp1234');

        // Assert
        expect(authService.isManager, true);
        expect(authService.isTechnician, false);
        expect(authService.currentUser!.role, 'manager');
      });

      test('should reset role getters after logout', () async {
        // Arrange
        await authService.login('admin@thriveoutdoor.com', 'temp1234');
        expect(authService.isManager, true);

        // Act
        authService.logout();

        // Assert
        expect(authService.isManager, false);
        expect(authService.isTechnician, false);
      });

      test('should update current user on successful login', () async {
        // Arrange
        final email = 'admin@thriveoutdoor.com';

        // Act
        final result = await authService.login(email, 'temp1234');

        // Assert
        expect(result.success, true);
        expect(authService.currentUser, isNotNull);
        expect(authService.currentUser!.email, email);
      });
    });
  });
}
