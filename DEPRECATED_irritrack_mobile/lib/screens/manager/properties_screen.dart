import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'create_property_screen.dart';
import 'edit_property_screen.dart';

class PropertiesScreen extends StatefulWidget {
  final AuthService authService;

  const PropertiesScreen({Key? key, required this.authService}) : super(key: key);

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  @override
  Widget build(BuildContext context) {
    final storage = widget.authService.storage;
    final properties = storage.properties.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Properties'),
      ),
      body: properties.isEmpty
          ? const Center(
              child: Text('No properties found.\nTap + to create one.'),
            )
          : ListView.builder(
              itemCount: properties.length,
              itemBuilder: (context, index) {
                final prop = properties[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ExpansionTile(
                    leading: const Icon(Icons.home_work),
                    title: Text(prop.address),
                    subtitle: Text('${prop.zones.length} zones'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditPropertyScreen(
                              authService: widget.authService,
                              property: prop,
                            ),
                          ),
                        );
                        if (result == true) {
                          setState(() {});
                        }
                      },
                      tooltip: 'Edit Property',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ID: ${prop.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('Meter: ${prop.meterLocation}'),
                            Text('Backflow: ${prop.backflowSize}" at ${prop.backflowLocation}'),
                            Text('Serial: ${prop.backflowSerial}'),
                            Text('Controllers: ${prop.numControllers} at ${prop.controllerLocation}'),
                            const Divider(height: 24),
                            const Text('Zones:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ...prop.zones.map((zone) => Padding(
                                  padding: const EdgeInsets.only(left: 16, top: 4),
                                  child: Text(
                                    'Zone ${zone.zoneNumber}: ${zone.description} - ${zone.headType}${zone.headCount != null ? " (${zone.headCount})" : ""}',
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreatePropertyScreen(authService: widget.authService),
            ),
          );
          if (result == true) {
            setState(() {});
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
