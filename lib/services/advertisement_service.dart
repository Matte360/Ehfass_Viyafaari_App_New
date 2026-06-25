import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/advertisement_request.dart';
import '../models/app_user.dart';

class AdvertisementService {
  AdvertisementService._();

  static final AdvertisementService instance = AdvertisementService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> submit({
    required AppUser owner,
    required String businessName,
    required String title,
    required String contactNumber,
    required String duration,
    required String details,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != owner.uid) {
      throw StateError('Your login session is invalid.');
    }

    await _firestore.collection('advertisement_requests').add({
      'ownerId': owner.uid,
      'ownerName': owner.fullName,
      'businessName': businessName.trim(),
      'title': title.trim(),
      'contactNumber': contactNumber.trim(),
      'duration': duration,
      'details': details.trim(),
      'status': 'pending',
      'rejectionReason': '',
      'submittedAt': FieldValue.serverTimestamp(),
      'reviewedAt': null,
      'reviewedBy': '',
    });
  }

  Stream<List<AdvertisementRequestModel>> watchAll() {
    return _firestore
        .collection('advertisement_requests')
        .snapshots()
        .map((snapshot) {
      final requests =
          snapshot.docs.map(AdvertisementRequestModel.fromDocument).toList();
      requests.sort((a, b) {
        final aDate = a.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return requests;
    });
  }

  Future<void> updateStatus({
    required String requestId,
    required String status,
    String rejectionReason = '',
  }) async {
    final admin = _auth.currentUser;
    if (admin == null) throw StateError('You must be logged in.');

    await _firestore
        .collection('advertisement_requests')
        .doc(requestId)
        .update({
      'status': status,
      'rejectionReason': rejectionReason.trim(),
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': admin.uid,
    });
  }
}
