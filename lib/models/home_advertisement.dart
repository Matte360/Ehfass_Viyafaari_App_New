import 'package:cloud_firestore/cloud_firestore.dart';

class HomeAdvertisement {
  const HomeAdvertisement({
    required this.id,
    required this.titleEnglish,
    required this.titleDhivehi,
    required this.descriptionEnglish,
    required this.descriptionDhivehi,
    required this.imageUrl,
    required this.storagePath,
    required this.isActive,
    required this.sortOrder,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String titleEnglish;
  final String titleDhivehi;
  final String descriptionEnglish;
  final String descriptionDhivehi;
  final String imageUrl;
  final String storagePath;
  final bool isActive;
  final int sortOrder;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory HomeAdvertisement.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};

    DateTime? readDate(String key) {
      final value = data[key];
      if (value is Timestamp) return value.toDate();
      return null;
    }

    return HomeAdvertisement(
      id: document.id,
      titleEnglish: (data['titleEnglish'] ?? '').toString(),
      titleDhivehi: (data['titleDhivehi'] ?? '').toString(),
      descriptionEnglish: (data['descriptionEnglish'] ?? '').toString(),
      descriptionDhivehi: (data['descriptionDhivehi'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      storagePath: (data['storagePath'] ?? '').toString(),
      isActive: data['isActive'] == true,
      sortOrder: (data['sortOrder'] is int) ? data['sortOrder'] as int : 0,
      createdBy: (data['createdBy'] ?? '').toString(),
      createdAt: readDate('createdAt'),
      updatedAt: readDate('updatedAt'),
    );
  }
}
