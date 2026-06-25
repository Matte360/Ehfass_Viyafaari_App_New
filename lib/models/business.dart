import 'package:cloud_firestore/cloud_firestore.dart';

class Business {
  const Business({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.ownerEmail,
    required this.businessName,
    required this.category,
    required this.contactNumber,
    required this.email,
    required this.island,
    required this.deliveryAvailable,
    required this.deliveryDetails,
    required this.description,
    required this.logoUrl,
    required this.status,
    required this.rejectionReason,
    required this.businessUserId,
    required this.businessLoginEmail,
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    required this.paymentInstructions,
    this.latitude,
    this.longitude,
    this.mapUrl = '',
    this.openingEnabled = false,
    this.openingTime = '08:00',
    this.closingTime = '22:00',
    this.openDays = const <String>['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'],
    this.temporarilyClosed = false,
    this.couponEnabled = false,
    this.couponMinimumSpendMvr = 500,
    this.couponRewardMvr = 0,
    this.couponTitle = 'Customer coupon',
    this.couponTerms = '',
    this.verifiedSeller = false,
    this.featured = false,
    this.sponsored = false,
    this.promotionLabel = '',
    this.submittedAt,
    this.reviewedAt,
    this.businessLoginCreatedAt,
  });

  final String id;
  final String ownerId;
  final String ownerName;
  final String ownerEmail;
  final String businessName;
  final String category;
  final String contactNumber;
  final String email;
  final String island;
  final bool deliveryAvailable;
  final String deliveryDetails;
  final String description;
  final String logoUrl;
  final double? latitude;
  final double? longitude;
  final String mapUrl;
  final String status;
  final String rejectionReason;
  final String businessUserId;
  final String businessLoginEmail;
  final String bankName;
  final String accountName;
  final String accountNumber;
  final String paymentInstructions;
  final bool openingEnabled;
  final String openingTime;
  final String closingTime;
  final List<String> openDays;
  final bool temporarilyClosed;
  final bool couponEnabled;
  final double couponMinimumSpendMvr;
  final double couponRewardMvr;
  final String couponTitle;
  final String couponTerms;
  final bool verifiedSeller;
  final bool featured;
  final bool sponsored;
  final String promotionLabel;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final DateTime? businessLoginCreatedAt;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get hasBusinessLogin => businessUserId.isNotEmpty;
  bool get hasPaymentAccount =>
      bankName.isNotEmpty && accountName.isNotEmpty && accountNumber.isNotEmpty;
  bool get hasCouponOffer => couponEnabled && couponMinimumSpendMvr > 0;
  bool get isTrustedSeller => isApproved && (verifiedSeller || businessUserId.isNotEmpty);
  bool get isFeatured => isApproved && featured;
  bool get isSponsored => isApproved && sponsored;
  String get trustBadgeText => verifiedSeller ? 'Verified seller' : 'Approved seller';
  String get promotionBadgeText {
    if (promotionLabel.trim().isNotEmpty) return promotionLabel.trim();
    if (isSponsored) return 'Sponsored';
    if (isFeatured) return 'Featured';
    return '';
  }
  String get couponMinimumSpendText =>
      'MVR ${couponMinimumSpendMvr.toStringAsFixed(2)}';
  String get couponRewardText => couponRewardMvr > 0
      ? 'MVR ${couponRewardMvr.toStringAsFixed(2)}'
      : 'Special seller coupon';

  bool get isOpenNow => openStatus(DateTime.now()).isOpen;

  BusinessOpenStatus openStatus(DateTime now) {
    if (temporarilyClosed) {
      return const BusinessOpenStatus(
        isOpen: false,
        english: 'Temporarily closed',
        dhivehi: 'މިހާރު ބަންދުވެފައި',
      );
    }

    if (!openingEnabled) {
      return const BusinessOpenStatus(
        isOpen: true,
        english: 'Open',
        dhivehi: 'ހުޅުވިފައި',
      );
    }

    final today = _dayKey(now.weekday);
    if (!openDays.contains(today)) {
      return const BusinessOpenStatus(
        isOpen: false,
        english: 'Closed today',
        dhivehi: 'މިއަދު ބަންދު',
      );
    }

    final openMinute = _minutesFromTime(openingTime);
    final closeMinute = _minutesFromTime(closingTime);
    final nowMinute = now.hour * 60 + now.minute;

    if (openMinute == null || closeMinute == null || openMinute == closeMinute) {
      return const BusinessOpenStatus(
        isOpen: true,
        english: 'Open',
        dhivehi: 'ހުޅުވިފައި',
      );
    }

    final open = openMinute < closeMinute
        ? nowMinute >= openMinute && nowMinute < closeMinute
        : nowMinute >= openMinute || nowMinute < closeMinute;

    if (open) {
      return BusinessOpenStatus(
        isOpen: true,
        english: 'Open now • closes $closingTime',
        dhivehi: 'މިހާރު ހުޅުވިފައި • $closingTime ބަންދުވާނެ',
      );
    }

    return BusinessOpenStatus(
      isOpen: false,
      english: 'Closed • opens $openingTime',
      dhivehi: 'ބަންދު • $openingTime ހުޅުވާނެ',
    );
  }

