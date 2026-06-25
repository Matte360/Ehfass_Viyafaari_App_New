import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_user.dart';
import '../models/business.dart';
import '../models/catalog_item.dart';
import '../services/marketplace_service.dart';
import '../utils/image_crop_helper.dart';

class PaymentSubmissionPage extends StatefulWidget {
  const PaymentSubmissionPage({
    super.key,
    required this.client,
    required this.business,
    required this.item,
    required this.quantity,
    required this.isDhivehi,
  });

  final AppUser client;
  final Business business;
  final CatalogItem item;
  final int quantity;
  final bool isDhivehi;

  @override
  State<PaymentSubmissionPage> createState() =>
      _PaymentSubmissionPageState();
}

class _PaymentSubmissionPageState extends State<PaymentSubmissionPage> {
  final _picker = ImagePicker();
  final _referenceController = TextEditingController();
  Uint8List? _receiptBytes;
  String? _receiptName;
  bool _submitting = false;

  double get total => widget.item.lineTotalForQuantity(widget.quantity);

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
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final cropped = await pickImageCropAndSet(
      context: context,
      picker: _picker,
      isDhivehi: widget.isDhivehi,
      title: text('Crop Receipt Image', 'ރަސީދު ފޮޓޯ ކްރޮޕް ކުރޭ'),
      initialMode: ImageCropMode.original,
      imageQuality: 90,
      maxWidth: 2000,
    );
    if (cropped == null || !mounted) return;

    setState(() {
      _receiptBytes = cropped.bytes;
      _receiptName = cropped.fileName;
    });
  }

  Future<void> _submit() async {
    if (_receiptBytes == null || _receiptName == null) {
      _showError(text(
        'Upload the bank transfer receipt first.',
        'ބޭންކް ޓްރާންސްފަރ ރަސީދު އަޕްލޯޑްކުރޭ.',
      ));
      return;
    }

    setState(() => _submitting = true);
    try {
      await MarketplaceService.instance.submitBankTransferOrder(
        client: widget.client,
        business: widget.business,
        item: widget.item,
        quantity: widget.quantity,
        receiptBytes: _receiptBytes!,
        receiptFileName: _receiptName!,
        transferReference: _referenceController.text,
      );

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            icon: const Icon(
              Icons.hourglass_top_rounded,
              size: 50,
              color: Colors.orange,
            ),
            title: Text(
              text('Sent for Verification', 'ވެރިފައިކުރުމަށް ފޮނުވިއްޖެ'),
              style: style(fontWeight: FontWeight.bold),
            ),
            content: Text(
              text(
                'The business owner will check your transfer receipt. Quantity will reduce only after the payment is verified.',
                'ވިޔަފާރީގެ ވެރިޔާ ތިޔަ ޓްރާންސްފަރ ރަސީދު ޗެކްކުރާނެ. ފައިސާ ވެރިފައިކުރުމުން މުދަލުގެ ޢަދަދު ކުޑަވާނެ.',
              ),
              style: style(height: 1.5),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(text('OK', 'އޯކޭ'), style: style()),
              ),
            ],
          );
        },
      );

      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      _showError(error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 7),
        content: Text(message, style: style(color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          widget.isDhivehi ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            text('Bank Transfer Payment', 'ބޭންކް ޓްރާންސްފަރ ފައިސާ'),
            style: style(fontWeight: FontWeight.bold),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.item.name,
                      style: style(fontSize: 21, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    _row(text('Unit price', 'އެކަކުގެ އަގު'), widget.item.priceText),
                    _row(text('Quantity', 'ޢަދަދު'), widget.quantity.toString()),
                    if (widget.item.discountForQuantity(widget.quantity) > 0)
                      _row(
                        text('Discount', 'ޑިސްކައުންޓް'),
                        '- MVR ${widget.item.discountForQuantity(widget.quantity).toStringAsFixed(2)}',
                      ),
                    const Divider(height: 26),
                    _row(
                      text('Total to transfer', 'ޓްރާންސްފަރކުރަންވީ ޖުމްލަ'),
                      'MVR ${total.toStringAsFixed(2)}',
                      strong: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_rounded),
                        const SizedBox(width: 9),
                        Text(
                          text('Transfer Account', 'ޓްރާންސްފަރ އެކައުންޓް'),
                          style: style(fontSize: 19, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    _row(text('Bank', 'ބޭންކް'), widget.business.bankName),
                    _row(
                      text('Account name', 'އެކައުންޓްގެ ނަން'),
                      widget.business.accountName,
                    ),
                    _row(
                      text('Account number', 'އެކައުންޓް ނަންބަރު'),
                      widget.business.accountNumber,
                      strong: true,
                    ),
                    if (widget.business.paymentInstructions.isNotEmpty) ...[
                      const Divider(height: 24),
                      Text(
                        widget.business.paymentInstructions,
                        style: style(height: 1.5),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 17),
            TextField(
              controller: _referenceController,
              decoration: InputDecoration(
                labelText: text(
                  'Transfer reference (optional)',
                  'ޓްރާންސްފަރ ރެފަރެންސް (އިޚްތިޔާރީ)',
                ),
                prefixIcon: const Icon(Icons.tag_rounded),
              ),
            ),
            const SizedBox(height: 17),
            InkWell(
              onTap: _submitting ? null : _pickReceipt,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 230,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _receiptBytes == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long_rounded, size: 56),
                          const SizedBox(height: 10),
                          Text(
                            text(
                              'Upload transfer receipt',
                              'ޓްރާންސްފަރ ރަސީދު އަޕްލޯޑްކުރޭ',
                            ),
                            style: style(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            text('JPG, PNG or WEBP', 'JPG، PNG ނުވަތަ WEBP'),
                            style: style(fontSize: 12),
                          ),
                        ],
                      )
                    : Image.memory(_receiptBytes!, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 55,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  text(
                    'Send Receipt for Verification',
                    'ވެރިފައިކުރުމަށް ރަސީދު ފޮނުވާ',
                  ),
                  style: style(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: style())),
          const SizedBox(width: 12),
          Flexible(
            child: SelectableText(
              value,
              textAlign: TextAlign.end,
              style: style(
                fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
