import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'services/revenuecat_service.dart';
import 'screens/login_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/manager_home_screen.dart';
import 'screens/technician_home_screen.dart';
import 'utils/app_version.dart';

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
  bool _showWhatsNew = false;

  @override
  void initState() {
    super.initState();
    _authServiceFuture = _initializeApp();
  }

  Future<AuthService> _initializeApp() async {
    print('Initializing IAF App...');

    // Initialize RevenueCat for mobile subscriptions
    await RevenueCatService.initialize();

    // Initialize storage
    final storage = StorageService();

    try {
      print('Loading data...');
      await storage.loadData();
      print('Data loaded successfully');
    } catch (e) {
      print('Error loading data (using defaults): $e');
    }

    // Initialize auth service
    final authService = AuthService(storage);

    // Try to restore previous session
    await authService.restoreSession();
    print('Auth service initialized (session restored: ${authService.isLoggedIn})');

    // Check if this is a new version since last launch
    final prefs = await SharedPreferences.getInstance();
    final lastSeenVersion = prefs.getString('last_app_version') ?? '';
    if (lastSeenVersion != kAppVersion) {
      _showWhatsNew = true;
      await prefs.setString('last_app_version', kAppVersion);
    }

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
        return IrriTrackApp(authService: authService, showWhatsNew: _showWhatsNew);
      },
    );
  }
}

class IrriTrackApp extends StatefulWidget {
  final AuthService authService;
  final bool showWhatsNew;

  const IrriTrackApp({
    Key? key,
    required this.authService,
    this.showWhatsNew = false,
  }) : super(key: key);

  @override
  State<IrriTrackApp> createState() => _IrriTrackAppState();
}

class _IrriTrackAppState extends State<IrriTrackApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    if (widget.showWhatsNew) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showWhatsNewDialog());
    }
  }

  void _showWhatsNewDialog() {
    final ctx = _navigatorKey.currentContext;
    if (ctx == null) return;
    showDialog(
      context: ctx,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.system_update, color: Colors.teal.shade700, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Updated to v$kAppVersion',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("What's New",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600,
                        fontWeight: FontWeight.normal)),
              ],
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: kWhatsNew.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, color: Colors.teal.shade600, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(item, style: const TextStyle(fontSize: 13))),
              ],
            ),
          )).toList(),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Irrigation Automated Flow',
      navigatorKey: _navigatorKey,
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
      home: widget.authService.isLoggedIn
          ? (widget.authService.isManager
              ? ManagerHomeScreen(authService: widget.authService)
              : TechnicianHomeScreen(authService: widget.authService))
          : WelcomeScreen(authService: widget.authService),
    );
  }
}
