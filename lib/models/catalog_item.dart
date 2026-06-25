import 'package:cloud_firestore/cloud_firestore.dart';

class CatalogItem {
  const CatalogItem({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.name,
    required this.description,
    required this.category,
    required this.itemType,
    required this.imageUrl,
    required this.priceMvr,
    required this.quantity,
    required this.active,
    this.deleted = false,
    required this.createdBy,
    this.oldPriceMvr = 0,
    this.promotionActive = false,
    this.bulkMinQuantity = 0,
    this.bulkDiscountAmountMvr = 0,
    this.bulkDiscountPercent = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String businessId;
  final String businessName;
  final String name;
  final String description;
  final String category;
  final String itemType;
  final String imageUrl;

  /// Current selling price. If promotion is enabled this is the new price.
  final double priceMvr;

  /// Old price shown with a red cross line when promotion is enabled.
  final double oldPriceMvr;
  final bool promotionActive;

  /// Optional bulk discount. Example: buy 10 and get MVR 5 off or 5% off.
  final int bulkMinQuantity;
  final double bulkDiscountAmountMvr;
  final double bulkDiscountPercent;

  final int quantity;
  final bool active;
  final bool deleted;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isService => itemType == 'service';
  bool get isProduct => !isService;
  bool get isAvailable => active && !deleted && quantity > 0;

  bool get hasPromotion =>
      promotionActive && oldPriceMvr > priceMvr && priceMvr > 0;

  int get promotionPercentOff {
    if (!hasPromotion) return 0;
    return (((oldPriceMvr - priceMvr) / oldPriceMvr) * 100).round();
  }

  String get promotionBadgeText {
    final percent = promotionPercentOff;
    return percent > 0 ? 'SALE $percent% OFF' : 'SALE';
  }

  bool get hasBulkDiscount =>
      bulkMinQuantity > 1 &&
      (bulkDiscountAmountMvr > 0 || bulkDiscountPercent > 0);

  String get priceText => 'MVR ${priceMvr.toStringAsFixed(2)}';
  String get oldPriceText => 'MVR ${oldPriceMvr.toStringAsFixed(2)}';

  String get bulkDiscountText {
    if (!hasBulkDiscount) return '';
    final parts = <String>[];
    if (bulkDiscountAmountMvr > 0) {
      parts.add('MVR ${bulkDiscountAmountMvr.toStringAsFixed(2)} off');
    }
    if (bulkDiscountPercent > 0) {
      parts.add('${bulkDiscountPercent.toStringAsFixed(0)}% off');
    }
    return 'Buy $bulkMinQuantity+ get ${parts.join(' + ')}';
  }

  double discountForQuantity(int selectedQuantity) {
    if (!hasBulkDiscount || selectedQuantity < bulkMinQuantity) return 0;

    final subtotal = priceMvr * selectedQuantity;
    var discount = 0.0;

    if (bulkDiscountAmountMvr > 0) {
      discount += bulkDiscountAmountMvr;
    }
    if (bulkDiscountPercent > 0) {
      discount += subtotal * (bulkDiscountPercent / 100);
    }

    if (discount < 0) return 0;
    if (discount >= subtotal) return subtotal;
    return discount;
  }

  double lineTotalForQuantity(int selectedQuantity) {
    final subtotal = priceMvr * selectedQuantity;
    final total = subtotal - discountForQuantity(selectedQuantity);
    return total < 0 ? 0 : total;
  }

  factory CatalogItem.fromDocument(
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

    return CatalogItem(
      id: document.id,
      businessId: data['businessId']?.toString() ?? '',
      businessName: data['businessName']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      category: data['category']?.toString() ?? 'Other',
      itemType: data['itemType']?.toString() == 'service'
          ? 'service'
          : 'product',
      imageUrl: data['imageUrl']?.toString() ?? '',
      priceMvr: readDouble(data['priceMvr']),
      oldPriceMvr: readDouble(data['oldPriceMvr']),
      promotionActive: data['promotionActive'] == true,
      bulkMinQuantity: readInt(data['bulkMinQuantity']),
      bulkDiscountAmountMvr: readDouble(data['bulkDiscountAmountMvr']),
      bulkDiscountPercent: readDouble(data['bulkDiscountPercent']),
      quantity: readInt(data['quantity']),
      active: data['active'] != false,
      deleted: data['deleted'] == true,
      createdBy: data['createdBy']?.toString() ?? '',
      createdAt: readDate(data['createdAt']),
      updatedAt: readDate(data['updatedAt']),
    );
  }
}
