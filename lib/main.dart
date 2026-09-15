import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'constants/app_version.dart';
import 'utils/web_reload.dart';
import 'utils/web_url.dart';
import 'screens/login_screen.dart';
import 'screens/manager_home_screen.dart';
import 'screens/technician_home_screen.dart';
import 'screens/client/client_quote_screen.dart';

// Capture the quote token from the URL BEFORE Flutter routing modifies it
String? _initialQuoteToken;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Capture quote token from the actual browser URL before Flutter changes it
  if (kIsWeb) {
    final href = getWebUrl(); // window.location.href
    if (href != null) {
      final uri = Uri.tryParse(href);
      if (uri != null) {
        // Check path-based URL: /quote?token=ABC
        if (uri.path.contains('/quote') &&
            uri.queryParameters.containsKey('token')) {
          _initialQuoteToken = uri.queryParameters['token'];
        }
        // Check hash-based URL: /#/quote?token=ABC
        if (_initialQuoteToken == null && uri.fragment.contains('token=')) {
          final fragmentUri = Uri.tryParse('/?${uri.fragment.split('?').last}');
          if (fragmentUri != null &&
              fragmentUri.queryParameters.containsKey('token')) {
            _initialQuoteToken = fragmentUri.queryParameters['token'];
          }
        }
      }
    }
  }

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

  bool _updateAvailable = false;

  Future<AuthService> _initializeApp() async {
    // Initialize storage (local cache only — cloud data needs auth)
    final storage = StorageService();

    try {
      await storage.loadData();
    } catch (_) {}

    // Initialize auth service and restore any persisted Firebase Auth session
    final authService = AuthService(storage);
    final restored = await authService.restoreSession();

    // Sync from Firestore only when authenticated — rules deny anonymous reads.
    // Timeout guards against hanging forever on poor/no connectivity (see the
    // note on AuthService.restoreSession for why this matters at startup).
    if (restored && storage.firestoreSyncEnabled) {
      try {
        await storage
            .downloadFromFirestore()
            .timeout(const Duration(seconds: 15));
      } catch (_) {}
    }

    // Auto-migrate existing property client data into Client records
    if (restored &&
        storage.clients.isEmpty &&
        storage.properties.values
            .any((p) => p.clientName.isNotEmpty || p.clientEmail.isNotEmpty)) {
      storage.migratePropertyClientsToClientRecords();
      await storage.saveData();
    }

    // Check for app updates (metadata/app_version is maintained by the
    // deploy script; clients only read it)
    if (restored) {
      try {
        final latestVersion = await FirestoreService()
            .getLatestAppVersion()
            .timeout(const Duration(seconds: 8));
        if (latestVersion != null && latestVersion != appVersion) {
          _updateAvailable = true;
        }
      } catch (_) {}
    }

    return authService;
  }

  @override
  Widget build(BuildContext context) {
    // Fast path: customer viewing a quote — skip full app init
    if (_initialQuoteToken != null) {
      return IrriTrackApp.quoteOnly(token: _initialQuoteToken!);
    }

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
        return IrriTrackApp(
            authService: authService, updateAvailable: _updateAvailable);
      },
    );
  }
}

class IrriTrackApp extends StatefulWidget {
  final AuthService? authService;
  final bool updateAvailable;
  final String? quoteToken;

  const IrriTrackApp(
      {Key? key,
      required AuthService authService,
      this.updateAvailable = false})
      : authService = authService,
        quoteToken = null,
        super(key: key);

  const IrriTrackApp.quoteOnly({Key? key, required String token})
      : authService = null,
        updateAvailable = false,
        quoteToken = token,
        super(key: key);

  @override
  State<IrriTrackApp> createState() => _IrriTrackAppState();
}

class _IrriTrackAppState extends State<IrriTrackApp> {
  bool _updateDismissed = false;

  Widget _getHomeScreen() {
    final authService = widget.authService!;

    // Normal app flow — Firebase Auth is the single source of truth for
    // whether someone is signed in. New companies sign up from the login
    // screen's "Create Account" link.
    if (authService.isLoggedIn) {
      return authService.isManager
          ? ManagerHomeScreen(authService: authService)
          : TechnicianHomeScreen(authService: authService);
    }
    return LoginScreen(authService: authService);
  }

