import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/business.dart';
import '../models/quotation_request.dart';
import '../services/marketplace_service.dart';
import '../utils/image_crop_helper.dart';

class QuotationRequestsPage extends StatefulWidget {
  const QuotationRequestsPage({
    super.key,
    required this.business,
    required this.isDhivehi,
  });

  final Business business;
  final bool isDhivehi;

  @override
  State<QuotationRequestsPage> createState() => _QuotationRequestsPageState();
}

class _QuotationRequestsPageState extends State<QuotationRequestsPage> {
  final _picker = ImagePicker();
  String _filter = 'pending';
  String? _workingRequestId;

  String text(String english, String dhivehi) {
    return widget.isDhivehi ? dhivehi : english;
  }

  TextStyle style({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return TextStyle(
      fontFamily: widget.isDhivehi ? 'Faruma' : null,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: StreamBuilder<List<QuotationRequest>>(
      stream: MarketplaceService.instance.watchQuotationRequestsForBusiness(
        widget.business.id,
      ),
      builder: (context, snapshot) {
        final all = snapshot.data ?? const <QuotationRequest>[];
        final requests = _filter == 'all'
            ? all
            : all.where((request) => request.status == _filter).toList();

        return Column(
          children: [
            SizedBox(
              height: 62,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                children: [
                  _filterChip('pending', text('Pending', 'ޕެންޑިންގް')),
                  _filterChip('quoted', text('Quoted', 'ކޯޓް ކުރި')),
                  _filterChip('accepted', text('Accepted', 'އެކްސެޕްޓް')),
                  _filterChip('declined', text('Declined', 'ޑިކްލައިން')),
                  _filterChip('rejected', text('Rejected', 'ރިޖެކްޓް')),
                  _filterChip('all', text('All', 'ހުރިހާ')),
                ],
              ),
            ),
            Expanded(
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : snapshot.hasError
                      ? Center(child: Text(snapshot.error.toString()))
                      : requests.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.request_quote_outlined,
                                      size: 70,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      text(
                                        'No quotation requests in this section.',
                                        'މި ބައިގައި ކޯޓޭޝަން ރިކުއެސްޓެއް ނެތް.',
                                      ),
                                      textAlign: TextAlign.center,
                                      style: style(fontSize: 17),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                              itemCount: requests.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, index) =>
                                  _quotationCard(requests[index]),
                            ),
            ),
          ],
        );
      },
    ),
    );
  }

  Widget _filterChip(String value, String label) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Material(
        type: MaterialType.transparency,
        child: ChoiceChip(
          selected: _filter == value,
          onSelected: (_) => setState(() => _filter = value),
          avatar: _filter == value ? const Icon(Icons.check_rounded, size: 17) : null,
          label: Text(label, style: style(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _quotationCard(QuotationRequest request) {
    final working = _workingRequestId == request.id;
    final statusColor = request.isRejected || request.isDeclined
        ? Colors.red
        : request.isPending
            ? Colors.orange
            : Colors.green;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.clientName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: style(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(widget.business.businessName, style: style(fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusText(request),
                    style: style(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _detail(Icons.phone_rounded, request.clientPhone),
            _detail(Icons.email_rounded, request.clientEmail),
            if (request.clientNote.isNotEmpty)
              _detail(Icons.message_rounded, request.clientNote),
            const Divider(height: 24),
            Text(
              text('Requested items', 'ރިކުއެސްޓް ކުރި މުދާ'),
              style: style(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            ...request.lines.map(_lineTile),
            const Divider(height: 24),
            _moneyRow(text('Requested total', 'ރިކުއެސްޓް ޖުމްލަ'), request.requestedTotalText),
            if (request.isQuoted) ...[
              _moneyRow(text('Delivery fee', 'ޑެލިވަރީ އަގު'), request.deliveryFeeText),
              _moneyRow(text('Discount', 'ޑިސްކައުންޓް'), request.discountText),
              _moneyRow(text('Final quotation', 'ފައިނަލް ކޯޓޭޝަން'), request.finalTotalText),
              if (request.quotationNumber.isNotEmpty)
                _detail(Icons.confirmation_number_rounded, request.quotationNumber),
              if (request.sellerNote.isNotEmpty)
                _detail(Icons.note_alt_rounded, request.sellerNote),
              if (request.quotationAttachmentUrl.isNotEmpty) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _viewAttachment(request),
                  icon: const Icon(Icons.image_rounded),
                  label: Text(text('View Uploaded Quotation', 'އަޕްލޯޑް ކުރި ކޯޓޭޝަން ބަލާ'), style: style()),
                ),
              ],
            ],
            if (request.isRejected && request.rejectionReason.isNotEmpty)
              _detail(Icons.info_outline_rounded, request.rejectionReason),
            if (request.isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: working ? null : () => _generateQuotation(request),
                      icon: working
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.request_quote_rounded),
                      label: Text(
                        text('Generate Quotation', 'ކޯޓޭޝަން ހަދާ'),
                        style: style(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: working ? null : () => _rejectQuotation(request),
                      icon: const Icon(Icons.close_rounded),
                      label: Text(text('Reject', 'ރިޖެކްޓް'), style: style()),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _lineTile(QuotationLine line) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 46,
              height: 46,
              child: line.itemImageUrl.isEmpty
                  ? Container(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        line.isService
                            ? Icons.design_services_rounded
                            : Icons.inventory_2_rounded,
                        size: 22,
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
                Text(
                  line.itemName,
                  style: style(fontWeight: FontWeight.bold),
                ),
                if (line.promotionActive && line.oldUnitPriceMvr > line.unitPriceMvr)
                  Text(
                    line.oldUnitPriceText,
                    style: style(
                      fontSize: 12,
                      color: Colors.red,
                    ).copyWith(
                      decoration: TextDecoration.lineThrough,
                      decorationColor: Colors.red,
                      decorationThickness: 2,
                    ),
                  ),
                Text(
                  '${line.unitPriceText} × ${line.quantity}',
                  style: style(fontSize: 12),
                ),
                if (line.lineDiscountMvr > 0)
                  Text(
                    '${text('Discount', 'ޑިސްކައުންޓް')}: ${line.lineDiscountText}',
                    style: style(fontSize: 12, color: Colors.deepOrange),
                  ),
              ],
            ),
          ),
          Text(line.lineTotalText, style: style(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _detail(IconData icon, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: SelectableText(value, style: style())),
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

  String _statusText(QuotationRequest request) {
    if (request.isAccepted) return text('Accepted', 'އެކްސެޕްޓް');
    if (request.isDeclined) return text('Declined', 'ޑިކްލައިން');
    if (request.isQuoted) return text('Quoted', 'ކޯޓް ކުރި');
    if (request.isRejected) return text('Rejected', 'ރިޖެކްޓް');
    return text('Pending', 'ޕެންޑިންގް');
  }

  Future<void> _generateQuotation(QuotationRequest request) async {
    final deliveryController = TextEditingController(text: '0');
    final discountController = TextEditingController(text: '0');
    final noteController = TextEditingController();
    Uint8List? attachmentBytes;
    String? attachmentName;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(
            text('Generate Quotation', 'ކޯޓޭޝަން ހަދާ'),
            style: style(fontWeight: FontWeight.w900),
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${widget.business.businessName}\n${text('Requested total', 'ރިކުއެސްޓް ޖުމްލަ')}: ${request.requestedTotalText}',
                    style: style(fontWeight: FontWeight.bold, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: deliveryController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: text('Delivery fee (MVR)', 'ޑެލިވަރީ އަގު (MVR)'),
                      prefixIcon: const Icon(Icons.delivery_dining_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: discountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: text('Discount (MVR)', 'ޑިސްކައުންޓް (MVR)'),
                      prefixIcon: const Icon(Icons.discount_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: text('Seller note', 'ސެލަރ ނޯޓް'),
                      hintText: text(
                        'Example: Quotation valid for 7 days.',
                        'މިސާލު: މި ކޯޓޭޝަން 7 ދުވަހަށް ވެލިޑް.',
                      ),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final cropped = await pickImageCropAndSet(
                        context: context,
                        picker: _picker,
                        isDhivehi: widget.isDhivehi,
                        title: text('Crop Quotation Image', 'ކޯޓޭޝަން ފޮޓޯ ކްރޮޕް ކުރޭ'),
                        initialMode: ImageCropMode.original,
                        imageQuality: 88,
                        maxWidth: 1800,
                      );
                      if (cropped == null) return;
                      setDialogState(() {
                        attachmentBytes = cropped.bytes;
                        attachmentName = cropped.fileName;
                      });
                    },
                    icon: const Icon(Icons.upload_file_rounded),
                    label: Text(
                      attachmentName == null
                          ? text('Upload quotation image', 'ކޯޓޭޝަން ފޮޓޯ އަޕްލޯޑް')
                          : attachmentName!,
                      style: style(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(text('Cancel', 'ކެންސަލް'), style: style()),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.send_rounded),
              label: Text(text('Send Quotation', 'ކޯޓޭޝަން ފޮނުވާ'), style: style()),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) {
      deliveryController.dispose();
      discountController.dispose();
      noteController.dispose();
      return;
    }

    final deliveryFee = double.tryParse(deliveryController.text.trim()) ?? -1;
    final discount = double.tryParse(discountController.text.trim()) ?? -1;
    final note = noteController.text;
    deliveryController.dispose();
    discountController.dispose();
    noteController.dispose();

    setState(() => _workingRequestId = request.id);
    try {
      await MarketplaceService.instance.generateQuotation(
        business: widget.business,
        request: request,
        deliveryFeeMvr: deliveryFee,
        discountMvr: discount,
        sellerNote: note,
        attachmentBytes: attachmentBytes,
        attachmentFileName: attachmentName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            text(
              'Quotation sent to the client.',
              'ކޯޓޭޝަން ކްލައިންޓަށް ފޮނުވިއްޖެ.',
            ),
            style: style(color: Colors.white),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    } finally {
      if (mounted) setState(() => _workingRequestId = null);
    }
  }

  Future<void> _rejectQuotation(QuotationRequest request) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          text('Reject Quotation Request', 'ކޯޓޭޝަން ރިކުއެސްޓް ރިޖެކްޓް'),
          style: style(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: text('Reason', 'ސަބަބު'),
            alignLabelWithHint: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(text('Cancel', 'ކެންސަލް'), style: style()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(text('Reject', 'ރިޖެކްޓް'), style: style()),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || reason.isEmpty) return;

    setState(() => _workingRequestId = request.id);
    try {
      await MarketplaceService.instance.rejectQuotationRequest(
        business: widget.business,
        request: request,
        reason: reason,
      );
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    } finally {
      if (mounted) setState(() => _workingRequestId = null);
    }
  }

  Future<void> _viewAttachment(QuotationRequest request) async {
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

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 7),
        content: Text(
          error.toString().replaceFirst('Bad state: ', ''),
          style: style(color: Colors.white),
        ),
      ),
    );
  }
}
