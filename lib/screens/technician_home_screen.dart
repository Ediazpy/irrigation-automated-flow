import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'technician/my_inspections_screen.dart';
import 'technician/start_inspection_screen.dart';
import 'technician/create_walk_screen.dart';
import 'technician/my_completed_screen.dart';
import 'technician/repair_tasks_screen.dart';
import 'login_screen.dart';

class TechnicianHomeScreen extends StatelessWidget {
  final AuthService authService;

  const TechnicianHomeScreen({Key? key, required this.authService}) : super(key: key);

  void _logout(BuildContext context) {
    authService.logout();
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
        title: const Text('Technician Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
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
                        'Welcome, ${authService.currentUser?.name ?? "Technician"}!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Field Service Technician',
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
                child: ListView(
                  children: [
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
                    const SizedBox(height: 12),
                    _MenuCard(
                      icon: Icons.play_arrow,
                      title: 'Start/Continue Inspection',
                      subtitle: 'Work on assigned inspections',
                      color: Colors.green,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => StartInspectionScreen(authService: authService),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 12),
                    _MenuCard(
                      icon: Icons.check_circle_outline,
                      title: 'My Completed Inspections',
                      subtitle: 'View your completed work',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => MyCompletedScreen(authService: authService),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _MenuCard(
                      icon: Icons.construction,
                      title: 'Repair Tasks',
                      subtitle: 'Approved repairs ready to complete',
                      color: Colors.amber,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => RepairTasksScreen(authService: authService),
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
