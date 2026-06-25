import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/client_coupon.dart';
import '../models/business.dart';
import '../models/purchase_order.dart';
import '../models/quotation_request.dart';
import '../services/business_service.dart';
import '../services/marketplace_service.dart';
import '../utils/coupon_image_saver.dart';

class ClientOrdersPage extends StatelessWidget {
  const ClientOrdersPage({
    super.key,
    required this.client,
    required this.isDhivehi,
    this.showAppBar = true,
  });

  final AppUser client;
  final bool isDhivehi;
  final bool showAppBar;

  String text(String english, String dhivehi) {
    return isDhivehi ? dhivehi : english;
  }

  TextStyle style({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return TextStyle(
      fontFamily: isDhivehi ? 'Faruma' : null,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isDhivehi ? TextDirection.rtl : TextDirection.ltr,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: showAppBar
              ? AppBar(
                  title: Text(
                    text('My Orders', 'އަހަރެންގެ އޯޑަރުތައް'),
                    style: style(fontWeight: FontWeight.bold),
                  ),
                  bottom: TabBar(
                    tabs: [
                      Tab(
                        icon: const Icon(Icons.shopping_bag_rounded),
                        text: text('Orders', 'އޯޑަރު'),
                      ),
                      Tab(
                        icon: const Icon(Icons.request_quote_rounded),
                        text: text('Quotations', 'ކޯޓޭޝަން'),
                      ),
                    ],
                  ),
                )
              : null,
          body: Column(
            children: [
              if (!showAppBar)
                Material(
                  color: Theme.of(context).colorScheme.surface,
                  child: TabBar(
                    tabs: [
                      Tab(
                        icon: const Icon(Icons.shopping_bag_rounded),
                        text: text('Orders', 'އޯޑަރު'),
                      ),
                      Tab(
                        icon: const Icon(Icons.request_quote_rounded),
                        text: text('Quotations', 'ކޯޓޭޝަން'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: TabBarView(
                  children: [
                    _ordersBody(context),
                    _quotationsBody(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ordersBody(BuildContext context) {
    return StreamBuilder<List<PurchaseOrder>>(
      stream: MarketplaceService.instance.watchOrdersForClient(client.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _error(snapshot.error.toString());
        }

        final orders = snapshot.data ?? const <PurchaseOrder>[];
        if (orders.isEmpty) {
          return _empty(
            Icons.shopping_bag_outlined,
            text(
              'You have not placed an order yet.',
              'ތިޔަބާ އަދި އޯޑަރެއް ނުކުރައްވާ.',
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _orderCard(context, orders[index]),
        );
      },
    );
  }

  Widget _quotationsBody(BuildContext context) {
    return StreamBuilder<List<QuotationRequest>>(
      stream: MarketplaceService.instance.watchQuotationRequestsForClient(
        client.uid,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _error(snapshot.error.toString());
        }

        final requests = snapshot.data ?? const <QuotationRequest>[];
        if (requests.isEmpty) {
          return _empty(
            Icons.request_quote_outlined,
            text(
              'You have not requested a quotation yet.',
              'ތިޔަބާ އަދި ކޯޓޭޝަން ރިކުއެސްޓެއް ނުކުރައްވާ.',
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _quotationCard(
            context,
            requests[index],
          ),
        );
      },
    );
  }

  Widget _orderCard(BuildContext context, PurchaseOrder order) {
    final statusColor = order.isRejected
        ? Colors.red
        : order.isPending
            ? Colors.orange
            : Colors.green;
    final statusText = _orderStatusText(order);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 88,
              height: 88,
              child: order.itemImageUrl.isEmpty
                  ? Container(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: const Icon(Icons.inventory_2_rounded, size: 38),
                    )
                  : Image.network(
                      order.itemImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_rounded,
                        size: 38,
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.itemName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: style(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(order.businessName, style: style(fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(
                    '${text('Quantity', 'ޢަދަދު')}: ${order.quantity}',
                    style: style(),
                  ),
                  Text(order.totalText, style: style(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 9),
                  _statusBadge(statusColor, statusText),
                  const SizedBox(height: 10),
                  _orderProgress(context, order),
                  if (order.isRejected && order.rejectionReason.isNotEmpty) ...[
                    const SizedBox(height: 9),
                    Text(
                      '${text('Reason', 'ސަބަބު')}: ${order.rejectionReason}',
                      style: style(color: Colors.red),
                    ),
                  ],
                  if (order.canReceiveReview) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _writeReview(context, order),
                      icon: const Icon(Icons.star_rate_rounded),
                      label: Text(text('Write Review', 'ރިވިއު ލިޔޭ'), style: style()),
                    ),
                  ],
                  _couponArea(context, order),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _orderProgress(BuildContext context, PurchaseOrder order) {
    final steps = <_OrderStepView>[
      _OrderStepView('pending_verification', text('Payment', 'ފައިސާ'), Icons.upload_file_rounded),
      _OrderStepView('verified', text('Verified', 'ވެރިފައިޑް'), Icons.verified_rounded),
      _OrderStepView('processing', text('Processing', 'ޕްރޮސެސް'), Icons.sync_rounded),
      _OrderStepView('ready', text('Ready', 'ރެޑީ'), Icons.inventory_rounded),
      _OrderStepView('completed', text('Done', 'ނިމި'), Icons.check_circle_rounded),
    ];

    final currentIndex = _orderStepIndex(order.status);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(steps.length, (index) {
          final step = steps[index];
          final done = !order.isRejected && index <= currentIndex;
          final active = !order.isRejected && index == currentIndex;
          final color = order.isRejected
              ? Colors.red
              : done
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline;
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: done
                      ? color
                      : color.withValues(alpha: 0.14),
                  child: Icon(
                    order.isRejected && index == currentIndex
                        ? Icons.close_rounded
                        : step.icon,
                    size: 15,
                    color: done ? Colors.white : color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style(
                    fontSize: 9,
                    fontWeight: active ? FontWeight.w900 : FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  int _orderStepIndex(String status) {
    switch (status) {
      case 'verified':
        return 1;
      case 'processing':
        return 2;
      case 'ready':
      case 'delivered':
        return 3;
      case 'completed':
        return 4;
      case 'rejected':
        return 0;
      default:
        return 0;
    }
  }

  Widget _couponArea(BuildContext context, PurchaseOrder order) {
    if (!order.canReceiveReview) return const SizedBox.shrink();

    return StreamBuilder<Business?>(
      stream: BusinessService.instance.watchBusiness(order.businessId),
      builder: (context, businessSnapshot) {
        final business = businessSnapshot.data;
        if (business == null || !business.hasCouponOffer) {
          return const SizedBox.shrink();
        }
        if (order.totalMvr < business.couponMinimumSpendMvr) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<ClientCoupon?>(
          stream: MarketplaceService.instance.watchCouponForOrder(
            orderId: order.id,
            clientId: client.uid,
          ),
          builder: (context, couponSnapshot) {
            final coupon = couponSnapshot.data;
            return Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_activity_rounded),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          coupon == null
                              ? text('Coupon available', 'ކޫޕަން ލިބޭނެ')
                              : text('Coupon generated', 'ކޫޕަން ޖެނެރޭޓްވެއްޖެ'),
                          style: style(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    coupon == null
                        ? text(
                            'This order is eligible because it is above ${business.couponMinimumSpendText}.',
                            'މި އޯޑަރު ${business.couponMinimumSpendText} އަށް މަތީ ކަމުން ކޫޕަން ލިބޭނެ.',
                          )
                        : '${text('Code', 'ކޯޑް')}: ${coupon.code}',
                    style: style(),
                  ),
                  if (coupon == null) ...[
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () => _generateCoupon(context, order),
                      icon: const Icon(Icons.card_giftcard_rounded),
                      label: Text(
                        text('Generate Coupon', 'ކޫޕަން ޖެނެރޭޓްކުރޭ'),
                        style: style(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Text(
                      text(
                        'Generate option is disabled for this order. Seller can see this coupon.',
                        'މި އޯޑަރަށް އަލުން ޖެނެރޭޓް ނުކުރެވޭ. ސެލަރަށް މި ކޫޕަން ފެންނާނެ.',
                      ),
                      style: style(fontSize: 12),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _generateCoupon(BuildContext context, PurchaseOrder order) async {
    try {
      final coupon = await MarketplaceService.instance.generateCouponForOrder(
        client: client,
        order: order,
      );
      final bytes = await _buildCouponImageBytes(coupon);
      final fileName = 'coupon_${coupon.code}.png';
      final savedTo = await saveCouponImageBytes(bytes, fileName);
      if (!context.mounted) return;
      await _showCouponGeneratedDialog(context, coupon, savedTo);
    } catch (error) {
      if (!context.mounted) return;
      _showError(context, error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  Future<void> _showCouponGeneratedDialog(
    BuildContext context,
    ClientCoupon coupon,
    String savedTo,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          text('Coupon generated', 'ކޫޕަން ޖެނެރޭޓްވެއްޖެ'),
          style: style(fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              coupon.code,
              style: style(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(coupon.title, style: style(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              text(
                'Coupon image saved/downloaded: $savedTo',
                'ކޫޕަން އިމޭޖް ސޭވް/ޑައުންލޯޑްވެއްޖެ: $savedTo',
              ),
              style: style(fontSize: 13),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(text('OK', 'އޯކޭ'), style: style()),
          ),
        ],
      ),
    );
  }

  Future<Uint8List> _buildCouponImageBytes(ClientCoupon coupon) async {
    const width = 1080.0;
    const height = 720.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, width, height));
    final background = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), background);

    final borderPaint = Paint()
      ..color = const Color(0xFF006C5B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    final fillPaint = Paint()..color = const Color(0xFFEAF7F3);
    final rect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(50, 50, width - 100, height - 100),
      const Radius.circular(42),
    );
    canvas.drawRRect(rect, fillPaint);
    canvas.drawRRect(rect, borderPaint);

    void drawText(
      String value,
      Offset offset, {
      double fontSize = 36,
      FontWeight fontWeight = FontWeight.normal,
      Color color = const Color(0xFF1D1D1D),
      double maxWidth = 880,
      TextAlign textAlign = TextAlign.left,
    }) {
      final painter = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: textAlign,
        maxLines: 2,
      )..layout(maxWidth: maxWidth);
      painter.paint(canvas, offset);
    }

    drawText(
      'EHFASS VIYAFAARI COUPON',
      const Offset(110, 110),
      fontSize: 42,
      fontWeight: FontWeight.w900,
      color: const Color(0xFF073F91),
    );
    drawText(
      coupon.title,
      const Offset(110, 180),
      fontSize: 34,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF007A5E),
    );
    drawText(
      coupon.code,
      const Offset(110, 270),
      fontSize: 64,
      fontWeight: FontWeight.w900,
      color: const Color(0xFFE97900),
    );
    drawText('Shop: ${coupon.businessName}', const Offset(110, 380));
    drawText('Client: ${coupon.clientName}', const Offset(110, 430));
    drawText('Purchase: ${coupon.purchaseTotalText}', const Offset(110, 480));
    drawText('Reward: ${coupon.rewardText}', const Offset(110, 530));
    if (coupon.terms.isNotEmpty) {
      drawText(
        coupon.terms,
        const Offset(110, 590),
        fontSize: 26,
        maxWidth: 860,
      );
    } else {
      drawText(
        'Show this coupon to the seller before using it.',
        const Offset(110, 590),
        fontSize: 26,
        maxWidth: 860,
      );
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      throw StateError('Could not create coupon image.');
    }
    return data.buffer.asUint8List();
  }

  Widget _quotationCard(BuildContext context, QuotationRequest request) {
    final statusColor = request.isRejected || request.isDeclined
        ? Colors.red
        : request.isPending
            ? Colors.orange
            : Colors.green;
    final statusText = _quotationStatusText(request);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.businessName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                _statusBadge(statusColor, statusText),
              ],
            ),
            if (request.quotationNumber.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(request.quotationNumber, style: style(fontWeight: FontWeight.bold)),
            ],
            const Divider(height: 24),
            ...request.lines.map((line) => _quoteLine(context, line)),
            const Divider(height: 24),
            _moneyRow(text('Requested total', 'ރިކުއެސްޓް ޖުމްލަ'), request.requestedTotalText),
            if (request.isQuoted) ...[
              _moneyRow(text('Delivery fee', 'ޑެލިވަރީ އަގު'), request.deliveryFeeText),
              _moneyRow(text('Discount', 'ޑިސްކައުންޓް'), request.discountText),
              _moneyRow(text('Final quotation', 'ފައިނަލް ކޯޓޭޝަން'), request.finalTotalText),
              if (request.sellerNote.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(request.sellerNote, style: style(height: 1.45)),
              ],
              if (request.quotationAttachmentUrl.isNotEmpty) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _viewQuotationAttachment(context, request),
                  icon: const Icon(Icons.image_rounded),
                  label: Text(text('View Uploaded Quotation', 'އަޕްލޯޑް ކުރި ކޯޓޭޝަން ބަލާ'), style: style()),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _acceptQuotation(context, request),
                      icon: const Icon(Icons.check_circle_rounded),
                      label: Text(text('Accept', 'އެކްސެޕްޓް'), style: style()),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _declineQuotation(context, request),
                      icon: const Icon(Icons.cancel_rounded),
                      label: Text(text('Decline', 'ޑިކްލައިން'), style: style()),
                    ),
                  ),
                ],
              ),
            ],
            if (request.isRejected && request.rejectionReason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${text('Reason', 'ސަބަބު')}: ${request.rejectionReason}',
                style: style(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _quoteLine(BuildContext context, QuotationLine line) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48,
              height: 48,
              child: line.itemImageUrl.isEmpty
                  ? Container(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        line.isService
                            ? Icons.design_services_rounded
                            : Icons.inventory_2_rounded,
                        size: 24,
                      ),
                    )
                  : Image.network(
                      line.itemImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_rounded,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.itemName, style: style(fontWeight: FontWeight.bold)),
                Text(
                  '${line.unitPriceText} × ${line.quantity}',
                  style: style(fontSize: 12),
                ),
              ],
            ),
          ),
          Text(line.lineTotalText, style: style(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _moneyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style(fontWeight: FontWeight.bold))),
          Text(value, style: style(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  String _orderStatusText(PurchaseOrder order) {
    if (order.isVerified) return text('Payment verified', 'ފައިސާ ވެރިފައިކުރެވިއްޖެ');
    if (order.isProcessing) return text('Processing order', 'އޯޑަރ ޕްރޮސެސްކުރަނީ');
    if (order.isReady) return text('Ready for delivery/pickup', 'ޑެލިވަރީ/ޕިކްއަޕަށް ރެޑީ');
    if (order.isDelivered) return text('Delivered', 'ޑެލިވަރޑް');
    if (order.isCompleted) return text('Completed', 'ނިމިއްޖެ');
    if (order.isRejected) return text('Payment rejected', 'ފައިސާ ރިޖެކްޓްކުރެވިއްޖެ');
    return text('Waiting for verification', 'ވެރިފައިކުރުމަށް މަޑުކުރަނީ');
  }

  String _quotationStatusText(QuotationRequest request) {
    if (request.isAccepted) return text('Quotation accepted', 'ކޯޓޭޝަން އެކްސެޕްޓްކުރި');
    if (request.isDeclined) return text('Quotation declined', 'ކޯޓޭޝަން ޑިކްލައިންކުރި');
    if (request.isQuoted) return text('Quotation received', 'ކޯޓޭޝަން ލިބިއްޖެ');
    if (request.isRejected) return text('Request rejected', 'ރިކުއެސްޓް ރިޖެކްޓް');
    return text('Waiting for seller', 'ސެލަރަށް މަޑުކުރަނީ');
  }

  Future<void> _acceptQuotation(
    BuildContext context,
    QuotationRequest request,
  ) async {
    try {
      await MarketplaceService.instance.acceptQuotation(
        client: client,
        request: request,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            text('Quotation accepted.', 'ކޯޓޭޝަން އެކްސެޕްޓްކުރެވިއްޖެ.'),
            style: style(color: Colors.white),
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      _showError(context, error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  Future<void> _declineQuotation(
    BuildContext context,
    QuotationRequest request,
  ) async {
    try {
      await MarketplaceService.instance.declineQuotation(
        client: client,
        request: request,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            text('Quotation declined.', 'ކޯޓޭޝަން ޑިކްލައިންކުރެވިއްޖެ.'),
            style: style(),
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      _showError(context, error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  Future<void> _writeReview(BuildContext context, PurchaseOrder order) async {
    var rating = 5;
    final commentController = TextEditingController();
    final submit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            text('Write Review', 'ރިވިއު ލިޔޭ'),
            style: style(fontWeight: FontWeight.w900),
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.center,
                  children: List.generate(5, (index) {
                    final value = index + 1;
                    return IconButton(
                      onPressed: () => setDialogState(() => rating = value),
                      icon: Icon(
                        value <= rating ? Icons.star_rounded : Icons.star_border_rounded,
                        color: Colors.orange,
                        size: 34,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: commentController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: text('Comment', 'ކޮމެންޓް'),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(text('Cancel', 'ކެންސަލް'), style: style()),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(text('Submit', 'ފޮނުވާ'), style: style()),
            ),
          ],
        ),
      ),
    );

    if (submit != true) {
      commentController.dispose();
      return;
    }

    try {
      await MarketplaceService.instance.submitReview(
        client: client,
        order: order,
        rating: rating,
        comment: commentController.text,
      );
      commentController.dispose();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            text('Review submitted.', 'ރިވިއު ފޮނުވިއްޖެ.'),
            style: style(color: Colors.white),
          ),
        ),
      );
    } catch (error) {
      commentController.dispose();
      if (!context.mounted) return;
      _showError(context, error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(message, style: style(color: Colors.white)),
      ),
    );
  }

  Widget _statusBadge(Color color, String statusText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText,
        style: style(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _empty(IconData icon, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 70),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: style(fontSize: 17),
            ),
          ],
        ),
      ),
    );
  }

  Widget _error(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center, style: style()),
      ),
    );
  }

  Future<void> _viewQuotationAttachment(
    BuildContext context,
    QuotationRequest request,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        text('Uploaded Quotation', 'އަޕްލޯޑް ކުރި ކޯޓޭޝަން'),
                        style: style(fontSize: 19, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: InteractiveViewer(
                  minScale: 0.7,
                  maxScale: 5,
                  child: Image.network(
                    request.quotationAttachmentUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : const Center(child: CircularProgressIndicator()),
                    errorBuilder: (_, __, ___) => const Padding(
                      padding: EdgeInsets.all(30),
                      child: Icon(Icons.broken_image_rounded, size: 70),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _OrderStepView {
  const _OrderStepView(this.status, this.label, this.icon);

  final String status;
  final String label;
  final IconData icon;
}
