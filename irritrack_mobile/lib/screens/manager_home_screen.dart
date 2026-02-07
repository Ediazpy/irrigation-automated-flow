import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/announcement_banner.dart';
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
import 'technician/my_inspections_screen.dart';
import 'technician/start_inspection_screen.dart';
import 'technician/create_walk_screen.dart';
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
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Announcement banner at the top
            const AnnouncementBanner(),
            Expanded(
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
                                  'IAF - Commercial Irrigation Manager',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Menu Options
                        Expanded(
                          child: ListView(
                            children: [
                              // Field Work Section
                              _SectionHeader(title: 'Field Work'),
                              _MenuCard(
                                icon: Icons.assignment_outlined,
                                title: 'My Assigned Inspections',
                                subtitle: 'View inspections assigned to you',
                                color: Colors.blue,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => MyInspectionsScreen(authService: authService),
                                    ),
                                  );
                                },
                              ),
                              _MenuCard(
                                icon: Icons.play_arrow,
                                title: 'Start/Continue Inspection',
                                subtitle: 'Walk properties assigned to you',
                                color: Colors.green,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => StartInspectionScreen(authService: authService),
                                    ),
                                  );
                                },
                              ),
                              _MenuCard(
                                icon: Icons.add_location_alt,
                                title: 'New Property Inspection',
                                subtitle: 'Create property and start inspection',
                                color: Colors.orange,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => CreateWalkScreen(authService: authService),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 16),

                              // Management Section
                              _SectionHeader(title: 'Management'),
                              _MenuCard(
                                icon: Icons.home_work,
                                title: 'Properties',
                                subtitle: 'Manage all properties',
                                color: Colors.teal,
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
                                subtitle: 'Monthly inspection calendar',
                                color: Colors.deepOrange,
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
                                title: 'Review Inspections',
                                subtitle: 'Review submitted inspections',
                                color: Colors.amber.shade700,
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
                                title: 'Completed Inspections',
                                subtitle: 'View all completed inspections',
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
                                title: 'Inspection History',
                                subtitle: 'Historical inspection records',
                                color: Colors.blueGrey,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => InspectionHistoryScreen(authService: authService),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 16),

                              // Quotes & Repairs Section
                              _SectionHeader(title: 'Quotes & Repairs'),
                              _MenuCard(
                                icon: Icons.receipt_long,
                                title: 'Quotes',
                                subtitle: 'Manage customer quotes',
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
                                subtitle: 'Manage approved repair tasks',
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
                                icon: Icons.build,
                                title: 'Repair Items & Pricing',
                                subtitle: 'Configure repair item prices',
                                color: Colors.indigo,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => RepairItemsScreen(authService: authService),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 16),

                              // Administration Section
                              _SectionHeader(title: 'Administration'),
                              _MenuCard(
                                icon: Icons.people,
                                title: 'Users',
                                subtitle: 'Manage technicians and users',
                                color: Colors.cyan,
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
                                subtitle: 'Generate monthly reports',
                                color: Colors.lightBlue,
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
                                subtitle: 'Reset for new month cycle',
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
                                icon: Icons.settings,
                                title: 'Company Settings',
                                subtitle: 'Configure company information',
                                color: Colors.grey.shade700,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => CompanySettingsScreen(authService: authService),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
      ),
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
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 28,
            color: color,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
