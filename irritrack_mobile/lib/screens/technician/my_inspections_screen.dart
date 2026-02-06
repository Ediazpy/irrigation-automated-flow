import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class MyInspectionsScreen extends StatelessWidget {
  final AuthService authService;

  const MyInspectionsScreen({Key? key, required this.authService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final storage = authService.storage;
    final myEmail = authService.currentUser?.email;
    final myInspections = storage.inspections.values
        .where((i) => i.technicians.contains(myEmail) && i.status != 'completed')
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('My Assigned Inspections')),
      body: myInspections.isEmpty
          ? const Center(child: Text('No assigned inspections'))
          : ListView.builder(
              itemCount: myInspections.length,
              itemBuilder: (context, index) {
                final insp = myInspections[index];
                final prop = storage.properties[insp.propertyId];

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: Icon(
                      insp.status == 'in_progress' ? Icons.pending : Icons.assignment,
                      color: insp.status == 'in_progress' ? Colors.orange : Colors.blue,
                    ),
                    title: Text(prop?.address ?? 'Unknown Property'),
                    subtitle: Text('${insp.date} - ${insp.status}'),
                    trailing: Chip(label: Text(insp.status)),
                  ),
                );
              },
            ),
    );
  }
}
