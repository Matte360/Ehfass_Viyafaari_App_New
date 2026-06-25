import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/business.dart';
import '../models/catalog_item.dart';
import '../models/cart_item.dart';
import '../models/chat_message.dart';
import '../models/chat_thread.dart';
import '../models/client_coupon.dart';
import '../models/purchase_order.dart';
import '../models/quotation_request.dart';
import '../models/review.dart';

class MarketplaceService {
  MarketplaceService._();

  static final MarketplaceService instance = MarketplaceService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _publicMediaBucket = 'business-media';
  static const String _receiptBucket = 'payment-proofs';
  static const String _quotationAttachmentFolder = 'quotations';
  static const Duration _uploadTimeout = Duration(seconds: 35);

  Stream<List<CatalogItem>> watchPublicCatalog(String businessId) {
    return _firestore
        .collection('catalog_items')
        .where('businessId', isEqualTo: businessId)
        .where('active', isEqualTo: true)
        .snapshots()
        .map(_catalogFromSnapshot);
  }

  Stream<List<CatalogItem>> watchBusinessCatalog(String businessId) {
    return _firestore
        .collection('catalog_items')
        .where('businessId', isEqualTo: businessId)
        .snapshots()
        .map(_catalogFromSnapshot);
  }

  Stream<List<CatalogItem>> watchSaleCatalog() {
    return _firestore
        .collection('catalog_items')
        .where('active', isEqualTo: true)
        .where('promotionActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final items = _catalogFromSnapshot(snapshot)
          .where((item) => item.hasPromotion && item.isProduct && item.isAvailable)
          .toList();
      items.sort((a, b) => b.promotionPercentOff.compareTo(a.promotionPercentOff));
      return items;
    });
  }

  List<CatalogItem> _catalogFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final items = snapshot.docs
        .map(CatalogItem.fromDocument)
        .where((item) => !item.deleted)
        .toList();
    items.sort((a, b) {
      final categoryResult = a.category.toLowerCase().compareTo(
            b.category.toLowerCase(),
          );
      if (categoryResult != 0) return categoryResult;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return items;
  }



  Stream<List<CartItem>> watchCartForClient(String clientId) {
    return _firestore
        .collection('cart_items')
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs.map(CartItem.fromDocument).toList();
      items.sort((a, b) {
        final aDate = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return items;
    });
  }

  Stream<int> watchCartCount(String clientId) {
    return watchCartForClient(clientId).map(
      (items) => items.fold<int>(0, (total, item) => total + item.quantity),
    );
  }

  Future<void> addProductToCart({
    required AppUser client,
    required Business business,
    required CatalogItem item,
    required int quantity,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != client.uid) {
      throw StateError('Please log in again before adding to cart.');
    }
    if (!client.isClient) {
      throw StateError('Only client accounts can use cart.');
    }
    if (item.isService) {
      throw StateError('Services use quotation request or chat. Cart is for products only.');
    }
    if (!business.isApproved || item.businessId != business.id) {
      throw StateError('This product is not available.');
    }
    if (quantity <= 0) {
      throw StateError('Quantity must be at least 1.');
    }

    final itemDocument =
        await _firestore.collection('catalog_items').doc(item.id).get();
    if (!itemDocument.exists) {
      throw StateError('This product is no longer available.');
    }
    final currentItem = CatalogItem.fromDocument(itemDocument);
    if (!currentItem.isProduct || !currentItem.isAvailable) {
      throw StateError('This product is currently out of stock.');
    }
    if (quantity > currentItem.quantity) {
      throw StateError('Only ${currentItem.quantity} item(s) are available.');
    }

    final cartReference =
        _firestore.collection('cart_items').doc('${client.uid}_${item.id}');
    await cartReference.set({
      'clientId': client.uid,
      'businessId': business.id,
      'businessName': business.businessName,
      'itemId': currentItem.id,
      'itemName': currentItem.name,
      'itemImageUrl': currentItem.imageUrl,
      'category': currentItem.category,
      'unitPriceMvr': currentItem.priceMvr,
      'oldUnitPriceMvr': currentItem.oldPriceMvr,
      'promotionActive': currentItem.hasPromotion,
      'quantity': quantity,
      'availableQuantity': currentItem.quantity,
      'bulkMinQuantity': currentItem.bulkMinQuantity,
      'bulkDiscountAmountMvr': currentItem.bulkDiscountAmountMvr,
      'bulkDiscountPercent': currentItem.bulkDiscountPercent,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateCartItemQuantity({
    required CartItem cartItem,
    required int quantity,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != cartItem.clientId) {
      throw StateError('Please log in again before updating cart.');
    }
    if (quantity <= 0) {
      await removeCartItem(cartItem);
      return;
    }
    if (quantity > cartItem.availableQuantity) {
      throw StateError('Only ${cartItem.availableQuantity} item(s) are available.');
    }
    await _firestore.collection('cart_items').doc(cartItem.id).update({
      'quantity': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeCartItem(CartItem cartItem) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != cartItem.clientId) {
      throw StateError('Please log in again before updating cart.');
    }
    await _firestore.collection('cart_items').doc(cartItem.id).delete();
  }

  Stream<List<PurchaseOrder>> watchOrdersForBusiness(String businessId) {
    return _firestore
        .collection('orders')
        .where('businessId', isEqualTo: businessId)
        .snapshots()
        .map(_ordersFromSnapshot);
  }

  Stream<List<PurchaseOrder>> watchOrdersForClient(String clientId) {
    return _firestore
        .collection('orders')
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map(_ordersFromSnapshot);
  }


  Stream<List<QuotationRequest>> watchQuotationRequestsForBusiness(
    String businessId,
  ) {
    return _firestore
        .collection('quotation_requests')
        .where('businessId', isEqualTo: businessId)
        .snapshots()
        .map(_quotationRequestsFromSnapshot);
  }

  Stream<List<QuotationRequest>> watchQuotationRequestsForClient(
    String clientId,
  ) {
    return _firestore
        .collection('quotation_requests')
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map(_quotationRequestsFromSnapshot);
  }

  List<QuotationRequest> _quotationRequestsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final requests = snapshot.docs.map(QuotationRequest.fromDocument).toList();
    requests.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return requests;
  }

  List<PurchaseOrder> _ordersFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final orders = snapshot.docs.map(PurchaseOrder.fromDocument).toList();
    orders.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return orders;
  }

  Future<void> addCatalogItem({
    required Business business,
    required String itemType,
    required String name,
    required String category,
    required double priceMvr,
    required int quantity,
    required String description,
    required double oldPriceMvr,
    required bool promotionActive,
    required int bulkMinQuantity,
    required double bulkDiscountAmountMvr,
    required double bulkDiscountPercent,
    required Uint8List imageBytes,
    required String imageFileName,
  }) async {
    _requireBusinessAccount(business);

    if (priceMvr <= 0) {
      throw StateError('Price must be more than MVR 0.00.');
    }
    if (quantity < 0) {
      throw StateError('Quantity cannot be negative.');
    }
    if (promotionActive && oldPriceMvr <= priceMvr) {
      throw StateError('Old price must be higher than the new promotion price.');
    }
    if (bulkMinQuantity < 0 || bulkDiscountAmountMvr < 0 || bulkDiscountPercent < 0) {
      throw StateError('Discount values cannot be negative.');
    }
    if (bulkDiscountPercent > 100) {
      throw StateError('Discount percentage cannot be more than 100%.');
    }

    final reference = _firestore.collection('catalog_items').doc();
    final imageUrl = await _uploadCatalogImage(
      businessId: business.id,
      itemId: reference.id,
      bytes: imageBytes,
      originalFileName: imageFileName,
      upsert: false,
    );

    await reference.set({
      'businessId': business.id,
      'businessName': business.businessName,
      'name': name.trim(),
      'nameLower': name.trim().toLowerCase(),
      'description': description.trim(),
      'category': category.trim(),
      'categoryLower': category.trim().toLowerCase(),
      'itemType': itemType == 'service' ? 'service' : 'product',
      'imageUrl': imageUrl,
      'priceMvr': priceMvr,
      'oldPriceMvr': promotionActive ? oldPriceMvr : 0,
      'promotionActive': promotionActive,
      'bulkMinQuantity': bulkMinQuantity,
      'bulkDiscountAmountMvr': bulkDiscountAmountMvr,
      'bulkDiscountPercent': bulkDiscountPercent,
      'quantity': quantity,
      'active': true,
      'deleted': false,
      'createdBy': _auth.currentUser!.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCatalogItem({
    required Business business,
    required CatalogItem item,
    required String itemType,
    required String name,
    required String category,
    required double priceMvr,
    required int quantity,
    required String description,
    required double oldPriceMvr,
    required bool promotionActive,
    required int bulkMinQuantity,
    required double bulkDiscountAmountMvr,
    required double bulkDiscountPercent,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    _requireBusinessAccount(business);

    if (item.businessId != business.id) {
      throw StateError('This item does not belong to your business.');
    }
    if (priceMvr <= 0) {
      throw StateError('Price must be more than MVR 0.00.');
    }
    if (quantity < 0) {
      throw StateError('Quantity cannot be negative.');
    }
    if (promotionActive && oldPriceMvr <= priceMvr) {
      throw StateError('Old price must be higher than the new promotion price.');
    }
    if (bulkMinQuantity < 0 || bulkDiscountAmountMvr < 0 || bulkDiscountPercent < 0) {
      throw StateError('Discount values cannot be negative.');
    }
    if (bulkDiscountPercent > 100) {
      throw StateError('Discount percentage cannot be more than 100%.');
    }

    var imageUrl = item.imageUrl;
    if (imageBytes != null && imageFileName != null) {
      imageUrl = await _uploadCatalogImage(
        businessId: business.id,
        itemId: item.id,
        bytes: imageBytes,
        originalFileName: imageFileName,
        upsert: true,
      );
    }

    await _firestore.collection('catalog_items').doc(item.id).update({
      'name': name.trim(),
      'nameLower': name.trim().toLowerCase(),
      'description': description.trim(),
      'category': category.trim(),
      'categoryLower': category.trim().toLowerCase(),
      'itemType': itemType == 'service' ? 'service' : 'product',
      'imageUrl': imageUrl,
      'priceMvr': priceMvr,
      'oldPriceMvr': promotionActive ? oldPriceMvr : 0,
      'promotionActive': promotionActive,
      'bulkMinQuantity': bulkMinQuantity,
      'bulkDiscountAmountMvr': bulkDiscountAmountMvr,
      'bulkDiscountPercent': bulkDiscountPercent,
      'quantity': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setCatalogItemActive({
    required Business business,
    required CatalogItem item,
    required bool active,
  }) async {
    _requireBusinessAccount(business);
    if (item.businessId != business.id) {
      throw StateError('This item does not belong to your business.');
    }

    await _firestore.collection('catalog_items').doc(item.id).update({
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markCatalogItemOutOfStock({
    required Business business,
    required CatalogItem item,
  }) async {
    _requireBusinessAccount(business);
    if (item.businessId != business.id) {
      throw StateError('This item does not belong to your business.');
    }

    await _firestore.collection('catalog_items').doc(item.id).update({
      'quantity': 0,
      'active': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCatalogItem({
    required Business business,
    required CatalogItem item,
  }) async {
    _requireBusinessAccount(business);
    if (item.businessId != business.id) {
      throw StateError('This item does not belong to your business.');
    }

    // Soft delete keeps old orders/quotations safe but removes the item
    // from seller lists and client storefronts.
    await _firestore.collection('catalog_items').doc(item.id).update({
      'active': false,
      'deleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePaymentAccount({
    required Business business,
    required String bankName,
    required String accountName,
    required String accountNumber,
    required String paymentInstructions,
  }) async {
    _requireBusinessAccount(business);

    await _firestore.collection('businesses').doc(business.id).update({
      'bankName': bankName.trim(),
      'accountName': accountName.trim(),
      'accountNumber': accountNumber.trim(),
      'paymentInstructions': paymentInstructions.trim(),
      'paymentUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> submitBankTransferOrder({
    required AppUser client,
    required Business business,
    required CatalogItem item,
    required int quantity,
    required Uint8List receiptBytes,
    required String receiptFileName,
    required String transferReference,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != client.uid) {
      throw StateError('Please log in again before placing this order.');
    }
    if (!client.isClient) {
      throw StateError('Only client accounts can place orders.');
    }
    if (!business.hasPaymentAccount) {
      throw StateError(
        'This business has not added its money transfer account details yet.',
      );
    }
    if (quantity <= 0) {
      throw StateError('Quantity must be at least 1.');
    }

    final orderReference = _firestore.collection('orders').doc();
    final receiptPath = await _uploadReceipt(
      businessId: business.id,
      orderId: orderReference.id,
      clientId: client.uid,
      bytes: receiptBytes,
      originalFileName: receiptFileName,
    );

    await _firestore.runTransaction((transaction) async {
      final itemReference = _firestore.collection('catalog_items').doc(item.id);
      final itemDocument = await transaction.get(itemReference);

      if (!itemDocument.exists) {
        throw StateError('This item is no longer available.');
      }

      final currentItem = CatalogItem.fromDocument(itemDocument);
      if (!currentItem.active || currentItem.businessId != business.id) {
        throw StateError('This item is not available for purchase.');
      }
      if (currentItem.quantity < quantity) {
        throw StateError(
          'Only ${currentItem.quantity} item(s) or service slot(s) are available.',
        );
      }

      final lineDiscount = currentItem.discountForQuantity(quantity);
      final total = currentItem.lineTotalForQuantity(quantity);

      transaction.set(orderReference, {
        'businessId': business.id,
        'businessName': business.businessName,
        'itemId': currentItem.id,
        'itemName': currentItem.name,
        'itemType': currentItem.itemType,
        'itemImageUrl': currentItem.imageUrl,
        'unitPriceMvr': currentItem.priceMvr,
        'quantity': quantity,
        'lineDiscountMvr': lineDiscount,
        'totalMvr': total,
        'clientId': client.uid,
        'clientName': client.fullName,
        'clientEmail': client.email,
        'clientPhone': client.phone,
        'paymentMethod': 'bank_transfer',
        'receiptPath': receiptPath,
        'transferReference': transferReference.trim(),
        'status': 'pending_verification',
        'statusHistory': [
          {
            'status': 'pending_verification',
            'label': 'Waiting for payment verification',
            'createdAt': Timestamp.now(),
            'by': client.uid,
          }
        ],
        'rejectionReason': '',
        'verifiedBy': '',
        'createdAt': FieldValue.serverTimestamp(),
        'verifiedAt': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    await _createNotification(
      userId: business.businessUserId,
      title: 'New payment pending',
      body: '${client.fullName} uploaded a transfer receipt for ${item.name}.',
      type: 'order_new',
      businessId: business.id,
      orderId: orderReference.id,
    );
  }


  Future<void> createQuotationRequest({
    required AppUser client,
    required Business business,
    required Map<CatalogItem, int> selections,
    required String note,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != client.uid) {
      throw StateError('Please log in again before requesting a quotation.');
    }
    if (!client.isClient) {
      throw StateError('Only client accounts can request quotations.');
    }
    if (!business.isApproved) {
      throw StateError('This business is not approved yet.');
    }
    if (selections.isEmpty) {
      throw StateError('Select at least one item or service.');
    }

    final requestReference = _firestore.collection('quotation_requests').doc();

    await _firestore.runTransaction((transaction) async {
      final lines = <Map<String, dynamic>>[];
      var requestedTotal = 0.0;

      for (final selection in selections.entries) {
        final requestedQuantity = selection.value;
        if (requestedQuantity <= 0) {
          throw StateError('Quantity must be at least 1.');
        }

        final itemReference =
            _firestore.collection('catalog_items').doc(selection.key.id);
        final itemDocument = await transaction.get(itemReference);
        if (!itemDocument.exists) {
          throw StateError('${selection.key.name} is no longer available.');
        }

        final currentItem = CatalogItem.fromDocument(itemDocument);
        if (!currentItem.active || currentItem.businessId != business.id) {
          throw StateError('${currentItem.name} is not available.');
        }
        if (currentItem.quantity < requestedQuantity) {
          throw StateError(
            'Only ${currentItem.quantity} available for ${currentItem.name}.',
          );
        }

        final lineDiscount = currentItem.discountForQuantity(requestedQuantity);
        final lineTotal = currentItem.lineTotalForQuantity(requestedQuantity);
        requestedTotal += lineTotal;
        lines.add({
          'itemId': currentItem.id,
          'itemName': currentItem.name,
          'itemType': currentItem.itemType,
          'itemImageUrl': currentItem.imageUrl,
          'unitPriceMvr': currentItem.priceMvr,
          'oldUnitPriceMvr': currentItem.oldPriceMvr,
          'promotionActive': currentItem.hasPromotion,
          'bulkMinQuantity': currentItem.bulkMinQuantity,
          'bulkDiscountAmountMvr': currentItem.bulkDiscountAmountMvr,
          'bulkDiscountPercent': currentItem.bulkDiscountPercent,
          'lineDiscountMvr': lineDiscount,
          'quantity': requestedQuantity,
          'lineTotalMvr': lineTotal,
        });
      }

      transaction.set(requestReference, {
        'businessId': business.id,
        'businessName': business.businessName,
        'clientId': client.uid,
        'clientName': client.fullName,
        'clientEmail': client.email,
        'clientPhone': client.phone,
        'lines': lines,
        'requestedTotalMvr': requestedTotal,
        'clientNote': note.trim(),
        'status': 'pending',
        'statusHistory': [
          {
            'status': 'pending',
            'label': 'Quotation requested',
            'createdAt': Timestamp.now(),
            'by': client.uid,
          }
        ],
        'quotationNumber': '',
        'quotationTotalMvr': 0,
        'deliveryFeeMvr': 0,
        'discountMvr': 0,
        'finalTotalMvr': 0,
        'sellerNote': '',
        'quotationAttachmentUrl': '',
        'quotationAttachmentPath': '',
        'rejectionReason': '',
        'quotedBy': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'quotedAt': null,
      });
    });

    await _createNotification(
      userId: business.businessUserId,
      title: 'New quotation request',
      body: '${client.fullName} requested a quotation from ${business.businessName}.',
      type: 'quote_new',
      businessId: business.id,
      quotationId: requestReference.id,
    );
  }

  Future<void> generateQuotation({
    required Business business,
    required QuotationRequest request,
    required double deliveryFeeMvr,
    required double discountMvr,
    required String sellerNote,
    Uint8List? attachmentBytes,
    String? attachmentFileName,
  }) async {
    _requireBusinessAccount(business);
    if (request.businessId != business.id) {
      throw StateError('This quotation request does not belong to your shop.');
    }
    if (!request.isPending) {
      throw StateError('This quotation request has already been reviewed.');
    }
    if (deliveryFeeMvr < 0 || discountMvr < 0) {
      throw StateError('Delivery fee and discount cannot be negative.');
    }

    final finalTotal = request.requestedTotalMvr + deliveryFeeMvr - discountMvr;
    if (finalTotal < 0) {
      throw StateError('Final quotation total cannot be below MVR 0.00.');
    }

    var attachmentUrl = '';
    var attachmentPath = '';
    if (attachmentBytes != null && attachmentFileName != null) {
      attachmentPath = await _uploadQuotationAttachment(
        businessId: business.id,
        requestId: request.id,
        bytes: attachmentBytes,
        originalFileName: attachmentFileName,
      );
      attachmentUrl = _supabase.storage
          .from(_publicMediaBucket)
          .getPublicUrl(attachmentPath);
    }

    final numberSuffix = request.id.length >= 6
        ? request.id.substring(0, 6).toUpperCase()
        : request.id.toUpperCase();

    await _firestore.collection('quotation_requests').doc(request.id).update({
      'status': 'quoted',
      'quotationNumber': 'QT-$numberSuffix',
      'quotationTotalMvr': request.requestedTotalMvr,
      'deliveryFeeMvr': deliveryFeeMvr,
      'discountMvr': discountMvr,
      'finalTotalMvr': finalTotal,
      'sellerNote': sellerNote.trim(),
      'quotationAttachmentUrl': attachmentUrl,
      'quotationAttachmentPath': attachmentPath,
      'rejectionReason': '',
      'quotedBy': _auth.currentUser!.uid,
      'quotedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([
        {
          'status': 'quoted',
          'label': 'Seller generated quotation',
          'createdAt': Timestamp.now(),
          'by': _auth.currentUser!.uid,
        }
      ]),
    });

    await _createNotification(
      userId: request.clientId,
      title: 'Quotation received',
      body: '${business.businessName} sent quotation $numberSuffix.',
      type: 'quote_status',
      businessId: business.id,
      quotationId: request.id,
    );
  }

  Future<void> rejectQuotationRequest({
    required Business business,
    required QuotationRequest request,
    required String reason,
  }) async {
    _requireBusinessAccount(business);
    if (request.businessId != business.id) {
      throw StateError('This quotation request does not belong to your shop.');
    }
    if (!request.isPending) {
      throw StateError('This quotation request has already been reviewed.');
    }
    if (reason.trim().isEmpty) {
      throw StateError('Please enter a rejection reason.');
    }

    await _firestore.collection('quotation_requests').doc(request.id).update({
      'status': 'rejected',
      'rejectionReason': reason.trim(),
      'quotedBy': _auth.currentUser!.uid,
      'updatedAt': FieldValue.serverTimestamp(),
      'quotedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([
        {
          'status': 'rejected',
          'label': 'Seller rejected quotation request',
          'createdAt': Timestamp.now(),
          'by': _auth.currentUser!.uid,
        }
      ]),
    });

    await _createNotification(
      userId: request.clientId,
      title: 'Quotation rejected',
      body: '${business.businessName} rejected your quotation request.',
      type: 'quote_status',
      businessId: business.id,
      quotationId: request.id,
    );
  }

  Future<void> verifyOrder({
    required Business business,
    required PurchaseOrder order,
  }) async {
    _requireBusinessAccount(business);

    await _firestore.runTransaction((transaction) async {
      final orderReference = _firestore.collection('orders').doc(order.id);
      final itemReference =
          _firestore.collection('catalog_items').doc(order.itemId);

      final orderDocument = await transaction.get(orderReference);
      final itemDocument = await transaction.get(itemReference);

      if (!orderDocument.exists) {
        throw StateError('The order no longer exists.');
      }
      if (!itemDocument.exists) {
        throw StateError('The ordered item no longer exists.');
      }

      final currentOrder = PurchaseOrder.fromDocument(orderDocument);
      final currentItem = CatalogItem.fromDocument(itemDocument);

      if (currentOrder.businessId != business.id) {
        throw StateError('This order does not belong to your business.');
      }
      if (!currentOrder.isPending) {
        throw StateError('This transfer has already been reviewed.');
      }
      if (currentItem.quantity < currentOrder.quantity) {
        throw StateError(
          'Not enough quantity remains. Current quantity: ${currentItem.quantity}.',
        );
      }

      final newQuantity = currentItem.quantity - currentOrder.quantity;

      transaction.update(itemReference, {
        'quantity': newQuantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(orderReference, {
        'status': 'verified',
        'verifiedBy': _auth.currentUser!.uid,
        'verifiedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'rejectionReason': '',
        'statusHistory': FieldValue.arrayUnion([
          {
            'status': 'verified',
            'label': 'Payment verified',
            'createdAt': Timestamp.now(),
            'by': _auth.currentUser!.uid,
          }
        ]),
      });
    });

    await _createNotification(
      userId: order.clientId,
      title: 'Payment verified',
      body: '${business.businessName} verified your payment for ${order.itemName}.',
      type: 'order_status',
      businessId: business.id,
      orderId: order.id,
    );
  }

  Future<void> rejectOrder({
    required Business business,
    required PurchaseOrder order,
    required String reason,
  }) async {
    _requireBusinessAccount(business);

    if (order.businessId != business.id) {
      throw StateError('This order does not belong to your business.');
    }

    await _firestore.collection('orders').doc(order.id).update({
      'status': 'rejected',
      'rejectionReason': reason.trim(),
      'verifiedBy': _auth.currentUser!.uid,
      'verifiedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([
        {
          'status': 'rejected',
          'label': 'Payment rejected',
          'createdAt': Timestamp.now(),
          'by': _auth.currentUser!.uid,
        }
      ]),
    });

    await _createNotification(
      userId: order.clientId,
      title: 'Payment rejected',
      body: '${business.businessName} rejected your payment for ${order.itemName}.',
      type: 'order_status',
      businessId: business.id,
      orderId: order.id,
    );
  }

  Future<String> createReceiptSignedUrl(String receiptPath) async {
    if (receiptPath.isEmpty) {
      throw StateError('No payment receipt was uploaded.');
    }

    return _supabase.storage
        .from(_receiptBucket)
        .createSignedUrl(receiptPath, 600);
  }


  Stream<List<ChatThread>> watchChatsForClient(String clientId) {
    return _firestore
        .collection('chat_threads')
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map(_chatThreadsFromSnapshot);
  }

  Stream<List<ChatThread>> watchChatsForBusiness(String businessId) {
    return _firestore
        .collection('chat_threads')
        .where('businessId', isEqualTo: businessId)
        .snapshots()
        .map(_chatThreadsFromSnapshot);
  }

  List<ChatThread> _chatThreadsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final threads = snapshot.docs.map(ChatThread.fromDocument).toList();
    threads.sort((a, b) {
      final aDate = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return threads;
  }

  Stream<List<ChatMessage>> watchChatMessages(String threadId) {
    return _firestore
        .collection('chat_threads')
        .doc(threadId)
        .collection('messages')
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs.map(ChatMessage.fromDocument).toList();
      messages.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aDate.compareTo(bDate);
      });
      return messages;
    });
  }

  Future<String> ensureChatThread({
    required AppUser client,
    required Business business,
    CatalogItem? item,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != client.uid) {
      throw StateError('Please log in again before opening chat.');
    }
    if (!client.isClient) {
      throw StateError('Only client accounts can chat with sellers.');
    }
    if (!business.isApproved) {
      throw StateError('This business is not approved yet.');
    }

    final threadId = '${business.id}_${client.uid}';
    final reference = _firestore.collection('chat_threads').doc(threadId);

    // Do not call reference.get() before creating a new chat.
    // Firestore rules can deny reading a document that does not exist yet.
    // set(..., merge: true) works for both new and existing chat threads.
    await reference.set({
      'businessId': business.id,
      'businessName': business.businessName,
      'businessUserId': business.businessUserId,
      'clientId': client.uid,
      'clientName': client.fullName,
      'clientEmail': client.email,
      'clientPhone': client.phone,
      'itemId': item?.id ?? '',
      'itemName': item?.name ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return threadId;
  }

  Future<ChatThread?> getChatThread(String threadId) async {
    final snapshot = await _firestore.collection('chat_threads').doc(threadId).get();
    if (!snapshot.exists) return null;
    return ChatThread.fromDocument(snapshot);
  }

  Future<void> sendChatMessage({
    required ChatThread thread,
    required AppUser sender,
    required String message,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != sender.uid) {
      throw StateError('Please log in again before sending message.');
    }

    final isClientSender = sender.uid == thread.clientId;
    final isBusinessSender = sender.uid == thread.businessUserId;
    if (!isClientSender && !isBusinessSender && !sender.isAdmin) {
      throw StateError('You are not allowed to send message in this chat.');
    }

    final threadReference = _firestore.collection('chat_threads').doc(thread.id);
    final messageReference = threadReference.collection('messages').doc();

    await _firestore.runTransaction((transaction) async {
      transaction.set(messageReference, {
        'senderId': sender.uid,
        'senderName': sender.fullName,
        'senderRole': isClientSender ? 'client' : 'business',
        'message': trimmed,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(threadReference, {
        'lastMessage': trimmed,
        'lastSenderId': sender.uid,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadForClient': !isClientSender,
        'unreadForBusiness': !isBusinessSender,
      });
    });

    final receiverId = isClientSender ? thread.businessUserId : thread.clientId;
    await _createNotification(
      userId: receiverId,
      title: isClientSender ? 'New client message' : 'New seller message',
      body: '${sender.fullName}: $trimmed',
      type: 'chat_message',
      businessId: thread.businessId,
      chatThreadId: thread.id,
    );
  }

  Future<void> markChatRead({
    required ChatThread thread,
    required AppUser reader,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != reader.uid) return;

    final updates = <String, dynamic>{};
    if (reader.uid == thread.clientId) {
      updates['unreadForClient'] = false;
    }
    if (reader.uid == thread.businessUserId) {
      updates['unreadForBusiness'] = false;
    }
    if (updates.isEmpty) return;

    await _firestore.collection('chat_threads').doc(thread.id).update(updates);
  }

  Stream<int> watchClientNotificationCount(String clientId) {
    final controller = StreamController<int>();
    var orders = <PurchaseOrder>[];
    var quotes = <QuotationRequest>[];
    var chats = <ChatThread>[];

    void emit() {
      if (controller.isClosed) return;
      final count = orders.where((order) => order.isPending).length +
          quotes.where((quote) => quote.isPending || quote.isQuoted).length +
          chats.where((chat) => chat.unreadForClient).length;
      controller.add(count);
    }

    final subscriptions = <StreamSubscription<dynamic>>[];
    subscriptions.add(watchOrdersForClient(clientId).listen((value) {
      orders = value;
      emit();
    }, onError: controller.addError));
    subscriptions.add(watchQuotationRequestsForClient(clientId).listen((value) {
      quotes = value;
      emit();
    }, onError: controller.addError));
    subscriptions.add(watchChatsForClient(clientId).listen((value) {
      chats = value;
      emit();
    }, onError: controller.addError));

    controller.onCancel = () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    };

    return controller.stream;
  }

  Stream<int> watchBusinessNotificationCount(String businessId) {
    final controller = StreamController<int>();
    var orders = <PurchaseOrder>[];
    var quotes = <QuotationRequest>[];
    var chats = <ChatThread>[];

    void emit() {
      if (controller.isClosed) return;
      final count = orders.where((order) => order.isPending).length +
          quotes.where((quote) => quote.isPending).length +
          chats.where((chat) => chat.unreadForBusiness).length;
      controller.add(count);
    }

    final subscriptions = <StreamSubscription<dynamic>>[];
    subscriptions.add(watchOrdersForBusiness(businessId).listen((value) {
      orders = value;
      emit();
    }, onError: controller.addError));
    subscriptions.add(watchQuotationRequestsForBusiness(businessId).listen((value) {
      quotes = value;
      emit();
    }, onError: controller.addError));
    subscriptions.add(watchChatsForBusiness(businessId).listen((value) {
      chats = value;
      emit();
    }, onError: controller.addError));

    controller.onCancel = () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    };

    return controller.stream;
  }




  Stream<ClientCoupon?> watchCouponForOrder({
    required String orderId,
    required String clientId,
  }) {
    if (orderId.isEmpty || clientId.isEmpty) return Stream.value(null);

    // Do not listen to coupons/{orderId}_{clientId} directly before it exists.
    // Firestore can deny a direct read on a missing document depending on rules.
    // Querying by orderId + clientId lets the empty result load safely.
    return _firestore
        .collection('coupons')
        .where('orderId', isEqualTo: orderId)
        .where('clientId', isEqualTo: clientId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return ClientCoupon.fromDocument(snapshot.docs.first);
    });
  }

  Stream<List<ClientCoupon>> watchCouponsForBusiness(String businessId) {
    return _firestore
        .collection('coupons')
        .where('businessId', isEqualTo: businessId)
        .snapshots()
        .map((snapshot) {
      final coupons = snapshot.docs.map(ClientCoupon.fromDocument).toList();
      coupons.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return coupons;
    });
  }

  Future<ClientCoupon> generateCouponForOrder({
    required AppUser client,
    required PurchaseOrder order,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != client.uid) {
      throw StateError('Please log in again before generating coupon.');
    }
    if (order.clientId != client.uid) {
      throw StateError('This order does not belong to your account.');
    }
    if (!order.canReceiveReview) {
      throw StateError('Coupon can be generated after seller verifies the payment.');
    }

    final businessDocument =
        await _firestore.collection('businesses').doc(order.businessId).get();
    if (!businessDocument.exists) {
      throw StateError('Business not found.');
    }
    final business = Business.fromDocument(businessDocument);
    if (!business.hasCouponOffer) {
      throw StateError('This seller has not enabled coupons.');
    }
    if (order.totalMvr < business.couponMinimumSpendMvr) {
      throw StateError(
        'This order must be at least ${business.couponMinimumSpendText} to generate coupon.',
      );
    }

    final couponId = '${order.id}_${client.uid}';
    final couponReference = _firestore.collection('coupons').doc(couponId);

    // Use a query instead of couponReference.get() before creating.
    // Direct reads of missing coupon documents can be blocked by Firestore rules.
    final existingCouponSnapshot = await _firestore
        .collection('coupons')
        .where('orderId', isEqualTo: order.id)
        .where('clientId', isEqualTo: client.uid)
        .limit(1)
        .get();
    if (existingCouponSnapshot.docs.isNotEmpty) {
      return ClientCoupon.fromDocument(existingCouponSnapshot.docs.first);
    }

    final suffix = order.id.length >= 5
        ? order.id.substring(0, 5).toUpperCase()
        : order.id.toUpperCase();
    final userPart = client.uid.length >= 4
        ? client.uid.substring(0, 4).toUpperCase()
        : client.uid.toUpperCase();
    final code = 'EH-$suffix-$userPart';

    await couponReference.set({
      'code': code,
      'businessId': business.id,
      'businessName': business.businessName,
      'clientId': client.uid,
      'clientName': client.fullName,
      'orderId': order.id,
      'itemName': order.itemName,
      'purchaseTotalMvr': order.totalMvr,
      'minimumSpendMvr': business.couponMinimumSpendMvr,
      'rewardMvr': business.couponRewardMvr,
      'title': business.couponTitle.trim().isEmpty
          ? 'Customer coupon'
          : business.couponTitle.trim(),
      'terms': business.couponTerms.trim(),
      'redeemed': false,
      'createdAt': FieldValue.serverTimestamp(),
      'redeemedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _createNotification(
      userId: business.businessUserId,
      title: 'New coupon generated',
      body: '${client.fullName} generated coupon $code after buying ${order.itemName}.',
      type: 'coupon_new',
      businessId: business.id,
      orderId: order.id,
    );

    final created = await couponReference.get();
    return ClientCoupon.fromDocument(created);
  }


  Stream<List<AppNotification>> watchNotificationsForUser(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs
          .map(AppNotification.fromDocument)
          .toList();
      notifications.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return notifications;
    });
  }

  Stream<int> watchUnreadNotificationCount(String userId) {
    return watchNotificationsForUser(userId).map(
      (notifications) => notifications.where((notification) => !notification.read).length,
    );
  }

  Future<void> markNotificationRead(AppNotification notification) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != notification.userId) return;
    if (notification.read) return;
    await _firestore.collection('notifications').doc(notification.id).update({
      'read': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAllNotificationsRead(String userId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != userId) return;
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .limit(30)
        .get();
    if (snapshot.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final document in snapshot.docs) {
      batch.update(document.reference, {
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> updateOrderStatus({
    required Business business,
    required PurchaseOrder order,
    required String status,
  }) async {
    _requireBusinessAccount(business);
    if (order.businessId != business.id) {
      throw StateError('This order does not belong to your business.');
    }

    const allowed = <String>{
      'verified',
      'processing',
      'ready',
      'delivered',
      'completed',
    };
    if (!allowed.contains(status)) {
      throw StateError('Unsupported order status.');
    }
    if (order.isRejected || order.isPending) {
      throw StateError('Verify payment before changing the order status.');
    }

    final label = _orderStatusLabel(status);
    await _firestore.collection('orders').doc(order.id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([
        {
          'status': status,
          'label': label,
          'createdAt': Timestamp.now(),
          'by': _auth.currentUser!.uid,
        }
      ]),
    });

    await _createNotification(
      userId: order.clientId,
      title: 'Order update',
      body: '${business.businessName}: ${order.itemName} is now $label.',
      type: 'order_status',
      businessId: business.id,
      orderId: order.id,
    );
  }

  Future<void> acceptQuotation({
    required AppUser client,
    required QuotationRequest request,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != client.uid) {
      throw StateError('Please log in again before accepting quotation.');
    }
    if (request.clientId != client.uid || !request.isQuoted) {
      throw StateError('This quotation cannot be accepted.');
    }

    await _firestore.collection('quotation_requests').doc(request.id).update({
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([
        {
          'status': 'accepted',
          'label': 'Client accepted quotation',
          'createdAt': Timestamp.now(),
          'by': client.uid,
        }
      ]),
    });

    final business = await _firestore.collection('businesses').doc(request.businessId).get();
    final businessUserId = business.data()?['businessUserId']?.toString() ?? '';
    await _createNotification(
      userId: businessUserId,
      title: 'Quotation accepted',
      body: '${client.fullName} accepted your quotation ${request.quotationNumber}.',
      type: 'quote_status',
      businessId: request.businessId,
      quotationId: request.id,
    );
  }

  Future<void> declineQuotation({
    required AppUser client,
    required QuotationRequest request,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != client.uid) {
      throw StateError('Please log in again before declining quotation.');
    }
    if (request.clientId != client.uid || !request.isQuoted) {
      throw StateError('This quotation cannot be declined.');
    }

    await _firestore.collection('quotation_requests').doc(request.id).update({
      'status': 'declined',
      'declinedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([
        {
          'status': 'declined',
          'label': 'Client declined quotation',
          'createdAt': Timestamp.now(),
          'by': client.uid,
        }
      ]),
    });

    final business = await _firestore.collection('businesses').doc(request.businessId).get();
    final businessUserId = business.data()?['businessUserId']?.toString() ?? '';
    await _createNotification(
      userId: businessUserId,
      title: 'Quotation declined',
      body: '${client.fullName} declined your quotation ${request.quotationNumber}.',
      type: 'quote_status',
      businessId: request.businessId,
      quotationId: request.id,
    );
  }

  Stream<List<BusinessReview>> watchBusinessReviews(String businessId) {
    return _firestore
        .collection('reviews')
        .where('businessId', isEqualTo: businessId)
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final reviews = snapshot.docs.map(BusinessReview.fromDocument).toList();
      reviews.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return reviews;
    });
  }

  Stream<ReviewSummary> watchBusinessReviewSummary(String businessId) {
    return watchBusinessReviews(businessId).map((reviews) {
      if (reviews.isEmpty) {
        return const ReviewSummary(count: 0, averageRating: 0);
      }
      final totalRating = reviews.fold<double>(
        0,
        (runningTotal, review) => runningTotal + review.rating.toDouble(),
      );
      return ReviewSummary(
        count: reviews.length,
        averageRating: totalRating / reviews.length,
      );
    });
  }

  Future<void> submitReview({
    required AppUser client,
    required PurchaseOrder order,
    required int rating,
    required String comment,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != client.uid) {
      throw StateError('Please log in again before writing review.');
    }
    if (!order.canReceiveReview || order.clientId != client.uid) {
      throw StateError('You can review only after the seller verifies your order.');
    }
    if (rating < 1 || rating > 5) {
      throw StateError('Select a rating from 1 to 5 stars.');
    }

    final reviewReference = _firestore.collection('reviews').doc('${order.id}_${client.uid}');
    await reviewReference.set({
      'businessId': order.businessId,
      'businessName': order.businessName,
      'clientId': client.uid,
      'clientName': client.fullName,
      'orderId': order.id,
      'itemId': order.itemId,
      'itemName': order.itemName,
      'rating': rating,
      'comment': comment.trim(),
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final business = await _firestore.collection('businesses').doc(order.businessId).get();
    final businessUserId = business.data()?['businessUserId']?.toString() ?? '';
    await _createNotification(
      userId: businessUserId,
      title: 'New review',
      body: '${client.fullName} rated ${order.itemName} $rating stars.',
      type: 'review_new',
      businessId: order.businessId,
      orderId: order.id,
    );
  }

  Future<void> _createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String businessId = '',
    String orderId = '',
    String quotationId = '',
    String chatThreadId = '',
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || userId.trim().isEmpty) return;
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'senderId': currentUser.uid,
        'title': title,
        'body': body.length > 160 ? '${body.substring(0, 157)}...' : body,
        'type': type,
        'businessId': businessId,
        'orderId': orderId,
        'quotationId': quotationId,
        'chatThreadId': chatThreadId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Notifications must never block orders, quotations or chat messages.
    }
  }

  String _orderStatusLabel(String status) {
    switch (status) {
      case 'verified':
        return 'Payment verified';
      case 'processing':
        return 'Processing';
      case 'ready':
        return 'Ready for pickup/delivery';
      case 'delivered':
        return 'Delivered';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  void _requireBusinessAccount(Business business) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw StateError('You must be logged in.');
    }
    if (business.businessUserId != currentUser.uid) {
      throw StateError('This business account cannot manage that business.');
    }
  }

  Future<String> _uploadCatalogImage({
    required String businessId,
    required String itemId,
    required Uint8List bytes,
    required String originalFileName,
    required bool upsert,
  }) async {
    _validateBytes(bytes, maxMegabytes: 5, label: 'item image');
    final imageType = _imageType(originalFileName);
    final path = 'catalog/$businessId/$itemId.${imageType.extension}';

    try {
      await _supabase.storage
          .from(_publicMediaBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              contentType: imageType.contentType,
              upsert: upsert,
            ),
          )
          .timeout(_uploadTimeout);
    } on StorageException catch (error) {
      throw StateError('Item image upload failed: ${error.message}');
    } on TimeoutException {
      throw StateError('Item image upload timed out. Please try again.');
    }

    return _supabase.storage.from(_publicMediaBucket).getPublicUrl(path);
  }

  Future<String> _uploadReceipt({
    required String businessId,
    required String orderId,
    required String clientId,
    required Uint8List bytes,
    required String originalFileName,
  }) async {
    _validateBytes(bytes, maxMegabytes: 8, label: 'payment receipt');
    final imageType = _imageType(originalFileName);
    final path =
        'receipts/$businessId/$orderId/$clientId.${imageType.extension}';

    try {
      await _supabase.storage
          .from(_receiptBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '300',
              contentType: imageType.contentType,
              upsert: false,
            ),
          )
          .timeout(_uploadTimeout);
    } on StorageException catch (error) {
      throw StateError('Receipt upload failed: ${error.message}');
    } on TimeoutException {
      throw StateError('Receipt upload timed out. Please try again.');
    }

    return path;
  }


  Future<String> _uploadQuotationAttachment({
    required String businessId,
    required String requestId,
    required Uint8List bytes,
    required String originalFileName,
  }) async {
    _validateBytes(bytes, maxMegabytes: 8, label: 'quotation attachment');
    final imageType = _imageType(originalFileName);
    final path =
        '$_quotationAttachmentFolder/$businessId/$requestId.${imageType.extension}';

    try {
      await _supabase.storage
          .from(_publicMediaBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              contentType: imageType.contentType,
              upsert: true,
            ),
          )
          .timeout(_uploadTimeout);
    } on StorageException catch (error) {
      throw StateError('Quotation attachment upload failed: ${error.message}');
    } on TimeoutException {
      throw StateError('Quotation attachment upload timed out. Please try again.');
    }

    return path;
  }

  void _validateBytes(
    Uint8List bytes, {
    required int maxMegabytes,
    required String label,
  }) {
    if (bytes.isEmpty) {
      throw StateError('The selected $label is empty.');
    }
    if (bytes.lengthInBytes > maxMegabytes * 1024 * 1024) {
      throw StateError(
        'The $label must be smaller than $maxMegabytes MB.',
      );
    }
  }

  _ImageType _imageType(String fileName) {
    final lowerName = fileName.trim().toLowerCase();
    if (lowerName.endsWith('.png')) {
      return const _ImageType('png', 'image/png');
    }
    if (lowerName.endsWith('.webp')) {
      return const _ImageType('webp', 'image/webp');
    }
    if (lowerName.endsWith('.jpeg')) {
      return const _ImageType('jpeg', 'image/jpeg');
    }
    if (lowerName.endsWith('.jpg')) {
      return const _ImageType('jpg', 'image/jpeg');
    }
    throw StateError(
      'Unsupported image. Select a JPG, JPEG, PNG, or WEBP file.',
    );
  }
}

class _ImageType {
  const _ImageType(this.extension, this.contentType);

  final String extension;
  final String contentType;
}
