import 'dart:math';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user.dart';
import 'manager_home_screen.dart';
import 'technician_home_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;

  const LoginScreen({Key? key, required this.authService}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

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

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (result.success) {
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
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forgot Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your email to reset your password:'),
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
              Navigator.pop(context);
              _attemptPasswordReset(email);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _attemptPasswordReset(String email) {
    final user = widget.authService.storage.users[email];

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Technicians must contact manager
    if (user.role != 'manager') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Contact Manager'),
          content: const Text(
            'Technicians must contact their manager to reset their password.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Manager must have security questions set up
    if (!user.hasSecurityQuestions()) {
      _showAlternateResetOptions(user);
      return;
    }

    // Show security question challenge
    _showSecurityQuestionChallenge(user);
  }

  void _showAlternateResetOptions(User user) {
    final hasMasterCode = widget.authService.storage.companySettings?.masterResetCode.isNotEmpty == true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Password Recovery'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Security questions have not been set up. Choose a recovery option:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (hasMasterCode)
              ListTile(
                leading: const Icon(Icons.vpn_key, color: Colors.teal),
                title: const Text('Use Master Reset Code'),
                subtitle: const Text('Enter the code provided by your admin/dev team'),
                onTap: () {
                  Navigator.pop(context);
                  _showMasterCodeDialog(user);
                },
              ),
            ListTile(
              leading: const Icon(Icons.send, color: Colors.orange),
              title: const Text('Request Reset from Dev Team'),
              subtitle: const Text('Send a reset request via cloud'),
              onTap: () {
                Navigator.pop(context);
                _submitResetRequest(user);
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.blue),
              title: const Text('Check Reset Status'),
              subtitle: const Text('Check if your reset request was approved'),
              onTap: () {
                Navigator.pop(context);
                _checkResetRequestStatus(user);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showMasterCodeDialog(User user) {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Master Reset Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the master reset code to reset your password:'),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Master Code',
                prefixIcon: Icon(Icons.vpn_key),
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
              final enteredCode = codeController.text.trim();
              final masterCode = widget.authService.storage.companySettings?.masterResetCode ?? '';

              if (enteredCode.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter the master code'), backgroundColor: Colors.red),
                );
                return;
              }

              if (enteredCode == masterCode) {
                Navigator.pop(context);
                _showNewPasswordDialog(user);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid master code'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _submitResetRequest(User user) async {
    try {
      final firestoreService = FirestoreService();
      await firestoreService.submitResetRequest(user.email, user.name);

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Request Sent'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your password reset request has been sent to the dev team.',
              ),
              const SizedBox(height: 12),
              Text(
                'Email: ${user.email}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Once approved, come back and tap "Forgot Password" > "Check Reset Status" to set your new password.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send request: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _checkResetRequestStatus(User user) async {
    try {
      final firestoreService = FirestoreService();
      final request = await firestoreService.checkResetRequest(user.email);

      if (!mounted) return;

      if (request == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No reset request found. Submit one first.'), backgroundColor: Colors.orange),
        );
        return;
      }

      final status = request['status'] ?? 'pending';

      if (status == 'approved') {
        final newPassword = request['new_password'] ?? '';
        if (newPassword.isNotEmpty) {
          // Apply the approved password reset
          final storage = widget.authService.storage;
          storage.users[user.email] = user.copyWith(password: newPassword);
          storage.failedAttempts.remove(user.email);
          await storage.saveData();

          // Clean up the request
          await firestoreService.deleteResetRequest(user.email);

          if (!mounted) return;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Password Reset!'),
              content: const Text(
                'Your password has been reset by the dev team. You can now log in with the temporary password they provided. Please change it after logging in.',
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
      } else if (status == 'denied') {
        await firestoreService.deleteResetRequest(user.email);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your reset request was denied. Contact the dev team directly.'), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your request is still pending. Please wait for the dev team to approve it.'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking status: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showSecurityQuestionChallenge(User user) {
    // Pick 3 random questions from the ones the user answered
    final answeredIds = user.securityAnswers.keys.toList();
    answeredIds.shuffle(Random());
    final selectedIds = answeredIds.take(3).toList();

    final answerControllers = <String, TextEditingController>{};
    for (var id in selectedIds) {
      answerControllers[id] = TextEditingController();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Security Questions'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Answer the following security questions to reset your password:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ...selectedIds.map((id) {
                final question = User.securityQuestions
                    .firstWhere((q) => q['id'] == id, orElse: () => {'question': 'Unknown'})['question']!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: answerControllers[id],
                    decoration: InputDecoration(
                      labelText: question,
                      isDense: true,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Verify answers (case insensitive)
              bool allCorrect = true;
              for (var id in selectedIds) {
                final userAnswer = answerControllers[id]!.text.trim().toLowerCase();
                final correctAnswer = user.securityAnswers[id]?.toLowerCase() ?? '';
                if (userAnswer != correctAnswer) {
                  allCorrect = false;
                  break;
                }
              }

              if (allCorrect) {
                Navigator.pop(context);
                _showNewPasswordDialog(user);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('One or more answers are incorrect'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _showNewPasswordDialog(User user) {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Set New Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outline),
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
              final newPassword = newPasswordController.text;
              final confirmPassword = confirmPasswordController.text;

              if (newPassword.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password must be at least 4 characters'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (newPassword != confirmPassword) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwords do not match'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Update password and clear failed attempts
              final storage = widget.authService.storage;
              storage.users[user.email] = user.copyWith(password: newPassword);
              storage.failedAttempts.remove(user.email);
              storage.saveData();

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password reset successfully! Please login.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Column(
      children: [
        Text(
          'IAF',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Irrigation Automated Flow',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w300,
                letterSpacing: 1,
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  _buildLogo(context),
                  const SizedBox(height: 8),
                  Text(
                    'Commercial Irrigation Management',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 48),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Forgot Password Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }
}
