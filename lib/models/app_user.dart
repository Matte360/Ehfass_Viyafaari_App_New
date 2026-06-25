import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.fullName,
    required this.username,
    required this.phone,
    required this.email,
    required this.role,
    this.businessId = '',
    this.businessName = '',
    this.profileImageUrl = '',
    this.createdAt,
  });

  final String uid;
  final String fullName;
  final String username;
  final String phone;
  final String email;
  final String role;
  final String businessId;
  final String businessName;
  final String profileImageUrl;
  final DateTime? createdAt;

  bool get isAdmin => role == 'admin';
  bool get isBusiness => role == 'business';
  bool get isClient => role == 'client';

  factory AppUser.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};
    final timestamp = data['createdAt'];

    return AppUser(
      uid: document.id,
      fullName: data['fullName']?.toString() ?? 'User',
      username: data['username']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      role: data['role']?.toString() ?? 'client',
      businessId: data['businessId']?.toString() ?? '',
      businessName: data['businessName']?.toString() ?? '',
      profileImageUrl: data['profileImageUrl']?.toString() ?? '',
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}
