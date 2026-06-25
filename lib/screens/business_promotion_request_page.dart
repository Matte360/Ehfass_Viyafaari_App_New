import 'package:flutter/material.dart';

import '../models/business.dart';
import '../models/promotion_request.dart';
import '../services/promotion_service.dart';

class BusinessPromotionRequestPage extends StatefulWidget {
  const BusinessPromotionRequestPage({
    super.key,
    required this.business,
    required this.isDhivehi,
  });

  final Business business;
  final bool isDhivehi;

  @override
  State<BusinessPromotionRequestPage> createState() =>
      _BusinessPromotionRequestPageState();
}

class _BusinessPromotionRequestPageState
    extends State<BusinessPromotionRequestPage> {
  final _noteController = TextEditingController();
  String _plan = 'featured_shop';
  bool _submitting = false;

  String text(String english, String dhivehi) =>
      widget.isDhivehi ? dhivehi : english;

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
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await PromotionService.instance.requestPromotion(
        business: widget.business,
        plan: _plan,
        note: _noteController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            text('Promotion request sent to admin.', 'ޕްރޮމޯޝަން ރިކުއެސްޓް އެޑްމިނަށް ފޮނުވިއްޖެ.'),
            style: style(color: Colors.white),
          ),
        ),
      );
      _noteController.clear();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            error.toString().replaceFirst('Bad state: ', ''),
            style: style(color: Colors.white),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.isDhivehi ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            text('Promotion Request', 'ޕްރޮމޯޝަން ރިކުއެސްޓް'),
            style: style(fontWeight: FontWeight.w900),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text('Grow your visibility', 'ތިޔަ ވިޔަފާރި އިތުރަށް ފެންނަން ހަދާ'),
                      style: style(fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      text(
                        'Request Featured, Sponsored, or Verified badge. Admin will approve before it appears to clients.',
                        'Featured، Sponsored، ނުވަތަ Verified badge ރިކުއެސްޓްކުރޭ. ކްލައިންޓަށް ފެންނާނީ އެޑްމިން ހުއްދަދިނުމަށް ފަހު.',
                      ),
                      style: style(height: 1.45),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'featured_shop',
                  icon: const Icon(Icons.star_rounded),
                  label: Text(text('Featured', 'ފީޗަރޑް'), style: style()),
                ),
                ButtonSegment(
                  value: 'sponsored_shop',
                  icon: const Icon(Icons.campaign_rounded),
                  label: Text(text('Sponsored', 'ސްޕޮންސަރ'), style: style()),
                ),
                ButtonSegment(
                  value: 'verified_badge',
                  icon: const Icon(Icons.verified_rounded),
                  label: Text(text('Verified', 'ވެރިފައިޑް'), style: style()),
                ),
              ],
              selected: {_plan},
              onSelectionChanged: (value) => setState(() => _plan = value.first),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _noteController,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: text('Message to admin', 'އެޑްމިނަށް މެސެޖް'),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send_rounded),
              label: Text(
                text('Send Request', 'ރިކުއެސްޓް ފޮނުވާ'),
                style: style(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              text('Your promotion requests', 'ތިޔަ ޕްރޮމޯޝަން ރިކުއެސްޓްތައް'),
              style: style(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<PromotionRequestModel>>(
              stream: PromotionService.instance.watchForBusiness(widget.business.id),
              builder: (context, snapshot) {
                final requests = snapshot.data ?? const <PromotionRequestModel>[];
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (requests.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(text('No requests yet.', 'އަދި ރިކުއެސްޓެއް ނެތް.'), style: style()),
                    ),
                  );
                }
                return Column(
                  children: requests.map((request) {
                    final color = request.isApproved
                        ? Colors.green
                        : request.isRejected
                            ? Colors.red
                            : Colors.orange;
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.campaign_rounded, color: color),
                        title: Text(request.planLabel, style: style(fontWeight: FontWeight.w900)),
                        subtitle: Text(
                          '${request.status}${request.rejectionReason.isEmpty ? '' : ' • ${request.rejectionReason}'}',
                          style: style(color: color),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
