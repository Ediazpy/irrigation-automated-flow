import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/company_settings.dart';

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
