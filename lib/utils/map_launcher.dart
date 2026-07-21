import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Open an address in the user's preferred maps app.
///
/// First use asks Google Maps vs Apple Maps and remembers the choice on this
/// device. No API key needed — these are plain map URLs.
Future<void> openAddressInMaps(BuildContext context, String address) async {
  if (address.trim().isEmpty) return;

  final prefs = await SharedPreferences.getInstance();
  String? choice = prefs.getString('iaf_maps_app');

  if (choice == null) {
    if (!context.mounted) return;
    choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open with'),
        content: const Text(
            'Which maps app do you prefer? We\'ll remember this choice — '
            'you can change it later from the same button by long-pressing.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'apple'),
            child: const Text('Apple Maps'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'google'),
            child: const Text('Google Maps'),
          ),
        ],
      ),
    );
    if (choice == null) return;
    await prefs.setString('iaf_maps_app', choice);
  }

  final q = Uri.encodeComponent(address.trim());
  final url = choice == 'apple'
      ? 'https://maps.apple.com/?q=$q'
      : 'https://www.google.com/maps/search/?api=1&query=$q';

  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Forget the stored maps choice so the picker shows again.
Future<void> resetMapsPreference() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('iaf_maps_app');
}

/// A small navigate button to place next to any address.
class OpenInMapsButton extends StatelessWidget {
  final String address;

  const OpenInMapsButton({Key? key, required this.address}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Long-press re-asks Google vs Apple
      onLongPress: () async {
        await resetMapsPreference();
        if (context.mounted) {
          await openAddressInMaps(context, address);
        }
      },
      child: IconButton(
        icon: const Icon(Icons.directions, color: Color(0xFF0EA5E9)),
        tooltip: 'Open in Maps (long-press to change app)',
        onPressed: () => openAddressInMaps(context, address),
      ),
    );
  }
}
