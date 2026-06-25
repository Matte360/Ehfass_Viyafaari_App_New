import 'package:cloud_firestore/cloud_firestore.dart';

class ClientCoupon {
  const ClientCoupon({
    required this.id,
    required this.code,
    required this.businessId,
    required this.businessName,
    required this.clientId,
    required this.clientName,
    required this.orderId,
    required this.itemName,
    required this.purchaseTotalMvr,
    required this.minimumSpendMvr,
    required this.rewardMvr,
    required this.title,
    required this.terms,
    required this.redeemed,
    this.createdAt,
    this.redeemedAt,
  });

  final String id;
  final String code;
  final String businessId;
  final String businessName;
  final String clientId;
  final String clientName;
  final String orderId;
  final String itemName;
  final double purchaseTotalMvr;
  final double minimumSpendMvr;
  final double rewardMvr;
  final String title;
  final String terms;
  final bool redeemed;
  final DateTime? createdAt;
  final DateTime? redeemedAt;

  String get purchaseTotalText => 'MVR ${purchaseTotalMvr.toStringAsFixed(2)}';
  String get minimumSpendText => 'MVR ${minimumSpendMvr.toStringAsFixed(2)}';
  String get rewardText => rewardMvr > 0
      ? 'MVR ${rewardMvr.toStringAsFixed(2)}'
      : 'Special seller coupon';

  factory ClientCoupon.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};

    DateTime? readDate(Object? value) {
      return value is Timestamp ? value.toDate() : null;
    }

    double readDouble(Object? value) {
      return value is num
          ? value.toDouble()
          : double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return ClientCoupon(
      id: document.id,
      code: data['code']?.toString() ?? document.id,
      businessId: data['businessId']?.toString() ?? '',
      businessName: data['businessName']?.toString() ?? '',
      clientId: data['clientId']?.toString() ?? '',
      clientName: data['clientName']?.toString() ?? '',
      orderId: data['orderId']?.toString() ?? '',
      itemName: data['itemName']?.toString() ?? '',
      purchaseTotalMvr: readDouble(data['purchaseTotalMvr']),
      minimumSpendMvr: readDouble(data['minimumSpendMvr']),
      rewardMvr: readDouble(data['rewardMvr']),
      title: data['title']?.toString() ?? 'Customer coupon',
      terms: data['terms']?.toString() ?? '',
      redeemed: data['redeemed'] == true,
      createdAt: readDate(data['createdAt']),
      redeemedAt: readDate(data['redeemedAt']),
    );
  }
}
