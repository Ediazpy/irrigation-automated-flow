import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'do_inspection_screen.dart';

class StartInspectionScreen extends StatelessWidget {
  final AuthService authService;

  const StartInspectionScreen({Key? key, required this.authService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final storage = authService.storage;
    final myEmail = authService.currentUser?.email;
    final myInspections = storage.inspections.entries
        .where((e) => e.value.technicians.contains(myEmail) && e.value.status != 'completed')
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Start/Continue Inspection')),
      body: myInspections.isEmpty
          ? const Center(child: Text('No inspections to work on'))
          : ListView.builder(
              itemCount: myInspections.length,
              itemBuilder: (context, index) {
                final entry = myInspections[index];
                final insp = entry.value;
                final prop = storage.properties[insp.propertyId];

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(prop?.address ?? 'Unknown Property'),
                    subtitle: Text('${insp.date} - ${insp.status}'),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      // Update status to in_progress
                      storage.inspections[entry.key] = insp.copyWith(status: 'in_progress');
                      storage.saveData();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DoInspectionScreen(
                            authService: authService,
                            inspectionId: entry.key,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
