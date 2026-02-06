import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

/// Service for uploading photos to Firebase Storage instead of storing
/// base64 strings directly in Firestore documents.
///
/// This prevents hitting the 1MB Firestore document size limit and
/// improves app performance by not loading large base64 strings into memory.
class PhotoStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a photo (as bytes) to Firebase Storage and return the download URL.
  /// Photos are stored at: inspections/{inspectionId}/zone_{zoneNumber}/{timestamp}.jpg
  static Future<String> uploadInspectionPhoto({
    required int inspectionId,
    required int zoneNumber,
    required Uint8List photoBytes,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'inspections/$inspectionId/zone_$zoneNumber/$timestamp.jpg';

    final ref = _storage.ref().child(path);
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {
        'inspectionId': inspectionId.toString(),
        'zoneNumber': zoneNumber.toString(),
      },
    );

    await ref.putData(photoBytes, metadata);
    final downloadUrl = await ref.getDownloadURL();
    return downloadUrl;
  }

  /// Upload a base64-encoded photo and return the download URL.
  /// Convenience wrapper for migrating existing base64 photos.
  static Future<String> uploadBase64Photo({
    required int inspectionId,
    required int zoneNumber,
    required String base64Photo,
  }) async {
    final bytes = base64Decode(base64Photo);
    return uploadInspectionPhoto(
      inspectionId: inspectionId,
      zoneNumber: zoneNumber,
      photoBytes: Uint8List.fromList(bytes),
    );
  }

  /// Delete a photo from Firebase Storage by its download URL.
  static Future<void> deletePhoto(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting photo from storage: $e');
    }
  }

  /// Delete all photos for an inspection.
  static Future<void> deleteInspectionPhotos(int inspectionId) async {
    try {
      final ref = _storage.ref().child('inspections/$inspectionId');
      final result = await ref.listAll();
      for (var prefix in result.prefixes) {
        final zoneResult = await prefix.listAll();
        for (var item in zoneResult.items) {
          await item.delete();
        }
      }
    } catch (e) {
      print('Error deleting inspection photos: $e');
    }
  }

  /// Check if a string is a Firebase Storage URL (vs base64 data).
  static bool isStorageUrl(String value) {
    return value.startsWith('https://') || value.startsWith('gs://');
  }

  /// Upload a signature image to Firebase Storage.
  static Future<String> uploadSignature({
    required int quoteId,
    required Uint8List signatureBytes,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'signatures/$quoteId/$timestamp.png';

    final ref = _storage.ref().child(path);
    final metadata = SettableMetadata(
      contentType: 'image/png',
      customMetadata: {
        'quoteId': quoteId.toString(),
      },
    );

    await ref.putData(signatureBytes, metadata);
    return await ref.getDownloadURL();
  }
}
