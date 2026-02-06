import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/announcement.dart';

class AnnouncementService {
  static const String _dismissedKey = 'dismissed_announcements';
  static const String _collectionName = 'announcements';

  /// Fetch active announcements from Firestore
  static Future<List<Announcement>> fetchAnnouncements() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(_collectionName)
          .orderBy('created_at', descending: true)
          .limit(10)
          .get();

      final now = DateTime.now();
      final announcements = <Announcement>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final announcement = Announcement.fromJson(data);

        // Skip expired announcements
        if (!announcement.isExpired) {
          announcements.add(announcement);
        }
      }

      return announcements;
    } catch (e) {
      print('Error fetching announcements: $e');
      return [];
    }
  }

  /// Get list of dismissed announcement IDs
  static Future<Set<String>> getDismissedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getStringList(_dismissedKey) ?? [];
    return dismissed.toSet();
  }

  /// Mark an announcement as dismissed
  static Future<void> dismissAnnouncement(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getStringList(_dismissedKey) ?? [];
    if (!dismissed.contains(id)) {
      dismissed.add(id);
      await prefs.setStringList(_dismissedKey, dismissed);
    }
  }

  /// Get active announcements that haven't been dismissed
  static Future<List<Announcement>> getActiveAnnouncements() async {
    final announcements = await fetchAnnouncements();
    final dismissedIds = await getDismissedIds();

    return announcements
        .where((a) => !dismissedIds.contains(a.id))
        .toList();
  }

  /// Clear all dismissed announcements (for testing/reset)
  static Future<void> clearDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dismissedKey);
  }

  /// Stream of announcements (for real-time updates)
  static Stream<List<Announcement>> announcementsStream() {
    return FirebaseFirestore.instance
        .collection(_collectionName)
        .orderBy('created_at', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      final announcements = <Announcement>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final announcement = Announcement.fromJson(data);
        if (!announcement.isExpired) {
          announcements.add(announcement);
        }
      }
      return announcements;
    });
  }
}
