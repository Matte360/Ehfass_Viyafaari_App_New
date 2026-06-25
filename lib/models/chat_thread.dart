import 'package:cloud_firestore/cloud_firestore.dart';

class ChatThread {
  const ChatThread({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.businessUserId,
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    required this.clientPhone,
    required this.itemId,
    required this.itemName,
    required this.lastMessage,
    required this.lastSenderId,
    required this.unreadForClient,
    required this.unreadForBusiness,
    this.createdAt,
    this.lastMessageAt,
  });

  final String id;
  final String businessId;
  final String businessName;
  final String businessUserId;
  final String clientId;
  final String clientName;
  final String clientEmail;
  final String clientPhone;
  final String itemId;
  final String itemName;
  final String lastMessage;
  final String lastSenderId;
  final bool unreadForClient;
  final bool unreadForBusiness;
  final DateTime? createdAt;
  final DateTime? lastMessageAt;

  factory ChatThread.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};

    DateTime? readDate(Object? value) {
      return value is Timestamp ? value.toDate() : null;
    }

    return ChatThread(
      id: document.id,
      businessId: data['businessId']?.toString() ?? '',
      businessName: data['businessName']?.toString() ?? '',
      businessUserId: data['businessUserId']?.toString() ?? '',
      clientId: data['clientId']?.toString() ?? '',
      clientName: data['clientName']?.toString() ?? '',
      clientEmail: data['clientEmail']?.toString() ?? '',
      clientPhone: data['clientPhone']?.toString() ?? '',
      itemId: data['itemId']?.toString() ?? '',
      itemName: data['itemName']?.toString() ?? '',
      lastMessage: data['lastMessage']?.toString() ?? '',
      lastSenderId: data['lastSenderId']?.toString() ?? '',
      unreadForClient: data['unreadForClient'] == true,
      unreadForBusiness: data['unreadForBusiness'] == true,
      createdAt: readDate(data['createdAt']),
      lastMessageAt: readDate(data['lastMessageAt']),
    );
  }
}
