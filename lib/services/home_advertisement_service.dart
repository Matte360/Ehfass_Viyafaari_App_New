import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';
import '../models/home_advertisement.dart';

class HomeAdvertisementService {
  HomeAdvertisementService._();

  static final HomeAdvertisementService instance = HomeAdvertisementService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _collection = 'home_advertisements';
  static const String _bucket = 'business-media';
  static const Duration _timeout = Duration(seconds: 25);

  Stream<List<HomeAdvertisement>> watchActive() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final advertisements =
          snapshot.docs.map(HomeAdvertisement.fromDocument).toList();

      advertisements.sort((a, b) {
        final order = a.sortOrder.compareTo(b.sortOrder);
        if (order != 0) return order;
        return a.titleEnglish.toLowerCase().compareTo(
              b.titleEnglish.toLowerCase(),
            );
      });

      return advertisements;
    });
  }

  Stream<List<HomeAdvertisement>> watchAll() {
    return _firestore.collection(_collection).snapshots().map((snapshot) {
      final advertisements =
          snapshot.docs.map(HomeAdvertisement.fromDocument).toList();

      advertisements.sort((a, b) {
        if (a.isActive != b.isActive) {
          return a.isActive ? -1 : 1;
        }
        final order = a.sortOrder.compareTo(b.sortOrder);
        if (order != 0) return order;
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      return advertisements;
    });
  }

  Future<void> createAdvertisement({
    required AppUser admin,
    required String titleEnglish,
    required String titleDhivehi,
    required String descriptionEnglish,
    required String descriptionDhivehi,
    required bool isActive,
    required int sortOrder,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null || currentUser.uid != admin.uid) {
      throw StateError('You must be logged in as admin.');
    }

    final reference = _firestore.collection(_collection).doc();

    if (imageBytes == null || imageFileName == null) {
      throw StateError(
          'Choose a banner image before creating the advertisement.');
    }

    final upload = await _uploadImage(
      adId: reference.id,
      imageBytes: imageBytes,
      imageFileName: imageFileName,
    );

    if (upload.imageUrl.trim().isEmpty) {
      throw StateError(
          'Image upload finished but Supabase did not return a public URL.');
    }

    final imageUrl = upload.imageUrl;
    final storagePath = upload.storagePath;

    await reference.set({
      'titleEnglish': titleEnglish.trim(),
      'titleDhivehi': titleDhivehi.trim(),
      'descriptionEnglish': descriptionEnglish.trim(),
      'descriptionDhivehi': descriptionDhivehi.trim(),
      'imageUrl': imageUrl,
      'storagePath': storagePath,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'createdBy': admin.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }).timeout(_timeout);
  }

  Future<void> updateActive({
    required String advertisementId,
    required bool isActive,
  }) async {
    await _firestore.collection(_collection).doc(advertisementId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    }).timeout(_timeout);
  }

  Future<void> deleteAdvertisement(HomeAdvertisement advertisement) async {
    await _firestore
        .collection(_collection)
        .doc(advertisement.id)
        .delete()
        .timeout(_timeout);

    if (advertisement.storagePath.isNotEmpty) {
      try {
        await _supabase.storage
            .from(_bucket)
            .remove([advertisement.storagePath]).timeout(_timeout);
      } catch (_) {
        // The Firestore record is already removed. Ignore storage cleanup errors.
      }
    }
  }

  Future<_HomeAdUpload> _uploadImage({
    required String adId,
    required Uint8List imageBytes,
    required String imageFileName,
  }) async {
    if (imageBytes.isEmpty) {
      throw StateError('Selected image is empty.');
    }

    if (imageBytes.lengthInBytes > 5 * 1024 * 1024) {
      throw StateError('Advertisement image must be smaller than 5 MB.');
    }

    final imageType = _getImageType(imageFileName);
    final storagePath = 'admin_ads/$adId.${imageType.extension}';

    try {
      await _supabase.storage
          .from(_bucket)
          .uploadBinary(
            storagePath,
            imageBytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              contentType: imageType.contentType,
              upsert: true,
            ),
          )
          .timeout(_timeout);

      return _HomeAdUpload(
        imageUrl: _supabase.storage.from(_bucket).getPublicUrl(storagePath),
        storagePath: storagePath,
      );
    } on TimeoutException {
      throw StateError('Advertisement image upload took too long.');
    } on StorageException catch (error) {
      throw StateError('Supabase upload failed: ${error.message}');
    }
  }

  _HomeAdImageType _getImageType(String fileName) {
    final lowerName = fileName.trim().toLowerCase();

    if (lowerName.endsWith('.png')) {
      return const _HomeAdImageType('png', 'image/png');
    }

    if (lowerName.endsWith('.webp')) {
      return const _HomeAdImageType('webp', 'image/webp');
    }

    if (lowerName.endsWith('.jpeg')) {
      return const _HomeAdImageType('jpeg', 'image/jpeg');
    }

    if (lowerName.endsWith('.jpg')) {
      return const _HomeAdImageType('jpg', 'image/jpeg');
    }

    throw StateError('Use JPG, JPEG, PNG, or WEBP image.');
  }
}

class _HomeAdUpload {
  const _HomeAdUpload({
    required this.imageUrl,
    required this.storagePath,
  });

  final String imageUrl;
  final String storagePath;
}

class _HomeAdImageType {
  const _HomeAdImageType(this.extension, this.contentType);

  final String extension;
  final String contentType;
}
