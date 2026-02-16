import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'manager/repair_items_screen.dart';
import 'manager/properties_screen.dart';
import 'manager/assign_inspection_screen.dart';
import 'manager/bulk_schedule_screen.dart';
import 'manager/monthly_dashboard_screen.dart';
import 'manager/review_inspections_screen.dart';
import 'manager/completed_inspections_screen.dart';
import 'manager/inspection_history_screen.dart';
import 'manager/users_screen.dart';
import 'manager/monthly_reset_screen.dart';
import 'manager/monthly_report_screen.dart';
import 'manager/quotes_list_screen.dart';
import 'manager/repair_tasks_list_screen.dart';
import 'manager/company_settings_screen.dart';
import 'login_screen.dart';

class ManagerHomeScreen extends StatelessWidget {
  final AuthService authService;

  const ManagerHomeScreen({Key? key, required this.authService}) : super(key: key);

  void _logout(BuildContext context) {
    authService.logout(); // fire-and-forget async
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => LoginScreen(authService: authService),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Dashboard'),
        actions: [
          _SyncIndicator(storage: authService.storage),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome message
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${authService.currentUser?.name ?? "Manager"}!',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'IAF - Commercial Irrigation',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Price setup prompt
                  if (!authService.storage.hasPricesConfigured)
                    Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Repair item prices not configured',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Set prices in Repair Items before technicians begin inspections.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => RepairItemsScreen(authService: authService),
                                  ),
                                );
                              },
                              child: const Text('Set Prices'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Menu Options - list style matching technician menu
                  Expanded(
                    child: ListView(
                      children: [
                        _MenuCard(
                          icon: Icons.build,
                          title: 'Repair Items',
                          subtitle: 'Configure parts and pricing',
                          color: Colors.blue,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => RepairItemsScreen(authService: authService),
                          )),
                        ),
                        const SizedBox(height: 12),
                        _MenuCard(
                          icon: Icons.home_work,
                          title: 'Properties',
                          subtitle: 'Manage client properties',
                          color: Colors.green,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => PropertiesScreen(authService: authService),
                          )),
                        ),
                        const SizedBox(height: 12),
                        _MenuCard(
                          icon: Icons.calendar_month,
                          title: 'Scheduling',
                          subtitle: 'Assign and schedule inspections',
                          color: Colors.orange,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => MonthlyDashboardScreen(authService: authService),
                          )),
                        ),
                        const SizedBox(height: 12),
                        _MenuCard(
                          icon: Icons.rate_review,
                          title: 'Review Inspections',
                          subtitle: 'Review technician submissions',
                          color: Colors.orange.shade700,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => ReviewInspectionsScreen(authService: authService),
                          )),
                        ),
                        const SizedBox(height: 12),
                        _MenuCard(
                          icon: Icons.check_circle,
                          title: 'Completed',
                          subtitle: 'View completed inspections',
                          color: Colors.purple,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => CompletedInspectionsScreen(authService: authService),
                          )),
                        ),
                        const SizedBox(height: 12),
                        _MenuCard(
                          icon: Icons.history,
                          title: 'History',
                          subtitle: 'Browse inspection history',
                          color: Colors.teal,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => InspectionHistoryScreen(authService: authService),
                          )),
                        ),
                        const SizedBox(height: 12),
                        _MenuCard(
                          icon: Icons.receipt_long,
                          title: 'Quotes',
                          subtitle: 'Manage and send client quotes',
                          color: Colors.pink,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => QuotesListScreen(authService: authService),
                          )),
                        ),
                        const SizedBox(height: 12),
                        _MenuCard(
                          icon: Icons.construction,
                          title: 'Repair Tasks',
                          subtitle: 'Track approved repair work',
                          color: Colors.amber,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => RepairTasksListScreen(authService: authService),
                          )),
                        ),
                        const SizedBox(height: 12),
                        _MenuCard(
                          icon: Icons.people,
                          title: 'Users',
                          subtitle: 'Manage technicians and managers',
                          color: Colors.indigo,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => UsersScreen(authService: authService),
                          )),
                        ),
                        const SizedBox(height: 12),
                        _MenuCard(
                          icon: Icons.assessment,
                          title: 'Reports',
                          subtitle: 'Monthly performance reports',
                          color: Colors.cyan,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => MonthlyReportScreen(authService: authService),
                          )),
                        ),
                        const SizedBox(height: 12),
                        _MenuCard(
                          icon: Icons.restart_alt,
                          title: 'Monthly Reset',
                          subtitle: 'Reset inspections for new month',
                          color: Colors.red,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => MonthlyResetScreen(authService: authService),
                          )),
                        ),
                        const SizedBox(height: 12),
                        _MenuCard(
                          icon: Icons.settings,
                          title: 'Settings',
                          subtitle: 'Company profile and configuration',
                          color: Colors.grey,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => CompanySettingsScreen(authService: authService),
                          )),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SyncIndicator extends StatefulWidget {
  final StorageService storage;
  const _SyncIndicator({Key? key, required this.storage}) : super(key: key);

  @override
  State<_SyncIndicator> createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends State<_SyncIndicator> {
  bool _syncing = false;

  Future<void> _manualSync() async {
    setState(() => _syncing = true);
    try {
      await widget.storage.uploadToFirestore();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data synced to cloud'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.storage.firestoreSyncEnabled;
    return IconButton(
      icon: _syncing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Icon(
              enabled ? Icons.cloud_done : Icons.cloud_off,
              color: enabled ? Colors.white : Colors.white54,
            ),
      tooltip: enabled ? 'Cloud sync enabled (tap to sync now)' : 'Cloud sync disabled',
      onPressed: enabled && !_syncing ? _manualSync : null,
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 32,
            color: color,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
