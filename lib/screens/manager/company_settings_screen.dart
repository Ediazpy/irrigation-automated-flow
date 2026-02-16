import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/company_settings.dart';
import '../../models/user.dart';
import '../../utils/password_hash.dart';

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
  late bool _photosRequired;
  late TextEditingController _masterResetCodeController;
  bool _isSyncing = false;

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
    _photosRequired = settings?.photosRequired ?? false;
    // Don't display the hashed master code — show empty field for re-entry
    final existingCode = settings?.masterResetCode ?? '';
    _masterResetCodeController = TextEditingController(
      text: PasswordHash.isHashed(existingCode) ? '' : existingCode,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _termsController.dispose();
    _footerController.dispose();
    _masterResetCodeController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    if (!_formKey.currentState!.validate()) return;

    // Hash the master reset code if it has been set/changed
    final rawCode = _masterResetCodeController.text.trim();
    final existingCode = widget.authService.storage.companySettings?.masterResetCode ?? '';
    String hashedCode;
    if (rawCode.isEmpty) {
      // User left field empty — keep existing hashed code
      hashedCode = existingCode;
    } else if (PasswordHash.isHashed(rawCode)) {
      // Already hashed (shouldn't normally happen)
      hashedCode = rawCode;
    } else {
      // New plaintext code — hash it
      hashedCode = PasswordHash.hashPassword(rawCode);
    }

    final settings = CompanySettings(
      companyName: _nameController.text.trim(),
      companyPhone: _phoneController.text.trim(),
      companyEmail: _emailController.text.trim(),
      companyAddress: _addressController.text.trim(),
      defaultTermsAndConditions: _termsController.text.trim(),
      quoteExpirationDays: _expirationDays,
      defaultFooterMessage: _footerController.text.trim(),
      photosRequired: _photosRequired,
      masterResetCode: hashedCode,
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Form(
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

            // Inspection Photos Section
            _buildSectionHeader('Inspection Photos', Icons.camera_alt),
            const SizedBox(height: 12),
            Card(
              child: SwitchListTile(
                secondary: Icon(
                  _photosRequired ? Icons.camera_alt : Icons.no_photography,
                  color: _photosRequired ? Colors.green : Colors.grey,
                ),
                title: const Text('Require Repair Photos'),
                subtitle: Text(
                  _photosRequired
                      ? 'Technicians must take photos before submitting'
                      : 'Photos are optional for technicians',
                ),
                value: _photosRequired,
                onChanged: (value) {
                  setState(() => _photosRequired = value);
                },
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

            // Cloud Sync Section
            _buildSectionHeader('Cloud Sync', Icons.cloud_sync),
            const SizedBox(height: 12),
            _buildCloudSyncCard(),

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

            // Master Reset Code Section
            _buildSectionHeader('Master Reset Code', Icons.vpn_key),
            const SizedBox(height: 8),
            Text(
              'Set a master code that can be used to reset a locked-out admin account. Share this code only with your dev team or trusted support.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _masterResetCodeController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Master Reset Code',
                prefixIcon: const Icon(Icons.vpn_key),
                hintText: PasswordHash.isHashed(widget.authService.storage.companySettings?.masterResetCode ?? '')
                    ? 'Code is set (enter new code to change)'
                    : 'Enter a secure code (e.g. 6+ characters)',
                helperText: 'Stored securely as a hash. Leave blank to keep existing code.',
              ),
            ),

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
                // Validate at least 3 questions answered, hash answers
                final answers = <String, String>{};
                for (var id in selectedQuestions) {
                  final answer = controllers[id]!.text.trim();
                  if (answer.isNotEmpty) {
                    // Hash the answer (lowercase for case-insensitive comparison)
                    answers[id] = PasswordHash.hashPassword(answer.toLowerCase());
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

  Widget _buildCloudSyncCard() {
    final storage = widget.authService.storage;
    final syncEnabled = storage.firestoreSyncEnabled;

    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: Icon(
              syncEnabled ? Icons.cloud_done : Icons.cloud_off,
              color: syncEnabled ? Colors.green : Colors.grey,
            ),
            title: const Text('Enable Cloud Sync'),
            subtitle: Text(
              syncEnabled
                  ? 'Data automatically syncs to Firebase'
                  : 'Data stored locally only',
            ),
            value: syncEnabled,
            onChanged: _isSyncing
                ? null
                : (value) async {
                    setState(() => _isSyncing = true);
                    if (value) {
                      await storage.enableFirestoreSync();
                      // Upload current data to cloud
                      final success = await storage.uploadToFirestore();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? 'Cloud sync enabled and data uploaded'
                                : 'Cloud sync enabled but upload failed'),
                            backgroundColor: success ? Colors.green : Colors.orange,
                          ),
                        );
                      }
                    } else {
                      await storage.disableFirestoreSync();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cloud sync disabled'),
                            backgroundColor: Colors.grey,
                          ),
                        );
                      }
                    }
                    if (mounted) {
                      setState(() => _isSyncing = false);
                    }
                  },
          ),
          if (syncEnabled) ...[
            const Divider(height: 1),
            ListTile(
              leading: _isSyncing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload),
              title: const Text('Upload to Cloud'),
              subtitle: const Text('Push local data to Firebase'),
              onTap: _isSyncing
                  ? null
                  : () async {
                      setState(() => _isSyncing = true);
                      final success = await storage.uploadToFirestore();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? 'Data uploaded successfully'
                                : 'Upload failed'),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );
                        setState(() => _isSyncing = false);
                      }
                    },
            ),
            ListTile(
              leading: _isSyncing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_download),
              title: const Text('Download from Cloud'),
              subtitle: const Text('Replace local data with cloud data'),
              onTap: _isSyncing
                  ? null
                  : () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Download from Cloud?'),
                          content: const Text(
                            'This will replace all local data with data from Firebase. '
                            'Any local changes not uploaded will be lost.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                              child: const Text('Download'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        setState(() => _isSyncing = true);
                        final success = await storage.downloadFromFirestore();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? 'Data downloaded successfully'
                                  : 'Download failed'),
                              backgroundColor: success ? Colors.green : Colors.red,
                            ),
                          );
                          setState(() => _isSyncing = false);
                        }
                      }
                    },
            ),
          ],
        ],
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
