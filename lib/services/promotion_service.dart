import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/business.dart';
import '../models/promotion_request.dart';

class PromotionService {
  PromotionService._();

  static final PromotionService instance = PromotionService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<PromotionRequestModel>> watchForBusiness(String businessId) {
    return _firestore
        .collection('promotion_requests')
        .where('businessId', isEqualTo: businessId)
        .snapshots()
        .map(_fromSnapshot);
  }

  Stream<List<PromotionRequestModel>> watchAll() {
    return _firestore
        .collection('promotion_requests')
        .snapshots()
        .map(_fromSnapshot);
  }

  List<PromotionRequestModel> _fromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final requests = snapshot.docs
        .map(PromotionRequestModel.fromDocument)
        .toList();
    requests.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return requests;
  }

  Future<void> requestPromotion({
    required Business business,
    required String plan,
    required String note,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != business.businessUserId) {
      throw StateError('Only the linked seller account can request promotion.');
    }

    final allowed = {'featured_shop', 'sponsored_shop', 'verified_badge'};
    if (!allowed.contains(plan)) {
      throw StateError('Choose a valid promotion plan.');
    }

    await _firestore.collection('promotion_requests').add({
      'businessId': business.id,
      'businessName': business.businessName,
      'sellerId': currentUser.uid,
      'plan': plan,
      'note': note.trim(),
      'status': 'pending',
      'rejectionReason': '',
      'createdAt': FieldValue.serverTimestamp(),
      'reviewedAt': null,
      'reviewedBy': '',
    });
  }

  Future<void> updateStatus({
    required PromotionRequestModel request,
    required String status,
    String rejectionReason = '',
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw StateError('Please log in again.');
    }
    if (status != 'approved' && status != 'rejected') {
      throw StateError('Unsupported promotion status.');
    }

    final batch = _firestore.batch();
    final requestReference =
        _firestore.collection('promotion_requests').doc(request.id);

    batch.update(requestReference, {
      'status': status,
      'rejectionReason': status == 'rejected' ? rejectionReason.trim() : '',
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': currentUser.uid,
    });

    if (status == 'approved') {
      final businessReference =
          _firestore.collection('businesses').doc(request.businessId);
      final update = <String, dynamic>{
        'promotionApprovedAt': FieldValue.serverTimestamp(),
      };

      if (request.plan == 'featured_shop') {
        update['featured'] = true;
        update['sponsored'] = false;
        update['promotionLabel'] = 'Featured';
        update['verifiedSeller'] = true;
      } else if (request.plan == 'sponsored_shop') {
        update['featured'] = true;
        update['sponsored'] = true;
        update['promotionLabel'] = 'Sponsored';
        update['verifiedSeller'] = true;
      } else if (request.plan == 'verified_badge') {
        update['verifiedSeller'] = true;
      }

      batch.update(businessReference, update);
    }

    await batch.commit();
  }
}
