import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseMediaService {
  SupabaseMediaService._();

  static final SupabaseMediaService instance = SupabaseMediaService._();

  static const String bucketName = 'business-media';

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<String> uploadBusinessImage({
    required Uint8List imageBytes,
    required String ownerUid,
    required String originalFileName,
  }) async {
    if (imageBytes.isEmpty) {
      throw Exception('The selected image is empty.');
    }

    if (imageBytes.length > 5 * 1024 * 1024) {
      throw Exception('The image must be smaller than 5 MB.');
    }

    final extension = _fileExtension(originalFileName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final safeOwnerUid = ownerUid.replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );

    final storagePath =
        'businesses/$safeOwnerUid/business_$timestamp.$extension';

    await _supabase.storage.from(bucketName).uploadBinary(
          storagePath,
          imageBytes,
          fileOptions: FileOptions(
            cacheControl: '3600',
            upsert: false,
            contentType: _contentType(extension),
          ),
        );

    return _supabase.storage.from(bucketName).getPublicUrl(storagePath);
  }


  Future<String> uploadUserProfileImage({
    required Uint8List imageBytes,
    required String userUid,
    required String originalFileName,
  }) async {
    if (imageBytes.isEmpty) {
      throw Exception('The selected image is empty.');
    }

    if (imageBytes.length > 5 * 1024 * 1024) {
      throw Exception('The image must be smaller than 5 MB.');
    }

    final extension = _fileExtension(originalFileName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final safeUserUid = userUid.replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );

    final storagePath =
        'profiles/$safeUserUid/profile_$timestamp.$extension';

    await _supabase.storage.from(bucketName).uploadBinary(
          storagePath,
          imageBytes,
          fileOptions: FileOptions(
            cacheControl: '3600',
            upsert: false,
            contentType: _contentType(extension),
          ),
        );

    return _supabase.storage.from(bucketName).getPublicUrl(storagePath);
  }

  String _fileExtension(String fileName) {
    final parts = fileName.toLowerCase().split('.');

    if (parts.length < 2) {
      return 'jpg';
    }

    final extension = parts.last;

    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
        return extension;
      default:
        return 'jpg';
    }
  }

  String _contentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpeg':
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }
}