  void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon:
            const Icon(Icons.system_update, size: 48, color: Color(0xFF0EA5E9)),
        title: const Text('Update Available'),
        content: const Text(
          'A new version of the app is available. Please refresh to get the latest features and fixes.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _updateDismissed = true);
            },
            child: const Text('Later'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (kIsWeb) {
                // Force a hard reload on web to clear service worker cache
                _forceWebReload();
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Update Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _forceWebReload() {
    forceWebReload();
  }

  @override
  Widget build(BuildContext context) {
    // Show update dialog after first frame if update is available
    if (widget.updateAvailable && !_updateDismissed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.updateAvailable && !_updateDismissed) {
          _showUpdateDialog(context);
          _updateDismissed = true; // prevent showing again
        }
      });
    }

    // Brand colors – clean light blue (Jobber-inspired layout)
    const Color primaryBlue = Color(0xFF0EA5E9); // sky-500 light blue
    const Color secondaryBlue = Color(0xFF0284C7); // sky-600 darker accent
    const Color darkText = Color(0xFF1F2937); // near-black text
    const Color bgColor = Color(0xFFF8FAFC); // slate-50 background

    return MaterialApp(
      title: 'Irrigation Automated Flow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          brightness: Brightness.light,
        ).copyWith(
          primary: primaryBlue,
          onPrimary: Colors.white,
          secondary: secondaryBlue,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: bgColor,

        // ── Typography ──────────────────────────────────────────────────────
        textTheme:
            GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
          headlineLarge: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: darkText,
          ),
          headlineMedium: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: darkText,
          ),
          headlineSmall: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: darkText,
          ),
          titleLarge: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: darkText,
          ),
          titleMedium: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: darkText,
          ),
          bodyLarge: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF374151),
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6B7280),
          ),
          labelLarge: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),

        // ── AppBar (Jobber: white with dark text) ───────────────────────────
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: darkText,
          elevation: 0,
          centerTitle: false,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: GoogleFonts.inter(
            color: darkText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: darkText),
        ),

        // ── Cards ───────────────────────────────────────────────────────────
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
          margin: EdgeInsets.zero,
        ),

        // ── Elevated Buttons ────────────────────────────────────────────────
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            textStyle:
                GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),

        // ── Outlined Buttons ────────────────────────────────────────────────
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryBlue,
            side: const BorderSide(color: Color(0xFFD1D5DB)),
            textStyle:
                GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),

        // ── Text Buttons ────────────────────────────────────────────────────
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryBlue,
            textStyle:
                GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),

        // ── Input Fields ────────────────────────────────────────────────────
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primaryBlue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red),
          ),
          labelStyle: GoogleFonts.inter(color: const Color(0xFF6B7280)),
          hintStyle: GoogleFonts.inter(color: const Color(0xFF9CA3AF)),
        ),

        // ── Tab Bar ──────────────────────────────────────────────────────────
        tabBarTheme: TabBarThemeData(
          labelStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 13),
          labelColor: primaryBlue,
          unselectedLabelColor: const Color(0xFF6B7280),
          indicatorColor: primaryBlue,
        ),

        // ── Bottom Nav ──────────────────────────────────────────────────────
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: primaryBlue,
          unselectedItemColor: const Color(0xFF9CA3AF),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          selectedLabelStyle:
              GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
        ),

        // ── FAB ─────────────────────────────────────────────────────────────
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 2,
        ),

        // ── Divider ─────────────────────────────────────────────────────────
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE5E7EB),
          thickness: 1,
          space: 1,
        ),

        // ── Dialog ──────────────────────────────────────────────────────────
        dialogTheme: DialogThemeData(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),

        // ── Chip ─────────────────────────────────────────────────────────────
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      onGenerateRoute: (settings) {
        // Handle /quote?token=XYZ for customer quote approval (no login needed)
        final uri = Uri.parse(settings.name ?? '');
        if (uri.path == '/quote' && uri.queryParameters.containsKey('token')) {
          final token = uri.queryParameters['token']!;
          return MaterialPageRoute(
            builder: (context) => ClientQuoteScreen(accessToken: token),
          );
        }
        // Default route
        return null;
      },
      home: widget.quoteToken != null
          ? ClientQuoteScreen(accessToken: widget.quoteToken!)
          : _getHomeScreen(),
    );
  }
}
