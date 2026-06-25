import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.businessId,
    required this.orderId,
    required this.quotationId,
    required this.chatThreadId,
    required this.read,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final String businessId;
  final String orderId;
  final String quotationId;
  final String chatThreadId;
  final bool read;
  final DateTime? createdAt;

  factory AppNotification.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};
    final createdAt = data['createdAt'];
    return AppNotification(
      id: document.id,
      userId: data['userId']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      body: data['body']?.toString() ?? '',
      type: data['type']?.toString() ?? '',
      businessId: data['businessId']?.toString() ?? '',
      orderId: data['orderId']?.toString() ?? '',
      quotationId: data['quotationId']?.toString() ?? '',
      chatThreadId: data['chatThreadId']?.toString() ?? '',
      read: data['read'] == true,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}
