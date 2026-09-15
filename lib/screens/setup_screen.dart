import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'manager_home_screen.dart';
import 'manager/company_settings_screen.dart';
import 'login_screen.dart';

class SetupScreen extends StatefulWidget {
  final AuthService authService;

  const SetupScreen({Key? key, required this.authService}) : super(key: key);

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _companyController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _completeSetup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Firebase Auth account + server-assigned manager role and companyId.
    // A Cloud Function creates the profile and company documents — the
    // client never writes its own role. try/finally so _isLoading can't get
    // stuck if anything throws (same class of bug just fixed in
    // AuthService.login/registerCompany and login_screen.dart's _login).
    LoginResult result;
    try {
      result = await widget.authService.registerCompany(
        companyName: _companyController.text.trim(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (!mounted) return;

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: Colors.red),
      );
      return;
    }

    // Navigate to manager home, then immediately open settings to complete profile
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>
            ManagerHomeScreen(authService: widget.authService),
      ),
    );

    // Push settings screen on top so user completes company profile
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            CompanySettingsScreen(authService: widget.authService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Logo and welcome
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.water_drop,
                    size: 50,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'IRRIGATION',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w300,
                        letterSpacing: 4,
                        color: Colors.grey.shade600,
                      ),
                ),
                Text(
                  'AUTOMATED FLOW',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Let\'s set up your commercial account',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 32),

                // Stepper
                Stepper(
                  currentStep: _currentStep,
                  onStepContinue: () {
                    if (_currentStep == 0) {
                      if (_companyController.text.isNotEmpty) {
                        setState(() => _currentStep = 1);
                      }
                    } else if (_currentStep == 1) {
                      if (_nameController.text.isNotEmpty &&
                          _emailController.text.isNotEmpty &&
                          _emailController.text.contains('@')) {
                        setState(() => _currentStep = 2);
                      }
                    } else if (_currentStep == 2) {
                      _completeSetup();
                    }
                  },
                  onStepCancel: () {
                    if (_currentStep > 0) {
                      setState(() => _currentStep -= 1);
                    }
                  },
                  controlsBuilder: (context, details) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed:
                                _isLoading ? null : details.onStepContinue,
                            child: _isLoading && _currentStep == 2
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Text(_currentStep == 2
                                    ? 'Complete Setup'
                                    : 'Continue'),
                          ),
                          if (_currentStep > 0) ...[
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: details.onStepCancel,
                              child: const Text('Back'),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                  steps: [
                    // Step 1: Company Info
                    Step(
                      title: const Text('Company Info'),
                      subtitle: const Text('Your business name'),
                      isActive: _currentStep >= 0,
                      state: _currentStep > 0
                          ? StepState.complete
                          : StepState.indexed,
                      content: Column(
                        children: [
                          TextFormField(
                            controller: _companyController,
                            decoration: const InputDecoration(
                              labelText: 'Company Name',
                              hintText: 'e.g., ABC Irrigation Services',
                              prefixIcon: Icon(Icons.business),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your company name';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    // Step 2: Admin Account
                    Step(
                      title: const Text('Admin Account'),
                      subtitle: const Text('Your login credentials'),
                      isActive: _currentStep >= 1,
                      state: _currentStep > 1
                          ? StepState.complete
                          : StepState.indexed,
                      content: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Your Name',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(),
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
                        ],
                      ),
                    ),

                    // Step 3: Password
                    Step(
                      title: const Text('Set Password'),
                      subtitle: const Text('Secure your account'),
                      isActive: _currentStep >= 2,
                      state: _currentStep > 2
                          ? StepState.complete
                          : StepState.indexed,
                      content: Column(
                        children: [
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirm = !_obscureConfirm;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F0F0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    color: Color(0xFF0EA5E9)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'This will be your admin account. You can add technicians and managers after setup.',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Already have an account?
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) =>
                                LoginScreen(authService: widget.authService),
                          ),
                        );
                      },
                      child: Text(
                        'Sign in',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
