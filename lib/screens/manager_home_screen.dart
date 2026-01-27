import 'package:flutter/material.dart';
import '../services/auth_service.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    // Responsive columns: 2 on mobile, 3 on tablet, 4 on desktop/web
    final crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);
    // Keep cards compact - max width ~160px per card
    final childAspectRatio = screenWidth > 600 ? 1.2 : 1.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Dashboard'),
        actions: [
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
            constraints: const BoxConstraints(maxWidth: 900),
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
                  const SizedBox(height: 24),

                  // Menu Options
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: childAspectRatio,
                      children: [
                    _MenuCard(
                      icon: Icons.build,
                      title: 'Repair Items',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => RepairItemsScreen(authService: authService),
                          ),
                        );
                      },
                    ),
                    _MenuCard(
                      icon: Icons.home_work,
                      title: 'Properties',
                      color: Colors.green,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PropertiesScreen(authService: authService),
                          ),
                        );
                      },
                    ),
                    _MenuCard(
                      icon: Icons.calendar_month,
                      title: 'Scheduling',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => MonthlyDashboardScreen(authService: authService),
                          ),
                        );
                      },
                    ),
                    _MenuCard(
                      icon: Icons.rate_review,
                      title: 'Review',
                      color: Colors.orange.shade700,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ReviewInspectionsScreen(authService: authService),
                          ),
                        );
                      },
                    ),
                    _MenuCard(
                      icon: Icons.check_circle,
                      title: 'Completed',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CompletedInspectionsScreen(authService: authService),
                          ),
                        );
                      },
                    ),
                    _MenuCard(
                      icon: Icons.history,
                      title: 'History',
                      color: Colors.teal,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => InspectionHistoryScreen(authService: authService),
                          ),
                        );
                      },
                    ),
                    _MenuCard(
                      icon: Icons.people,
                      title: 'Users',
                      color: Colors.indigo,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => UsersScreen(authService: authService),
                          ),
                        );
                      },
                    ),
                    _MenuCard(
                      icon: Icons.assessment,
                      title: 'Reports',
                      color: Colors.cyan,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => MonthlyReportScreen(authService: authService),
                          ),
                        );
                      },
                    ),
                    _MenuCard(
                      icon: Icons.restart_alt,
                      title: 'Monthly Reset',
                      color: Colors.red,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => MonthlyResetScreen(authService: authService),
                          ),
                        );
                      },
                    ),
                    _MenuCard(
                      icon: Icons.receipt_long,
                      title: 'Quotes',
                      color: Colors.pink,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => QuotesListScreen(authService: authService),
                          ),
                        );
                      },
                    ),
                    _MenuCard(
                      icon: Icons.construction,
                      title: 'Repair Tasks',
                      color: Colors.amber,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => RepairTasksListScreen(authService: authService),
                          ),
                        );
                      },
                    ),
                    _MenuCard(
                      icon: Icons.settings,
                      title: 'Settings',
                      color: Colors.grey,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CompanySettingsScreen(authService: authService),
                          ),
                        );
                      },
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

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isWide ? 12 : 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: isWide ? 32 : 40,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isWide ? 13 : 15,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
