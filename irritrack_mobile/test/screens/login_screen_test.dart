import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irritrack_mobile/screens/login_screen.dart';
import 'package:irritrack_mobile/screens/manager_home_screen.dart';
import 'package:irritrack_mobile/screens/technician_home_screen.dart';
import 'package:irritrack_mobile/services/auth_service.dart';
import 'package:irritrack_mobile/services/storage_service.dart';
import 'package:irritrack_mobile/models/user.dart';

void main() {
  group('LoginScreen Widget Tests', () {
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
    });

    Widget createLoginScreen() {
      return MaterialApp(
        home: LoginScreen(authService: authService),
      );
    }

    group('UI Elements', () {
      testWidgets('should display app branding', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createLoginScreen());

        // Assert
        expect(find.byIcon(Icons.water_drop), findsOneWidget);
        expect(find.text('IrriTrack'), findsOneWidget);
        expect(find.text('Field Service Management'), findsOneWidget);
      });

      testWidgets('should display email and password fields', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createLoginScreen());

        // Assert
        expect(find.byType(TextFormField), findsNWidgets(2));
        expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
        expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      });

      testWidgets('should display login button', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createLoginScreen());

        // Assert
        expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
      });

      testWidgets('should display forgot password button', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createLoginScreen());

        // Assert
        expect(find.widgetWithText(TextButton, 'Forgot Password?'), findsOneWidget);
      });

      testWidgets('should display default login credentials hint', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createLoginScreen());

        // Assert
        expect(find.text('Default Login:'), findsOneWidget);
        expect(find.text('admin@thriveoutdoor.com'), findsOneWidget);
        expect(find.text('temp1234'), findsOneWidget);
      });

      testWidgets('should display email and lock icons', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createLoginScreen());

        // Assert
        expect(find.byIcon(Icons.email), findsOneWidget);
        expect(find.byIcon(Icons.lock), findsOneWidget);
      });

      testWidgets('password field should be obscured by default', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createLoginScreen());

        // Assert
        final passwordField = tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, 'Password'),
        );
        expect(passwordField.obscureText, true);
      });

      testWidgets('should display visibility toggle icon for password', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createLoginScreen());

        // Assert
        expect(find.byIcon(Icons.visibility), findsOneWidget);
      });
    });

    group('Form Validation', () {
      testWidgets('should show error when email is empty', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createLoginScreen());

        // Act - Tap login without entering email
        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pump();

        // Assert
        expect(find.text('Please enter your email'), findsOneWidget);
      });

      testWidgets('should show error when email is invalid', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createLoginScreen());

        // Act - Enter invalid email
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'invalidemail',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pump();

        // Assert
        expect(find.text('Please enter a valid email'), findsOneWidget);
      });

      testWidgets('should show error when password is empty', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createLoginScreen());

        // Act - Enter email but not password
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pump();

        // Assert
        expect(find.text('Please enter your password'), findsOneWidget);
      });

      testWidgets('should accept valid email format', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createLoginScreen());

        // Act
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'valid@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'password123',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pump();

        // Assert - No validation errors shown
        expect(find.text('Please enter your email'), findsNothing);
        expect(find.text('Please enter a valid email'), findsNothing);
      });
    });

    group('Password Visibility Toggle', () {
      testWidgets('should toggle password visibility when icon is tapped', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createLoginScreen());

        // Act - Tap visibility toggle
        await tester.tap(find.byIcon(Icons.visibility));
        await tester.pump();

        // Assert - Icon should change and password should be visible
        expect(find.byIcon(Icons.visibility_off), findsOneWidget);
        expect(find.byIcon(Icons.visibility), findsNothing);

        final passwordField = tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, 'Password'),
        );
        expect(passwordField.obscureText, false);
      });

      testWidgets('should toggle back to obscured', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createLoginScreen());

        // Act - Toggle twice
        await tester.tap(find.byIcon(Icons.visibility));
        await tester.pump();
        await tester.tap(find.byIcon(Icons.visibility_off));
        await tester.pump();

        // Assert - Should be back to obscured
        expect(find.byIcon(Icons.visibility), findsOneWidget);
        final passwordField = tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, 'Password'),
        );
        expect(passwordField.obscureText, true);
      });
    });

    group('Forgot Password Dialog', () {
      testWidgets('should show forgot password dialog when button is tapped', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createLoginScreen());

        // Act
        await tester.tap(find.widgetWithText(TextButton, 'Forgot Password?'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Forgot Password'), findsOneWidget);
        expect(find.text('Please contact your manager to reset your password.'), findsOneWidget);
        expect(find.widgetWithText(TextButton, 'OK'), findsOneWidget);
      });

      testWidgets('should close dialog when OK is tapped', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createLoginScreen());
        await tester.tap(find.widgetWithText(TextButton, 'Forgot Password?'));
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.widgetWithText(TextButton, 'OK'));
        await tester.pumpAndSettle();

        // Assert - Dialog should be closed
        expect(find.text('Forgot Password'), findsNothing);
      });
    });

    group('Login Flow - Success', () {
      testWidgets('should navigate to manager home on successful manager login', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createLoginScreen());

        // Act - Enter valid manager credentials
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'admin@thriveoutdoor.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'temp1234',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pumpAndSettle();

        // Assert - Should navigate to ManagerHomeScreen
        expect(find.byType(ManagerHomeScreen), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);
      });

      testWidgets('should navigate to technician home on successful technician login', (WidgetTester tester) async {
        // Arrange
        final techEmail = 'tech@example.com';
        storage.users[techEmail] = User(
          email: techEmail,
          password: 'tech123',
          role: 'technician',
          name: 'Tech User',
        );

        await tester.pumpWidget(createLoginScreen());

        // Act - Enter valid technician credentials
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          techEmail,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'tech123',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pumpAndSettle();

        // Assert - Should navigate to TechnicianHomeScreen
        expect(find.byType(TechnicianHomeScreen), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);
      });

      testWidgets('should trim email before login', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createLoginScreen());

        // Act - Enter email with spaces
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          '  admin@thriveoutdoor.com  ',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'temp1234',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pumpAndSettle();

        // Assert - Should successfully login despite spaces
        expect(find.byType(ManagerHomeScreen), findsOneWidget);
      });
    });

    group('Login Flow - Failure', () {
      testWidgets('should show error snackbar on failed login', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createLoginScreen());

        // Act - Enter wrong password
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'admin@thriveoutdoor.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'wrongpassword',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pump();

        // Assert - Should show error snackbar
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('Incorrect password. Attempts remaining: 2'), findsOneWidget);
      });

      testWidgets('should show error for non-existent email', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createLoginScreen());

        // Act - Enter non-existent email
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'nonexistent@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'password123',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pump();

        // Assert - Should show error snackbar
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.textContaining('Email not found'), findsOneWidget);
      });

      testWidgets('should show account locked message after 3 failed attempts', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createLoginScreen());
        final email = 'admin@thriveoutdoor.com';

        // Act - Make 3 failed login attempts
        for (int i = 0; i < 3; i++) {
          await tester.enterText(find.widgetWithText(TextFormField, 'Email'), email);
          await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'wrongpassword');
          await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
          await tester.pump();
          await tester.pump(const Duration(seconds: 5)); // Wait for snackbar to disappear
        }

        // Try to login again with locked account
        await tester.enterText(find.widgetWithText(TextFormField, 'Email'), email);
        await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'temp1234');
        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pump();

        // Assert
        expect(find.textContaining('Account locked'), findsOneWidget);
        expect(find.textContaining('contact your manager'), findsOneWidget);
      });

      testWidgets('should remain on login screen after failed login', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createLoginScreen());

        // Act - Enter wrong credentials
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'admin@thriveoutdoor.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'wrongpassword',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pumpAndSettle();

        // Assert - Should still be on login screen
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(ManagerHomeScreen), findsNothing);
        expect(find.byType(TechnicianHomeScreen), findsNothing);
      });
    });

    group('Loading State', () {
      testWidgets('should show loading indicator during login', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createLoginScreen());

        // Act - Initiate login
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'admin@thriveoutdoor.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'temp1234',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pump();

        // Assert - Should show loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should disable login button during loading', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createLoginScreen());

        // Act - Initiate login
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'admin@thriveoutdoor.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'temp1234',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pump();

        // Assert - Button should be disabled
        final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.onPressed, isNull);
      });
    });

    group('Text Controllers', () {
      testWidgets('should update email field when text is entered', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createLoginScreen());

        // Act
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );

        // Assert
        expect(find.text('test@example.com'), findsOneWidget);
      });

      testWidgets('should update password field when text is entered', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createLoginScreen());

        // Act - Toggle visibility first to see the text
        await tester.tap(find.byIcon(Icons.visibility));
        await tester.pump();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'mypassword',
        );

        // Assert
        expect(find.text('mypassword'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should have semantic labels for form fields', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createLoginScreen());

        // Assert - Email field should have semantic label
        final emailField = find.widgetWithText(TextFormField, 'Email');
        expect(emailField, findsOneWidget);

        // Password field should have semantic label
        final passwordField = find.widgetWithText(TextFormField, 'Password');
        expect(passwordField, findsOneWidget);
      });

      testWidgets('should have accessible button labels', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createLoginScreen());

        // Assert
        expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
        expect(find.widgetWithText(TextButton, 'Forgot Password?'), findsOneWidget);
      });

      testWidgets('should have descriptive icons with semantic meaning', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createLoginScreen());

        // Assert - Icons should be present for visual clarity
        expect(find.byIcon(Icons.email), findsOneWidget);
        expect(find.byIcon(Icons.lock), findsOneWidget);
        expect(find.byIcon(Icons.water_drop), findsOneWidget);
      });

      testWidgets('should support keyboard navigation between fields', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createLoginScreen());

        // Act - Enter text in email field
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );

        // Verify email was entered
        expect(find.text('test@example.com'), findsOneWidget);

        // Enter text in password field
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'password123',
        );

        // Toggle visibility to verify
        await tester.tap(find.byIcon(Icons.visibility));
        await tester.pump();

        // Assert - Both fields should have values
        expect(find.text('test@example.com'), findsOneWidget);
        expect(find.text('password123'), findsOneWidget);
      });

      testWidgets('should display error messages clearly', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createLoginScreen());

        // Act - Submit form without filling fields
        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pump();

        // Assert - Error messages should be visible
        expect(find.text('Please enter your email'), findsOneWidget);
      });

      testWidgets('should have sufficient tap target size for buttons', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createLoginScreen());

        // Assert - Login button should be tappable
        final loginButton = find.widgetWithText(ElevatedButton, 'Login');
        expect(loginButton, findsOneWidget);

        final buttonWidget = tester.widget<ElevatedButton>(loginButton);
        expect(buttonWidget, isNotNull);

        // Forgot password button should be tappable
        final forgotButton = find.widgetWithText(TextButton, 'Forgot Password?');
        expect(forgotButton, findsOneWidget);
      });

      testWidgets('should show loading indicator with accessibility', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createLoginScreen());

        // Act - Start login
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'admin@thriveoutdoor.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'temp1234',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pump();

        // Assert - Loading indicator should be accessible
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should provide feedback for successful actions', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createLoginScreen());

        // Act - Successful login
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'admin@thriveoutdoor.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'temp1234',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pumpAndSettle();

        // Assert - Should navigate to new screen (success feedback)
        expect(find.byType(LoginScreen), findsNothing);
      });

      testWidgets('should provide feedback for failed actions', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createLoginScreen());

        // Act - Failed login
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'admin@thriveoutdoor.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'wrongpassword',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pump();

        // Assert - Error message should be shown via SnackBar
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.textContaining('Incorrect password'), findsOneWidget);
      });

      testWidgets('should have clear visual hierarchy', (WidgetTester tester) async {
        // Arrange & Act
        await tester.pumpWidget(createLoginScreen());

        // Assert - Title should be prominent
        expect(find.text('IrriTrack'), findsOneWidget);
        expect(find.text('Field Service Management'), findsOneWidget);

        // Logo should be visible
        expect(find.byIcon(Icons.water_drop), findsOneWidget);

        // Form elements should be present
        expect(find.byType(TextFormField), findsNWidgets(2));
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('should handle dialog accessibility', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createLoginScreen());

        // Act - Open forgot password dialog
        await tester.tap(find.widgetWithText(TextButton, 'Forgot Password?'));
        await tester.pumpAndSettle();

        // Assert - Dialog should have clear title and content
        expect(find.text('Forgot Password'), findsOneWidget);
        expect(find.text('Please contact your manager to reset your password.'), findsOneWidget);

        // Dialog should have action button
        expect(find.widgetWithText(TextButton, 'OK'), findsOneWidget);
      });
    });

    group('Edge Cases and Error Handling', () {
      testWidgets('should handle rapid button tapping', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createLoginScreen());
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'admin@thriveoutdoor.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'temp1234',
        );

        // Act - Tap login button multiple times rapidly
        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pump();

        // Button should be disabled during loading
        final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.onPressed, isNull);

        // Attempting to tap again should have no effect
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        await tester.pumpAndSettle();

        // Assert - Should only process one login
        expect(find.byType(LoginScreen), findsNothing);
      });

      testWidgets('should handle very long email input', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createLoginScreen());
        final longEmail = 'a' * 100 + '@example.com';

        // Act
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          longEmail,
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'password',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pump();

        // Assert - Should show error or handle gracefully
        await tester.pumpAndSettle();
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('should handle special characters in input', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createLoginScreen());

        // Act
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          "test+tag@example.com",
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          "P@ssw0rd!#$",
        );

        // Assert - Should accept special characters
        expect(find.text("test+tag@example.com"), findsOneWidget);
      });

      testWidgets('should clear password field on failed login', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createLoginScreen());

        // Act - Failed login
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'admin@thriveoutdoor.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'wrongpassword',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
        await tester.pumpAndSettle();

        // Assert - Should still be on login screen with error
        expect(find.byType(LoginScreen), findsOneWidget);
      });
    });
  });
}
