import 'package:cloud_firestore/cloud_firestore.dart';

class PromotionRequestModel {
  const PromotionRequestModel({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.sellerId,
    required this.plan,
    required this.note,
    required this.status,
    required this.rejectionReason,
    this.createdAt,
    this.reviewedAt,
  });

  final String id;
  final String businessId;
  final String businessName;
  final String sellerId;
  final String plan;
  final String note;
  final String status;
  final String rejectionReason;
  final DateTime? createdAt;
  final DateTime? reviewedAt;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  String get planLabel {
    switch (plan) {
      case 'featured_shop':
        return 'Featured Shop';
      case 'sponsored_shop':
        return 'Sponsored Shop';
      case 'verified_badge':
        return 'Verified Badge';
      default:
        return 'Promotion';
    }
  }

  factory PromotionRequestModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};

    DateTime? readDate(Object? value) {
      return value is Timestamp ? value.toDate() : null;
    }

    return PromotionRequestModel(
      id: document.id,
      businessId: data['businessId']?.toString() ?? '',
      businessName: data['businessName']?.toString() ?? '',
      sellerId: data['sellerId']?.toString() ?? '',
      plan: data['plan']?.toString() ?? 'featured_shop',
      note: data['note']?.toString() ?? '',
      status: data['status']?.toString() ?? 'pending',
      rejectionReason: data['rejectionReason']?.toString() ?? '',
      createdAt: readDate(data['createdAt']),
      reviewedAt: readDate(data['reviewedAt']),
    );
  }
}
