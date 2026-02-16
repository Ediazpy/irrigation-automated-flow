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
import 'screens/client/client_quote_screen.dart';

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

      print('Local users loaded: ${storage.users.length}');

      // Always sync from Firestore on startup when enabled,
      // so new users/data created on other devices are available
      if (storage.firestoreSyncEnabled) {
        print('Syncing from cloud...');
        final downloaded = await storage.downloadFromFirestore();
        print(downloaded
            ? 'Cloud sync complete (${storage.users.length} users)'
            : 'Cloud sync failed or no data');
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

  Widget _getHomeScreen(AuthService authService) {
    // Check if web URL has a quote token (e.g. /quote?token=ABC)
    if (kIsWeb) {
      final uri = Uri.base;
      if (uri.path.contains('/quote') && uri.queryParameters.containsKey('token')) {
        final token = uri.queryParameters['token']!;
        return ClientQuoteScreen(
          storage: authService.storage,
          accessToken: token,
        );
      }
    }

    // Normal app flow
    if (authService.storage.users.isEmpty) {
      return SetupScreen(authService: authService);
    }
    if (authService.isLoggedIn) {
      return authService.isManager
          ? ManagerHomeScreen(authService: authService)
          : TechnicianHomeScreen(authService: authService);
    }
    return LoginScreen(authService: authService);
  }

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
      onGenerateRoute: (settings) {
        // Handle /quote?token=XYZ for customer quote approval (no login needed)
        final uri = Uri.parse(settings.name ?? '');
        if (uri.path == '/quote' && uri.queryParameters.containsKey('token')) {
          final token = uri.queryParameters['token']!;
          return MaterialPageRoute(
            builder: (context) => ClientQuoteScreen(
              storage: authService.storage,
              accessToken: token,
            ),
          );
        }
        // Default route
        return null;
      },
      home: _getHomeScreen(authService),
    );
  }
}
