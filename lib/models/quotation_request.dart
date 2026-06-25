import 'package:cloud_firestore/cloud_firestore.dart';

class QuotationLine {
  const QuotationLine({
    required this.itemId,
    required this.itemName,
    required this.itemType,
    required this.itemImageUrl,
    required this.unitPriceMvr,
    required this.quantity,
    required this.lineTotalMvr,
    this.oldUnitPriceMvr = 0,
    this.promotionActive = false,
    this.bulkMinQuantity = 0,
    this.bulkDiscountAmountMvr = 0,
    this.bulkDiscountPercent = 0,
    this.lineDiscountMvr = 0,
  });

  final String itemId;
  final String itemName;
  final String itemType;
  final String itemImageUrl;
  final double unitPriceMvr;
  final int quantity;
  final double lineTotalMvr;
  final double oldUnitPriceMvr;
  final bool promotionActive;
  final int bulkMinQuantity;
  final double bulkDiscountAmountMvr;
  final double bulkDiscountPercent;
  final double lineDiscountMvr;

  bool get isService => itemType == 'service';
  String get unitPriceText => 'MVR ${unitPriceMvr.toStringAsFixed(2)}';
  String get lineTotalText => 'MVR ${lineTotalMvr.toStringAsFixed(2)}';
  String get oldUnitPriceText => 'MVR ${oldUnitPriceMvr.toStringAsFixed(2)}';
  String get lineDiscountText => 'MVR ${lineDiscountMvr.toStringAsFixed(2)}';

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'itemType': itemType,
      'itemImageUrl': itemImageUrl,
      'unitPriceMvr': unitPriceMvr,
      'oldUnitPriceMvr': oldUnitPriceMvr,
      'promotionActive': promotionActive,
      'bulkMinQuantity': bulkMinQuantity,
      'bulkDiscountAmountMvr': bulkDiscountAmountMvr,
      'bulkDiscountPercent': bulkDiscountPercent,
      'lineDiscountMvr': lineDiscountMvr,
      'quantity': quantity,
      'lineTotalMvr': lineTotalMvr,
    };
  }

  factory QuotationLine.fromMap(Map<String, dynamic> data) {
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

    return QuotationLine(
      itemId: data['itemId']?.toString() ?? '',
      itemName: data['itemName']?.toString() ?? '',
      itemType: data['itemType']?.toString() == 'service'
          ? 'service'
          : 'product',
      itemImageUrl: data['itemImageUrl']?.toString() ?? '',
      unitPriceMvr: readDouble(data['unitPriceMvr']),
      oldUnitPriceMvr: readDouble(data['oldUnitPriceMvr']),
      promotionActive: data['promotionActive'] == true,
      bulkMinQuantity: readInt(data['bulkMinQuantity']),
      bulkDiscountAmountMvr: readDouble(data['bulkDiscountAmountMvr']),
      bulkDiscountPercent: readDouble(data['bulkDiscountPercent']),
      lineDiscountMvr: readDouble(data['lineDiscountMvr']),
      quantity: readInt(data['quantity']),
      lineTotalMvr: readDouble(data['lineTotalMvr']),
    );
  }
}

class QuotationRequest {
  const QuotationRequest({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.clientId,
    required this.clientName,
    required this.clientEmail,
    required this.clientPhone,
    required this.lines,
    required this.requestedTotalMvr,
    required this.clientNote,
    required this.status,
    required this.quotationNumber,
    required this.quotationTotalMvr,
    required this.deliveryFeeMvr,
    required this.discountMvr,
    required this.finalTotalMvr,
    required this.sellerNote,
    required this.quotationAttachmentUrl,
    required this.quotationAttachmentPath,
    required this.rejectionReason,
    required this.quotedBy,
    this.createdAt,
    this.updatedAt,
    this.quotedAt,
  });

  final String id;
  final String businessId;
  final String businessName;
  final String clientId;
  final String clientName;
  final String clientEmail;
  final String clientPhone;
  final List<QuotationLine> lines;
  final double requestedTotalMvr;
  final String clientNote;
  final String status;
  final String quotationNumber;
  final double quotationTotalMvr;
  final double deliveryFeeMvr;
  final double discountMvr;
  final double finalTotalMvr;
  final String sellerNote;
  final String quotationAttachmentUrl;
  final String quotationAttachmentPath;
  final String rejectionReason;
  final String quotedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? quotedAt;

  bool get isPending => status == 'pending';
  bool get isQuoted => status == 'quoted';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';
  bool get isRejected => status == 'rejected';
  String get requestedTotalText => 'MVR ${requestedTotalMvr.toStringAsFixed(2)}';
  String get finalTotalText => 'MVR ${finalTotalMvr.toStringAsFixed(2)}';
  String get deliveryFeeText => 'MVR ${deliveryFeeMvr.toStringAsFixed(2)}';
  String get discountText => 'MVR ${discountMvr.toStringAsFixed(2)}';

  factory QuotationRequest.fromDocument(
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

    final rawLines = data['lines'];
    final lines = rawLines is List
        ? rawLines
            .whereType<Map>()
            .map((line) => QuotationLine.fromMap(
                  Map<String, dynamic>.from(line),
                ))
            .toList()
        : const <QuotationLine>[];

    return QuotationRequest(
      id: document.id,
      businessId: data['businessId']?.toString() ?? '',
      businessName: data['businessName']?.toString() ?? '',
      clientId: data['clientId']?.toString() ?? '',
      clientName: data['clientName']?.toString() ?? '',
      clientEmail: data['clientEmail']?.toString() ?? '',
      clientPhone: data['clientPhone']?.toString() ?? '',
      lines: lines,
      requestedTotalMvr: readDouble(data['requestedTotalMvr']),
      clientNote: data['clientNote']?.toString() ?? '',
      status: data['status']?.toString() ?? 'pending',
      quotationNumber: data['quotationNumber']?.toString() ?? '',
      quotationTotalMvr: readDouble(data['quotationTotalMvr']),
      deliveryFeeMvr: readDouble(data['deliveryFeeMvr']),
      discountMvr: readDouble(data['discountMvr']),
      finalTotalMvr: readDouble(data['finalTotalMvr']),
      sellerNote: data['sellerNote']?.toString() ?? '',
      quotationAttachmentUrl: data['quotationAttachmentUrl']?.toString() ?? '',
      quotationAttachmentPath: data['quotationAttachmentPath']?.toString() ?? '',
      rejectionReason: data['rejectionReason']?.toString() ?? '',
      quotedBy: data['quotedBy']?.toString() ?? '',
      createdAt: readDate(data['createdAt']),
      updatedAt: readDate(data['updatedAt']),
      quotedAt: readDate(data['quotedAt']),
    );
  }
}
