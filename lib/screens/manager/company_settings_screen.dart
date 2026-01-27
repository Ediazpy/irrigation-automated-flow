import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/company_settings.dart';
import '../../models/user.dart';

class CompanySettingsScreen extends StatefulWidget {
  final AuthService authService;

  const CompanySettingsScreen({Key? key, required this.authService}) : super(key: key);

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _termsController;
  late TextEditingController _footerController;
  late int _expirationDays;

  @override
  void initState() {
    super.initState();
    final settings = widget.authService.storage.companySettings;
    _nameController = TextEditingController(text: settings?.companyName ?? '');
    _phoneController = TextEditingController(text: settings?.companyPhone ?? '');
    _emailController = TextEditingController(text: settings?.companyEmail ?? '');
    _addressController = TextEditingController(text: settings?.companyAddress ?? '');
    _termsController = TextEditingController(
        text: settings?.defaultTermsAndConditions ?? CompanySettings.defaultTerms);
    _footerController = TextEditingController(
        text: settings?.defaultFooterMessage ?? 'Thank you for your business!');
    _expirationDays = settings?.quoteExpirationDays ?? 30;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _termsController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    if (!_formKey.currentState!.validate()) return;

    final settings = CompanySettings(
      companyName: _nameController.text.trim(),
      companyPhone: _phoneController.text.trim(),
      companyEmail: _emailController.text.trim(),
      companyAddress: _addressController.text.trim(),
      defaultTermsAndConditions: _termsController.text.trim(),
      quoteExpirationDays: _expirationDays,
      defaultFooterMessage: _footerController.text.trim(),
    );

    widget.authService.storage.companySettings = settings;
    widget.authService.storage.saveData();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Company settings saved'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

  void _resetTermsToDefault() {
    setState(() {
      _termsController.text = CompanySettings.defaultTerms;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Settings'),
        actions: [
          TextButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Company Information Section
            _buildSectionHeader('Company Information', Icons.business),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Company Name',
                prefixIcon: Icon(Icons.business),
                hintText: 'Your Irrigation Company',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Company name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
                hintText: '(555) 123-4567',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email),
                hintText: 'contact@yourcompany.com',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Business Address',
                prefixIcon: Icon(Icons.location_on),
                hintText: '123 Main St, City, State ZIP',
              ),
            ),

            const SizedBox(height: 32),

            // Quote Settings Section
            _buildSectionHeader('Quote Settings', Icons.receipt_long),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.timer),
                title: const Text('Quote Expiration'),
                subtitle: Text('$_expirationDays days'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _expirationDays > 7
                          ? () => setState(() => _expirationDays--)
                          : null,
                    ),
                    Text('$_expirationDays'),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _expirationDays < 90
                          ? () => setState(() => _expirationDays++)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _footerController,
              decoration: const InputDecoration(
                labelText: 'Quote Footer Message',
                prefixIcon: Icon(Icons.message),
                hintText: 'Thank you for your business!',
              ),
            ),

            const SizedBox(height: 32),

            // Terms and Conditions Section
            _buildSectionHeader('Terms and Conditions', Icons.description),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _resetTermsToDefault,
                  icon: const Icon(Icons.restore, size: 18),
                  label: const Text('Reset to Default'),
                ),
              ],
            ),
            TextFormField(
              controller: _termsController,
              maxLines: 12,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter your terms and conditions...',
              ),
            ),

            const SizedBox(height: 32),

            // Security Questions Section
            _buildSectionHeader('Security Questions', Icons.security),
            const SizedBox(height: 8),
            Text(
              'Set up security questions to allow password reset if locked out.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 12),
            _buildSecurityQuestionsCard(),

            const SizedBox(height: 32),

            // Save Button
            ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save),
              label: const Text('Save Settings'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityQuestionsCard() {
    final currentUser = widget.authService.currentUser;
    final hasQuestions = currentUser?.hasSecurityQuestions() ?? false;

    return Card(
      child: ListTile(
        leading: Icon(
          hasQuestions ? Icons.check_circle : Icons.warning,
          color: hasQuestions ? Colors.green : Colors.orange,
        ),
        title: Text(hasQuestions ? 'Security Questions Set' : 'Security Questions Not Set'),
        subtitle: Text(
          hasQuestions
              ? 'You can reset your password using security questions'
              : 'Set up questions to enable password reset',
        ),
        trailing: ElevatedButton(
          onPressed: _setupSecurityQuestions,
          child: Text(hasQuestions ? 'Update' : 'Set Up'),
        ),
      ),
    );
  }

  void _setupSecurityQuestions() {
    final currentUser = widget.authService.currentUser;
    if (currentUser == null) return;

    // Controllers for answers
    final controllers = <String, TextEditingController>{};
    for (var q in User.securityQuestions) {
      controllers[q['id']!] = TextEditingController(
        text: currentUser.securityAnswers[q['id']] ?? '',
      );
    }

    // Track selected questions
    Set<String> selectedQuestions = Set.from(currentUser.securityAnswers.keys);
    if (selectedQuestions.length < 3) {
      // Pre-select first 3 if none selected
      selectedQuestions = User.securityQuestions.take(3).map((q) => q['id']!).toSet();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Security Questions'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select and answer at least 3 questions:',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  ...User.securityQuestions.map((q) {
                    final id = q['id']!;
                    final question = q['question']!;
                    final isSelected = selectedQuestions.contains(id);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                onChanged: (value) {
                                  setDialogState(() {
                                    if (value == true) {
                                      selectedQuestions.add(id);
                                    } else {
                                      selectedQuestions.remove(id);
                                      controllers[id]!.clear();
                                    }
                                  });
                                },
                              ),
                              Expanded(
                                child: Text(
                                  question,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                    color: isSelected ? null : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (isSelected)
                            Padding(
                              padding: const EdgeInsets.only(left: 48),
                              child: TextField(
                                controller: controllers[id],
                                decoration: const InputDecoration(
                                  hintText: 'Your answer',
                                  isDense: true,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Validate at least 3 questions answered
                final answers = <String, String>{};
                for (var id in selectedQuestions) {
                  final answer = controllers[id]!.text.trim();
                  if (answer.isNotEmpty) {
                    answers[id] = answer;
                  }
                }

                if (answers.length < 3) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please answer at least 3 questions'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Save answers
                final storage = widget.authService.storage;
                storage.users[currentUser.email] = currentUser.copyWith(
                  securityAnswers: answers,
                );
                storage.saveData();

                Navigator.pop(context);
                setState(() {}); // Refresh the card

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Security questions saved'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
