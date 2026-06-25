import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseOrder {
  const PurchaseOrder({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.itemId,
    required this.itemName,
    required this.itemType,
    required this.itemImageUrl,
    required this.unitPriceMvr,
    required this.quantity,
    required this.totalMvr,
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    required this.clientPhone,
    required this.receiptPath,
    required this.transferReference,
    required this.status,
    required this.rejectionReason,
    required this.verifiedBy,
    this.createdAt,
    this.verifiedAt,
  });

  final String id;
  final String businessId;
  final String businessName;
  final String itemId;
  final String itemName;
  final String itemType;
  final String itemImageUrl;
  final double unitPriceMvr;
  final int quantity;
  final double totalMvr;
  final String clientId;
  final String clientName;
  final String clientEmail;
  final String clientPhone;
  final String receiptPath;
  final String transferReference;
  final String status;
  final String rejectionReason;
  final String verifiedBy;
  final DateTime? createdAt;
  final DateTime? verifiedAt;

  bool get isPending => status == 'pending_verification';
  bool get isVerified => status == 'verified';
  bool get isProcessing => status == 'processing';
  bool get isReady => status == 'ready';
  bool get isDelivered => status == 'delivered';
  bool get isCompleted => status == 'completed';
  bool get isRejected => status == 'rejected';
  bool get canReceiveReview =>
      isVerified || isProcessing || isReady || isDelivered || isCompleted;
  bool get isSaleCounted =>
      isVerified || isProcessing || isReady || isDelivered || isCompleted;
  String get totalText => 'MVR ${totalMvr.toStringAsFixed(2)}';

  factory PurchaseOrder.fromDocument(
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

    int readInt(Object? value) {
      return value is num
          ? value.toInt()
          : int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return PurchaseOrder(
      id: document.id,
      businessId: data['businessId']?.toString() ?? '',
      businessName: data['businessName']?.toString() ?? '',
      itemId: data['itemId']?.toString() ?? '',
      itemName: data['itemName']?.toString() ?? '',
      itemType: data['itemType']?.toString() ?? 'product',
      itemImageUrl: data['itemImageUrl']?.toString() ?? '',
      unitPriceMvr: readDouble(data['unitPriceMvr']),
      quantity: readInt(data['quantity']),
      totalMvr: readDouble(data['totalMvr']),
      clientId: data['clientId']?.toString() ?? '',
      clientName: data['clientName']?.toString() ?? '',
      clientEmail: data['clientEmail']?.toString() ?? '',
      clientPhone: data['clientPhone']?.toString() ?? '',
      receiptPath: data['receiptPath']?.toString() ?? '',
      transferReference: data['transferReference']?.toString() ?? '',
      status: data['status']?.toString() ?? 'pending_verification',
      rejectionReason: data['rejectionReason']?.toString() ?? '',
      verifiedBy: data['verifiedBy']?.toString() ?? '',
      createdAt: readDate(data['createdAt']),
      verifiedAt: readDate(data['verifiedAt']),
    );
  }
}
