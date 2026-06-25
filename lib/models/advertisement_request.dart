import 'package:cloud_firestore/cloud_firestore.dart';

class AdvertisementRequestModel {
  const AdvertisementRequestModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.businessName,
    required this.title,
    required this.contactNumber,
    required this.duration,
    required this.details,
    required this.status,
    required this.rejectionReason,
    this.submittedAt,
  });

  final String id;
  final String ownerId;
  final String ownerName;
  final String businessName;
  final String title;
  final String contactNumber;
  final String duration;
  final String details;
  final String status;
  final String rejectionReason;
  final DateTime? submittedAt;

  factory AdvertisementRequestModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};
    final submittedAt = data['submittedAt'];

    return AdvertisementRequestModel(
      id: document.id,
      ownerId: data['ownerId']?.toString() ?? '',
      ownerName: data['ownerName']?.toString() ?? '',
      businessName: data['businessName']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      contactNumber: data['contactNumber']?.toString() ?? '',
      duration: data['duration']?.toString() ?? '',
      details: data['details']?.toString() ?? '',
      status: data['status']?.toString() ?? 'pending',
      rejectionReason: data['rejectionReason']?.toString() ?? '',
      submittedAt:
          submittedAt is Timestamp ? submittedAt.toDate() : null,
    );
  }
}
