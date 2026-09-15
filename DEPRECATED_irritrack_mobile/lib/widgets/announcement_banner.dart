import 'package:flutter/material.dart';
import '../models/announcement.dart';
import '../services/announcement_service.dart';

/// A dismissible banner that shows announcements from the dev team
class AnnouncementBanner extends StatefulWidget {
  const AnnouncementBanner({Key? key}) : super(key: key);

  @override
  State<AnnouncementBanner> createState() => _AnnouncementBannerState();
}

class _AnnouncementBannerState extends State<AnnouncementBanner> {
  List<Announcement> _announcements = [];
  Set<String> _dismissedIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    try {
      final announcements = await AnnouncementService.fetchAnnouncements();
      final dismissedIds = await AnnouncementService.getDismissedIds();
      if (mounted) {
        setState(() {
          _announcements = announcements;
          _dismissedIds = dismissedIds;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _dismissAnnouncement(String id) {
    AnnouncementService.dismissAnnouncement(id);
    setState(() {
      _dismissedIds.add(id);
    });
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'info':
      default:
        return Colors.blue;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'urgent':
        return Icons.error;
      case 'warning':
        return Icons.warning;
      case 'info':
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox.shrink();
    }

    // Filter out dismissed announcements
    final activeAnnouncements = _announcements
        .where((a) => !_dismissedIds.contains(a.id))
        .toList();

    if (activeAnnouncements.isEmpty) {
      return const SizedBox.shrink();
    }

    // Show only the most recent/highest priority announcement
    final announcement = activeAnnouncements.first;
    final color = _getPriorityColor(announcement.priority);
    final icon = _getPriorityIcon(announcement.priority);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: color.withOpacity(0.3), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (announcement.title.isNotEmpty)
                  Text(
                    announcement.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color.shade700,
                      fontSize: 13,
                    ),
                  ),
                Text(
                  announcement.message,
                  style: TextStyle(
                    color: color.shade700,
                    fontSize: 12,
                  ),
                ),
                if (activeAnnouncements.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+${activeAnnouncements.length - 1} more announcement(s)',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (announcement.dismissible)
            GestureDetector(
              onTap: () => _dismissAnnouncement(announcement.id),
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.close,
                  color: color.shade600,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Extension to get shade colors
extension ColorShade on Color {
  Color get shade600 => HSLColor.fromColor(this).withLightness(0.4).toColor();
  Color get shade700 => HSLColor.fromColor(this).withLightness(0.35).toColor();
}
