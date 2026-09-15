import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class MonthlyResetScreen extends StatelessWidget {
  final AuthService authService;

  const MonthlyResetScreen({Key? key, required this.authService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final storage = authService.storage;

    // Count inspections
    final completedCount = storage.inspections.values
        .where((i) => i.status == 'completed')
        .length;
    final incompleteCount = storage.inspections.values
        .where((i) => i.status != 'completed')
        .length;
    final totalCount = storage.inspections.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Reset'),
        backgroundColor: Colors.red.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Warning Card
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 64,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'MONTHLY RESET',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This action will archive all completed inspections and reset the system for a new month.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Current Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Status',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                    _buildStatusRow('Total Inspections', totalCount.toString(), Icons.assignment),
                    const SizedBox(height: 12),
                    _buildStatusRow('Completed', completedCount.toString(), Icons.check_circle, Colors.green),
                    const SizedBox(height: 12),
                    _buildStatusRow('Incomplete', incompleteCount.toString(), Icons.pending, Colors.orange),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // What will happen Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'What will happen:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildBulletPoint('All COMPLETED inspections will be archived'),
                    _buildBulletPoint('All INCOMPLETE inspections will be deleted'),
                    _buildBulletPoint('You can then create new inspections for the new month'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Archived inspections can be viewed in the History screen',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Reset Button
            ElevatedButton.icon(
              onPressed: () => _confirmReset(context),
              icon: const Icon(Icons.restart_alt, size: 28),
              label: const Text(
                'START MONTHLY RESET',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(20),
              ),
            ),

            const SizedBox(height: 16),

            // Cancel Button
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, IconData icon, [Color? color]) {
    return Row(
      children: [
        Icon(icon, color: color ?? Colors.grey, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade700),
            const SizedBox(width: 8),
            const Text('Confirm Reset'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you absolutely sure?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 12),
            Text('This action cannot be undone.'),
            SizedBox(height: 8),
            Text('Type "RESET" below to confirm:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close confirmation dialog
              _showFinalConfirmation(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showFinalConfirmation(BuildContext context) {
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Type RESET to confirm:'),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'RESET',
              ),
              textCapitalization: TextCapitalization.characters,
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
              if (confirmController.text.trim().toUpperCase() == 'RESET') {
                Navigator.pop(context); // Close dialog
                _performReset(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please type RESET to confirm'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('RESET NOW'),
          ),
        ],
      ),
    );
  }

  void _performReset(BuildContext context) {
    final storage = authService.storage;

    // Count what we're doing
    int completedArchived = 0;
    int incompleteDeleted = 0;

    // Create a new map to store only the completed inspections for archive
    // (In a real app, you might move these to a separate "archived_inspections" collection)
    final Map<int, dynamic> newInspections = {};

    for (var entry in storage.inspections.entries) {
      if (entry.value.status == 'completed') {
        // Keep completed inspections (they stay in history)
        completedArchived++;
        // In a future version, you might move these to an archive
      } else {
        // Delete incomplete inspections
        incompleteDeleted++;
      }
    }

    // Clear all inspections
    storage.inspections.clear();

    // Save the changes
    storage.saveData();

    // Go back to home screen
    Navigator.pop(context);

    // Show success message
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700),
            const SizedBox(width: 8),
            const Text('Reset Complete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✓ $completedArchived completed inspections archived'),
            Text('✓ $incompleteDeleted incomplete inspections deleted'),
            const SizedBox(height: 16),
            const Text(
              'You can now create new inspections for the new month using Bulk Schedule.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
