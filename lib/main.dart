import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/manager_home_screen.dart';
import 'screens/technician_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable Firestore offline persistence for field use (bad signal areas)
  // Mobile has persistence enabled by default, but we set cache size explicitly
  // Web needs persistence enabled manually
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<AuthService> _authServiceFuture;

  @override
  void initState() {
    super.initState();
    _authServiceFuture = _initializeApp();
  }

  Future<AuthService> _initializeApp() async {
    print('Initializing IAF App...');

    // Initialize storage
    final storage = StorageService();

    try {
      print('Loading data...');
      await storage.loadData();
      print('Data loaded successfully');

      // If local data is empty but Firestore sync is enabled,
      // try to download from cloud (handles web<->mobile sync)
      if (storage.users.isEmpty && storage.firestoreSyncEnabled) {
        print('Local data empty, attempting cloud download...');
        final downloaded = await storage.downloadFromFirestore();
        if (downloaded) {
          print('Cloud data downloaded successfully');
        } else {
          print('No cloud data available or download failed');
        }
      }
    } catch (e) {
      print('Error loading data (using defaults): $e');
    }

    // Initialize auth service
    final authService = AuthService(storage);

    // Try to restore previous session
    await authService.restoreSession();
    print('Auth service initialized (session restored: ${authService.isLoggedIn})');

    return authService;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthService>(
      future: _authServiceFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('Error: ${snapshot.error}'),
              ),
            ),
          );
        }

        final authService = snapshot.data!;
        return IrriTrackApp(authService: authService);
      },
    );
  }
}

class IrriTrackApp extends StatelessWidget {
  final AuthService authService;

  const IrriTrackApp({Key? key, required this.authService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Irrigation Automated Flow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
      home: authService.storage.users.isEmpty
          ? SetupScreen(authService: authService)
          : authService.isLoggedIn
              ? (authService.isManager
                  ? ManagerHomeScreen(authService: authService)
                  : TechnicianHomeScreen(authService: authService))
              : LoginScreen(authService: authService),
    );
  }
}
