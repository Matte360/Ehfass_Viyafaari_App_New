import 'package:flutter/material.dart';

import '../models/business.dart';
import '../models/client_coupon.dart';
import '../services/marketplace_service.dart';

class BusinessCouponsPage extends StatelessWidget {
  const BusinessCouponsPage({
    super.key,
    required this.business,
    required this.isDhivehi,
  });

  final Business business;
  final bool isDhivehi;

  String text(String english, String dhivehi) {
    return isDhivehi ? dhivehi : english;
  }

  TextStyle style({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: isDhivehi ? 'Faruma' : null,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isDhivehi ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            text('Client Coupons', 'ކްލައިންޓް ކޫޕަންތައް'),
            style: style(fontWeight: FontWeight.bold),
          ),
        ),
        body: StreamBuilder<List<ClientCoupon>>(
          stream: MarketplaceService.instance.watchCouponsForBusiness(business.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(snapshot.error.toString(), style: style()),
                ),
              );
            }
            final coupons = snapshot.data ?? const <ClientCoupon>[];
            if (coupons.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_activity_outlined, size: 70),
                      const SizedBox(height: 14),
                      Text(
                        text(
                          'No client coupons generated yet.',
                          'އަދި ކްލައިންޓް ކޫޕަނެއް ޖެނެރޭޓް ނުކުރެވޭ.',
                        ),
                        textAlign: TextAlign.center,
                        style: style(fontSize: 17),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: coupons.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _couponCard(context, coupons[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _couponCard(BuildContext context, ClientCoupon coupon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: const Icon(Icons.local_activity_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        coupon.code,
                        style: style(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      Text(coupon.title, style: style(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Chip(
                  avatar: Icon(
                    coupon.redeemed
                        ? Icons.check_circle_rounded
                        : Icons.hourglass_top_rounded,
                    size: 18,
                  ),
                  label: Text(
                    coupon.redeemed
                        ? text('Redeemed', 'ބޭނުންކުރެވިފައި')
                        : text('Active', 'އެކްޓިވް'),
                    style: style(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _row(text('Client', 'ކްލައިންޓް'), coupon.clientName),
            _row(text('Order item', 'އޯޑަރުގެ މުދަލު'), coupon.itemName),
            _row(text('Purchase total', 'ހޯދި ޖުމްލަ'), coupon.purchaseTotalText),
            _row(text('Minimum spend', 'މިނިމަމް'), coupon.minimumSpendText),
            _row(text('Reward', 'ރިވޯޑް'), coupon.rewardText),
            if (coupon.terms.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(coupon.terms, style: style()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(label, style: style(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: SelectableText(value.isEmpty ? '-' : value, style: style())),
        ],
      ),
    );
  }
}
