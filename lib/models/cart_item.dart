import 'package:cloud_firestore/cloud_firestore.dart';

import 'catalog_item.dart';

class CartItem {
  const CartItem({
    required this.id,
    required this.clientId,
    required this.businessId,
    required this.businessName,
    required this.itemId,
    required this.itemName,
    required this.itemImageUrl,
    required this.category,
    required this.unitPriceMvr,
    required this.oldUnitPriceMvr,
    required this.promotionActive,
    required this.quantity,
    required this.availableQuantity,
    required this.bulkMinQuantity,
    required this.bulkDiscountAmountMvr,
    required this.bulkDiscountPercent,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String clientId;
  final String businessId;
  final String businessName;
  final String itemId;
  final String itemName;
  final String itemImageUrl;
  final String category;
  final double unitPriceMvr;
  final double oldUnitPriceMvr;
  final bool promotionActive;
  final int quantity;
  final int availableQuantity;
  final int bulkMinQuantity;
  final double bulkDiscountAmountMvr;
  final double bulkDiscountPercent;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get unitPriceText => 'MVR ${unitPriceMvr.toStringAsFixed(2)}';
  String get subtotalText => 'MVR ${lineTotal.toStringAsFixed(2)}';
  bool get hasPromotion => promotionActive && oldUnitPriceMvr > unitPriceMvr;
  String get oldPriceText => 'MVR ${oldUnitPriceMvr.toStringAsFixed(2)}';
  bool get isAvailable => availableQuantity > 0 && quantity <= availableQuantity;

  bool get hasBulkDiscount =>
      bulkMinQuantity > 1 &&
      (bulkDiscountAmountMvr > 0 || bulkDiscountPercent > 0);

  double get lineDiscount {
    if (!hasBulkDiscount || quantity < bulkMinQuantity) return 0;
    final subtotal = unitPriceMvr * quantity;
    var discount = 0.0;
    if (bulkDiscountAmountMvr > 0) discount += bulkDiscountAmountMvr;
    if (bulkDiscountPercent > 0) {
      discount += subtotal * (bulkDiscountPercent / 100);
    }
    if (discount < 0) return 0;
    if (discount > subtotal) return subtotal;
    return discount;
  }

  double get lineTotal => (unitPriceMvr * quantity) - lineDiscount;

  CatalogItem toCatalogItem() {
    return CatalogItem(
      id: itemId,
      businessId: businessId,
      businessName: businessName,
      name: itemName,
      description: '',
      category: category,
      itemType: 'product',
      imageUrl: itemImageUrl,
      priceMvr: unitPriceMvr,
      quantity: availableQuantity,
      active: true,
      createdBy: '',
      oldPriceMvr: oldUnitPriceMvr,
      promotionActive: promotionActive,
      bulkMinQuantity: bulkMinQuantity,
      bulkDiscountAmountMvr: bulkDiscountAmountMvr,
      bulkDiscountPercent: bulkDiscountPercent,
    );
  }

  factory CartItem.fromDocument(
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

    return CartItem(
      id: document.id,
      clientId: data['clientId']?.toString() ?? '',
      businessId: data['businessId']?.toString() ?? '',
      businessName: data['businessName']?.toString() ?? '',
      itemId: data['itemId']?.toString() ?? '',
      itemName: data['itemName']?.toString() ?? '',
      itemImageUrl: data['itemImageUrl']?.toString() ?? '',
      category: data['category']?.toString() ?? 'Other',
      unitPriceMvr: readDouble(data['unitPriceMvr']),
      oldUnitPriceMvr: readDouble(data['oldUnitPriceMvr']),
      promotionActive: data['promotionActive'] == true,
      quantity: readInt(data['quantity']),
      availableQuantity: readInt(data['availableQuantity']),
      bulkMinQuantity: readInt(data['bulkMinQuantity']),
      bulkDiscountAmountMvr: readDouble(data['bulkDiscountAmountMvr']),
      bulkDiscountPercent: readDouble(data['bulkDiscountPercent']),
      createdAt: readDate(data['createdAt']),
      updatedAt: readDate(data['updatedAt']),
    );
  }
}
