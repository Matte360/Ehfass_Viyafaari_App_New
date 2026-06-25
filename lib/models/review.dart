import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessReview {
  const BusinessReview({
    required this.id,
    required this.businessId,
    required this.clientId,
    required this.clientName,
    required this.orderId,
    required this.rating,
    required this.comment,
    required this.active,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String businessId;
  final String clientId;
  final String clientName;
  final String orderId;
  final int rating;
  final String comment;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory BusinessReview.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};

    DateTime? readDate(Object? value) {
      return value is Timestamp ? value.toDate() : null;
    }

    int readInt(Object? value) {
      return value is num
          ? value.toInt()
          : int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return BusinessReview(
      id: document.id,
      businessId: data['businessId']?.toString() ?? '',
      clientId: data['clientId']?.toString() ?? '',
      clientName: data['clientName']?.toString() ?? '',
      orderId: data['orderId']?.toString() ?? '',
      rating: readInt(data['rating']).clamp(0, 5).toInt(),
      comment: data['comment']?.toString() ?? '',
      active: data['active'] != false,
      createdAt: readDate(data['createdAt']),
      updatedAt: readDate(data['updatedAt']),
    );
  }
}

class ReviewSummary {
  const ReviewSummary({
    required this.count,
    required this.averageRating,
  });

  final int count;
  final double averageRating;

  String get ratingText => count == 0
      ? 'No reviews yet'
      : '${averageRating.toStringAsFixed(1)} ★ ($count)';
}
