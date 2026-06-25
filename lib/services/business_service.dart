import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../firebase_options.dart';
import '../models/app_user.dart';
import '../models/business.dart';

class BusinessService {
  BusinessService._();

  static final BusinessService instance = BusinessService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _mediaBucket = 'business-media';

  static const Duration _storageTimeout = Duration(seconds: 30);
  static const Duration _firestoreTimeout = Duration(seconds: 15);

  Stream<Business?> watchBusiness(String businessId) {
    if (businessId.isEmpty) {
      return Stream.value(null);
    }

    return _firestore.collection('businesses').doc(businessId).snapshots().map(
      (document) {
        if (!document.exists) {
          return null;
        }

        return Business.fromDocument(document);
      },
    );
  }

  Stream<List<Business>> watchApprovedBusinesses() {
    return _firestore
        .collection('businesses')
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) {
      final businesses = snapshot.docs.map(Business.fromDocument).toList();

      businesses.sort(
        (a, b) => a.businessName.toLowerCase().compareTo(
              b.businessName.toLowerCase(),
            ),
      );

      return businesses;
    });
  }

  Stream<List<Business>> watchBusinessesForOwner(String ownerId) {
    return _firestore
        .collection('businesses')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
      final businesses = snapshot.docs.map(Business.fromDocument).toList();

      businesses.sort((a, b) {
        final aDate =
            a.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate =
            b.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      });

      return businesses;
    });
  }

  Stream<List<Business>> watchAllBusinesses() {
    return _firestore.collection('businesses').snapshots().map((snapshot) {
      final businesses = snapshot.docs.map(Business.fromDocument).toList();

      businesses.sort((a, b) {
        final aDate =
            a.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate =
            b.submittedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      });

      return businesses;
    });
  }

  Stream<List<AppUser>> watchClients() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'client')
        .snapshots()
        .map((snapshot) {
      final users = snapshot.docs.map(AppUser.fromDocument).toList();

      users.sort(
        (a, b) => a.fullName.toLowerCase().compareTo(
              b.fullName.toLowerCase(),
            ),
      );

      return users;
    });
  }



  Future<void> updateBusinessLocation({
    required Business business,
    required String island,
    required double? latitude,
    required double? longitude,
    String mapUrl = '',
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != business.businessUserId) {
      throw StateError('Only the linked business account can update location.');
    }

    final cleanIsland = island.trim();
    if (cleanIsland.isEmpty) {
      throw StateError('Island or location name is required.');
    }

    await _firestore.collection('businesses').doc(business.id).update({
      'island': cleanIsland,
      'islandLower': cleanIsland.toLowerCase(),
      'latitude': latitude,
      'longitude': longitude,
      'mapUrl': mapUrl.trim(),
      'locationUpdatedAt': FieldValue.serverTimestamp(),
    }).timeout(_firestoreTimeout);
  }


  Future<void> updateBusinessOpeningHours({
    required Business business,
    required bool openingEnabled,
    required String openingTime,
    required String closingTime,
    required List<String> openDays,
    required bool temporarilyClosed,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != business.businessUserId) {
      throw StateError('Only the linked business account can update opening hours.');
    }

    await _firestore.collection('businesses').doc(business.id).update({
      'openingEnabled': openingEnabled,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'openDays': openDays,
      'temporarilyClosed': temporarilyClosed,
      'openingHoursUpdatedAt': FieldValue.serverTimestamp(),
    }).timeout(_firestoreTimeout);
  }



  Future<void> updateBusinessCouponOffer({
    required Business business,
    required bool couponEnabled,
    required double couponMinimumSpendMvr,
    required double couponRewardMvr,
    required String couponTitle,
    required String couponTerms,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != business.businessUserId) {
      throw StateError('Only the linked business account can update coupon settings.');
    }
    if (couponEnabled && couponMinimumSpendMvr <= 0) {
      throw StateError('Minimum purchase amount must be more than MVR 0.00.');
    }
    if (couponRewardMvr < 0) {
      throw StateError('Coupon reward cannot be negative.');
    }

    await _firestore.collection('businesses').doc(business.id).update({
      'couponEnabled': couponEnabled,
      'couponMinimumSpendMvr': couponEnabled ? couponMinimumSpendMvr : 0,
      'couponRewardMvr': couponEnabled ? couponRewardMvr : 0,
      'couponTitle': couponTitle.trim().isEmpty
          ? 'Customer coupon'
          : couponTitle.trim(),
      'couponTerms': couponTerms.trim(),
      'couponUpdatedAt': FieldValue.serverTimestamp(),
    }).timeout(_firestoreTimeout);
  }

  Future<String> _uploadLogoToSupabase({
    required String businessId,
    required Uint8List bytes,
    required String originalFileName,
  }) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw StateError('You must be logged in.');
    }

    if (bytes.isEmpty) {
      throw StateError('The selected business image is empty.');
    }

    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      throw StateError('The business image must be smaller than 5 MB.');
    }

    final imageType = _getImageType(originalFileName);
    final extension = imageType.$1;
    final contentType = imageType.$2;

    final safeUserId = currentUser.uid.replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );

    final storagePath =
        'businesses/$safeUserId/$businessId.$extension';

    try {
      await _supabase.storage
          .from(_mediaBucket)
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              contentType: contentType,
              upsert: false,
            ),
          )
          .timeout(_storageTimeout);

      return _supabase.storage
          .from(_mediaBucket)
          .getPublicUrl(storagePath);
    } on TimeoutException {
      throw StateError(
        'The image upload took too long. Check your internet and try again.',
      );
    } on StorageException catch (error) {
      throw StateError(
        'Supabase image upload failed: ${error.message}',
      );
    }
  }

  (String, String) _getImageType(String fileName) {
    final lowerName = fileName.trim().toLowerCase();

    if (lowerName.endsWith('.png')) {
      return ('png', 'image/png');
    }

    if (lowerName.endsWith('.webp')) {
      return ('webp', 'image/webp');
    }

    if (lowerName.endsWith('.jpeg')) {
      return ('jpeg', 'image/jpeg');
    }

    if (lowerName.endsWith('.jpg')) {
      return ('jpg', 'image/jpeg');
    }

    throw StateError(
      'Unsupported image format. Please select a JPG, JPEG, PNG, or WEBP image.',
    );
  }

  Future<void> submitBusiness({
    required AppUser owner,
    required String businessName,
    required String category,
    required String contactNumber,
    required String email,
    required String island,
    required bool deliveryAvailable,
    required String deliveryDetails,
    required String description,
    Uint8List? logoBytes,
    String? logoFileName,
    double? latitude,
    double? longitude,
    String mapUrl = '',
  }) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null || currentUser.uid != owner.uid) {
      throw StateError(
        'Your login session is invalid. Please log in again.',
      );
    }

    final reference = _firestore.collection('businesses').doc();
    String logoUrl = '';

    if (logoBytes != null && logoFileName != null) {
      logoUrl = await _uploadLogoToSupabase(
        businessId: reference.id,
        bytes: logoBytes,
        originalFileName: logoFileName,
      );
    }

    try {
      await reference.set({
        'ownerId': owner.uid,
        'ownerName': owner.fullName,
        'ownerEmail': owner.email,
        'businessName': businessName.trim(),
        'businessNameLower': businessName.trim().toLowerCase(),
        'category': category.trim(),
        'categoryLower': category.trim().toLowerCase(),
        'contactNumber': contactNumber.trim(),
        'email': email.trim().toLowerCase(),
        'island': island.trim(),
        'islandLower': island.trim().toLowerCase(),
        'deliveryAvailable': deliveryAvailable,
        'deliveryDetails': deliveryDetails.trim(),
        'description': description.trim(),
        'logoUrl': logoUrl,
        'latitude': latitude,
        'longitude': longitude,
        'mapUrl': mapUrl.trim(),
        'status': 'pending',
        'rejectionReason': '',
        'openingEnabled': false,
        'openingTime': '08:00',
        'closingTime': '22:00',
        'openDays': ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'],
        'temporarilyClosed': false,
        'couponEnabled': false,
        'couponMinimumSpendMvr': 500,
        'couponRewardMvr': 0,
        'couponTitle': 'Customer coupon',
        'couponTerms': '',
        'submittedAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
        'reviewedBy': '',
        'businessUserId': '',
        'businessLoginEmail': '',
        'businessLoginCreatedAt': null,
      }).timeout(_firestoreTimeout);
    } on TimeoutException {
      throw StateError(
        'The request took too long. Check your internet connection and try again.',
      );
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw StateError(
          'Firestore permission denied. Publish the Firestore rules and try again.',
        );
      }

      throw StateError(
        error.message ?? 'Firebase error: ${error.code}',
      );
    }
  }

  Future<void> approveBusinessAndCreateLogin({
    required Business business,
    required String loginEmail,
    required String temporaryPassword,
  }) async {
    final admin = _auth.currentUser;

    if (admin == null) {
      throw StateError(
        'You must be logged in as an administrator.',
      );
    }

    if (business.hasBusinessLogin) {
      throw StateError(
        'A business login already exists for this business.',
      );
    }

    final cleanEmail = loginEmail.trim().toLowerCase();

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
        .hasMatch(cleanEmail)) {
      throw StateError('Enter a valid business login email.');
    }

    if (temporaryPassword.length < 8) {
      throw StateError(
        'The temporary password must have at least 8 characters.',
      );
    }

    _CreatedBusinessAuthAccount? createdAccount;

    try {
      // Do not use FirebaseAuth.createUserWithEmailAndPassword on the default
      // app here. Even with a secondary app, Flutter web can rebuild the admin
      // auth gate while the approval dialog is being disposed. Creating the
      // business Firebase Auth account through the Identity Toolkit REST API
      // keeps the currently signed-in admin session stable.
      createdAccount = await _createBusinessAuthAccountWithRestApi(
        email: cleanEmail,
        password: temporaryPassword,
        displayName: business.businessName,
      );

      final businessUserReference =
          _firestore.collection('users').doc(createdAccount.uid);

      final businessReference =
          _firestore.collection('businesses').doc(business.id);

      final batch = _firestore.batch();

      batch.set(businessUserReference, {
        'uid': createdAccount.uid,
        'fullName': business.businessName,
        'username': '',
        'usernameLower': '',
        'phone': business.contactNumber,
        'email': cleanEmail,
        'role': 'business',
        'businessId': business.id,
        'businessName': business.businessName,
        'profileImageUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      batch.update(businessReference, {
        'status': 'approved',
        'rejectionReason': '',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': admin.uid,
        'businessUserId': createdAccount.uid,
        'businessLoginEmail': cleanEmail,
        'businessLoginCreatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit().timeout(_firestoreTimeout);
    } on TimeoutException {
      throw StateError(
        'Creating the business login took too long. Check the internet connection and try again.',
      );
    } catch (error) {
      if (createdAccount != null) {
        try {
          await _deleteBusinessAuthAccountWithRestApi(createdAccount.idToken);
        } catch (_) {
          // Keep the original approval error.
        }
      }

      rethrow;
    }
  }


  String get _firebaseApiKey => DefaultFirebaseOptions.currentPlatform.apiKey;

  Future<_CreatedBusinessAuthAccount> _createBusinessAuthAccountWithRestApi({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final uri = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_firebaseApiKey',
    );

    final response = await http
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'password': password,
            'returnSecureToken': true,
          }),
        )
        .timeout(_firestoreTimeout);

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorMessage = (decoded['error'] as Map<String, dynamic>?)?['message']
              ?.toString() ??
          'AUTH_ACCOUNT_CREATE_FAILED';
      throw StateError(_friendlyAuthRestError(errorMessage));
    }

    final uid = decoded['localId']?.toString() ?? '';
    final idToken = decoded['idToken']?.toString() ?? '';

    if (uid.isEmpty || idToken.isEmpty) {
      throw StateError('The business Firebase account could not be created.');
    }

    await _updateBusinessAuthDisplayName(
      idToken: idToken,
      displayName: displayName,
    );

    return _CreatedBusinessAuthAccount(uid: uid, idToken: idToken);
  }

  Future<void> _updateBusinessAuthDisplayName({
    required String idToken,
    required String displayName,
  }) async {
    final cleanName = displayName.trim();
    if (cleanName.isEmpty) return;

    final uri = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:update?key=$_firebaseApiKey',
    );

    try {
      await http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'idToken': idToken,
              'displayName': cleanName,
              'returnSecureToken': false,
            }),
          )
          .timeout(_firestoreTimeout);
    } catch (_) {
      // The Firestore business profile still stores the business name, so this
      // optional Firebase Auth display name update should not block approval.
    }
  }

  Future<void> _deleteBusinessAuthAccountWithRestApi(String idToken) async {
    if (idToken.isEmpty) return;

    final uri = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:delete?key=$_firebaseApiKey',
    );

    await http
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'idToken': idToken}),
        )
        .timeout(_firestoreTimeout);
  }

  String _friendlyAuthRestError(String errorMessage) {
    return switch (errorMessage) {
      'EMAIL_EXISTS' =>
        'This email is already used by another Firebase account. Use a different business login email.',
      'INVALID_EMAIL' => 'The business login email is invalid.',
      'WEAK_PASSWORD : Password should be at least 6 characters' =>
        'The temporary password is too weak.',
      'OPERATION_NOT_ALLOWED' =>
        'Email/password login is not enabled in Firebase Authentication.',
      _ => 'Firebase Auth error: $errorMessage',
    };
  }

  Future<void> rejectBusiness({
    required String businessId,
    required String reason,
  }) async {
    final admin = _auth.currentUser;

    if (admin == null) {
      throw StateError('You must be logged in.');
    }

    await _firestore.collection('businesses').doc(businessId).update({
      'status': 'rejected',
      'rejectionReason': reason.trim(),
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': admin.uid,
    });
  }
}

class _CreatedBusinessAuthAccount {
  const _CreatedBusinessAuthAccount({
    required this.uid,
    required this.idToken,
  });

  final String uid;
  final String idToken;
}
