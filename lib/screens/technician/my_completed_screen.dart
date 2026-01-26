import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class MyCompletedScreen extends StatelessWidget {
  final AuthService authService;

  const MyCompletedScreen({Key? key, required this.authService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final storage = authService.storage;
    final myEmail = authService.currentUser?.email;
    final completedInspections = storage.inspections.values
        .where((i) => i.technician == myEmail && i.status == 'completed')
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('My Completed Inspections')),
      body: completedInspections.isEmpty
          ? const Center(child: Text('No completed inspections'))
          : ListView.builder(
              itemCount: completedInspections.length,
              itemBuilder: (context, index) {
                final insp = completedInspections[index];
                final prop = storage.properties[insp.propertyId];

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(prop?.address ?? 'Unknown Property'),
                    subtitle: Text('${insp.date} - ${insp.repairs.length + insp.otherRepairs.length} repairs'),
                  ),
                );
              },
            ),
    );
  }
}
