import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/photo_storage_service.dart';

/// Widget that displays a photo from either a Firebase Storage URL
/// or a base64-encoded string (backwards compatibility).
class PhotoImage extends StatelessWidget {
  final String photoData;
  final BoxFit fit;
  final double? width;
  final double? height;

  const PhotoImage({
    Key? key,
    required this.photoData,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (PhotoStorageService.isStorageUrl(photoData)) {
      return Image.network(
        photoData,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    } else {
      // Base64 fallback (legacy photos or offline captures)
      try {
        return Image.memory(
          base64Decode(photoData),
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: width,
              height: height,
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
          },
        );
      } catch (e) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
      }
    }
  }
}

/// ImageProvider that works with both URLs and base64 strings.
ImageProvider photoImageProvider(String photoData) {
  if (PhotoStorageService.isStorageUrl(photoData)) {
    return NetworkImage(photoData);
  } else {
    return MemoryImage(base64Decode(photoData));
  }
}
