import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irritrack_mobile/main.dart';
import 'package:irritrack_mobile/screens/login_screen.dart';
import 'package:irritrack_mobile/screens/manager_home_screen.dart';
import 'package:irritrack_mobile/screens/technician_home_screen.dart';
import 'package:irritrack_mobile/services/auth_service.dart';
import 'package:irritrack_mobile/services/storage_service.dart';
import 'package:irritrack_mobile/models/user.dart';

void main() {
  group('IrriTrack App Integration Tests', () {
    testWidgets('app initializes and shows login screen', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const MyApp());

      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for initialization
      await tester.pumpAndSettle();

      // Should show login screen after initialization
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('IrriTrack'), findsOneWidget);
      expect(find.text('Field Service Management'), findsOneWidget);
    });

    testWidgets('complete manager login flow', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Verify we're on login screen
      expect(find.byType(LoginScreen), findsOneWidget);

      // Enter manager credentials
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'admin@thriveoutdoor.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'temp1234',
      );

      // Tap login button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      // Should navigate to manager home screen
      expect(find.byType(ManagerHomeScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);

      // Verify manager home screen content
      expect(find.text('Manager Dashboard'), findsOneWidget);
    });

    testWidgets('complete technician login flow', (WidgetTester tester) async {
      // Create a technician user for testing
      final storage = StorageService();
      storage.users['tech@test.com'] = User(
        email: 'tech@test.com',
        password: 'tech123',
        role: 'technician',
        name: 'Test Technician',
      );
      final authService = AuthService(storage);

      // Build app with our test auth service
      await tester.pumpWidget(IrriTrackApp(authService: authService));

      // Verify we're on login screen
      expect(find.byType(LoginScreen), findsOneWidget);

      // Enter technician credentials
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'tech@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'tech123',
      );

      // Tap login button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      // Should navigate to technician home screen
      expect(find.byType(TechnicianHomeScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);

      // Verify technician home screen content
      expect(find.text('Technician Dashboard'), findsOneWidget);
    });

    testWidgets('failed login shows error and stays on login screen', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Enter incorrect credentials
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'admin@thriveoutdoor.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'wrongpassword',
      );

      // Tap login button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();

      // Should show error message
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Incorrect password'), findsOneWidget);

      // Should still be on login screen
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(ManagerHomeScreen), findsNothing);
    });

    testWidgets('app theme is properly configured', (WidgetTester tester) async {
      final storage = StorageService();
      final authService = AuthService(storage);

      await tester.pumpWidget(IrriTrackApp(authService: authService));

      // Get the MaterialApp
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

      // Verify theme configuration
      expect(materialApp.title, 'IrriTrack');
      expect(materialApp.debugShowCheckedModeBanner, false);
      expect(materialApp.theme, isNotNull);
      expect(materialApp.theme!.useMaterial3, true);
    });

    testWidgets('login screen validates empty email', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Leave email empty, enter password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );

      // Tap login button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();

      // Should show validation error
      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('login screen validates invalid email format', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Enter invalid email format
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'notanemail',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );

      // Tap login button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();

      // Should show validation error
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('login screen validates empty password', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Enter email but leave password empty
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );

      // Tap login button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();

      // Should show validation error
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('password visibility toggle works', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Password should be obscured initially
      final passwordFieldBefore = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Password'),
      );
      expect(passwordFieldBefore.obscureText, true);
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      // Tap visibility toggle
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      // Password should now be visible
      final passwordFieldAfter = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Password'),
      );
      expect(passwordFieldAfter.obscureText, false);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('forgot password dialog works', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Tap forgot password button
      await tester.tap(find.widgetWithText(TextButton, 'Forgot Password?'));
      await tester.pumpAndSettle();

      // Dialog should be shown
      expect(find.text('Forgot Password'), findsOneWidget);
      expect(find.text('Please contact your manager to reset your password.'), findsOneWidget);

      // Close dialog
      await tester.tap(find.widgetWithText(TextButton, 'OK'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.text('Forgot Password'), findsNothing);
    });
  });
}