  String hoursSummary({required bool isDhivehi}) {
    if (temporarilyClosed) {
      return isDhivehi ? 'މިހާރު ބަންދުވެފައި' : 'Temporarily closed';
    }
    if (!openingEnabled) {
      return isDhivehi ? 'ހުޅުވިފައި' : 'Open';
    }
    return '$openingTime - $closingTime';
  }

  static String _dayKey(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'mon';
      case DateTime.tuesday:
        return 'tue';
      case DateTime.wednesday:
        return 'wed';
      case DateTime.thursday:
        return 'thu';
      case DateTime.friday:
        return 'fri';
      case DateTime.saturday:
        return 'sat';
      default:
        return 'sun';
    }
  }

  static int? _minutesFromTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return hour * 60 + minute;
  }

  factory Business.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};

    double? readDouble(Object? value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '');
    }

    DateTime? readDate(Object? value) {
      return value is Timestamp ? value.toDate() : null;
    }

    List<String> readDays(Object? value) {
      if (value is Iterable) {
        final days = value.map((day) => day.toString()).toList();
        if (days.isNotEmpty) return days;
      }
      return const <String>['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    }

    return Business(
      id: document.id,
      ownerId: data['ownerId']?.toString() ?? '',
      ownerName: data['ownerName']?.toString() ?? '',
      ownerEmail: data['ownerEmail']?.toString() ?? '',
      businessName: data['businessName']?.toString() ?? '',
      category: data['category']?.toString() ?? '',
      contactNumber: data['contactNumber']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      island: data['island']?.toString() ?? '',
      deliveryAvailable: data['deliveryAvailable'] == true,
      deliveryDetails: data['deliveryDetails']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      logoUrl: data['logoUrl']?.toString() ?? '',
      latitude: readDouble(data['latitude']),
      longitude: readDouble(data['longitude']),
      mapUrl: data['mapUrl']?.toString() ?? '',
      status: data['status']?.toString() ?? 'pending',
      rejectionReason: data['rejectionReason']?.toString() ?? '',
      businessUserId: data['businessUserId']?.toString() ?? '',
      businessLoginEmail: data['businessLoginEmail']?.toString() ?? '',
      bankName: data['bankName']?.toString() ?? '',
      accountName: data['accountName']?.toString() ?? '',
      accountNumber: data['accountNumber']?.toString() ?? '',
      paymentInstructions: data['paymentInstructions']?.toString() ?? '',
      openingEnabled: data['openingEnabled'] == true,
      openingTime: data['openingTime']?.toString() ?? '08:00',
      closingTime: data['closingTime']?.toString() ?? '22:00',
      openDays: readDays(data['openDays']),
      temporarilyClosed: data['temporarilyClosed'] == true,
      couponEnabled: data['couponEnabled'] == true,
      couponMinimumSpendMvr: readDouble(data['couponMinimumSpendMvr']) ?? 500,
      couponRewardMvr: readDouble(data['couponRewardMvr']) ?? 0,
      couponTitle: data['couponTitle']?.toString() ?? 'Customer coupon',
      couponTerms: data['couponTerms']?.toString() ?? '',
      verifiedSeller: data['verifiedSeller'] == true,
      featured: data['featured'] == true,
      sponsored: data['sponsored'] == true,
      promotionLabel: data['promotionLabel']?.toString() ?? '',
      submittedAt: readDate(data['submittedAt']),
      reviewedAt: readDate(data['reviewedAt']),
      businessLoginCreatedAt: readDate(data['businessLoginCreatedAt']),
    );
  }
}

class BusinessOpenStatus {
  const BusinessOpenStatus({
    required this.isOpen,
    required this.english,
    required this.dhivehi,
  });

  final bool isOpen;
  final String english;
  final String dhivehi;

  String label({required bool isDhivehi}) => isDhivehi ? dhivehi : english;
}
