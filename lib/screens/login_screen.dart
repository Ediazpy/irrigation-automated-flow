import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../constants/app_version.dart';
import 'manager_home_screen.dart';
import 'technician_home_screen.dart';
import 'setup_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;

  const LoginScreen({Key? key, required this.authService}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String _savedEmailKey = 'iaf_saved_email';

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberEmail = true;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_savedEmailKey);
    if (saved != null && saved.isNotEmpty && mounted) {
      setState(() => _emailController.text = saved);
    }
  }

  Future<void> _persistEmailChoice() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberEmail) {
      await prefs.setString(_savedEmailKey, _emailController.text.trim().toLowerCase());
    } else {
      await prefs.remove(_savedEmailKey);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await widget.authService.login(
      _emailController.text.trim().toLowerCase(),
      _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.success) {
      await _persistEmailChoice();
      if (!mounted) return;
      // Navigate to appropriate home screen
      if (widget.authService.isManager) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ManagerHomeScreen(authService: widget.authService),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => TechnicianHomeScreen(authService: widget.authService),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showForgotPasswordDialog() {
    final emailController =
        TextEditingController(text: _emailController.text.trim().toLowerCase());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your email and we\'ll send you a link to reset your password:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final email = emailController.text.trim().toLowerCase();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid email'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              _sendPasswordReset(email);
            },
            child: const Text('Send Reset Email'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendPasswordReset(String email) async {
    try {
      await widget.authService.sendPasswordReset(email);
    } catch (_) {
      // Deliberately ignore errors — do not reveal whether the email exists.
    }
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Check Your Email'),
        content: Text(
          'If an account exists for $email, a password reset link has been sent. '
          'Follow the link in the email to choose a new password.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      body: Column(
        children: [
          // ── Gradient Hero Header ────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Glassy icon circle
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.water_drop,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 18),

                // IAF brand name — large, spaced
                const Text(
                  'IAF',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Irrigation Automated Flow',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // ── Login Form ──────────────────────────────────────────────────
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Section heading
                        const Text(
                          'Welcome back',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A2332),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Sign in to your account to continue',
                          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 24),

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email address',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          onFieldSubmitted: (_) => _isLoading ? null : _login(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: const Color(0xFF94A3B8),
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),

                        // Remember email + Forgot Password on one row
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => setState(
                                    () => _rememberEmail = !_rememberEmail),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        value: _rememberEmail,
                                        onChanged: (v) => setState(
                                            () => _rememberEmail = v ?? true),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Remember email',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _showForgotPasswordDialog,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 8),
                              ),
                              child: const Text('Forgot Password?'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Sign In button
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Divider row
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // New Company
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'New company?',
                              style: TextStyle(
                                  fontSize: 14, color: Color(0xFF64748B)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SetupScreen(authService: widget.authService),
                                ),
                              ),
                              child: const Text('Create Account'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),
                        Text(
                          appVersion,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
