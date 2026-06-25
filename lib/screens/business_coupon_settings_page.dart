import 'package:flutter/material.dart';

import '../models/business.dart';
import '../services/business_service.dart';

class BusinessCouponSettingsPage extends StatefulWidget {
  const BusinessCouponSettingsPage({
    super.key,
    required this.business,
    required this.isDhivehi,
  });

  final Business business;
  final bool isDhivehi;

  @override
  State<BusinessCouponSettingsPage> createState() =>
      _BusinessCouponSettingsPageState();
}

class _BusinessCouponSettingsPageState
    extends State<BusinessCouponSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late bool _couponEnabled;
  late final TextEditingController _minimumController;
  late final TextEditingController _rewardController;
  late final TextEditingController _titleController;
  late final TextEditingController _termsController;
  bool _saving = false;

  String text(String english, String dhivehi) {
    return widget.isDhivehi ? dhivehi : english;
  }

  TextStyle style({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: widget.isDhivehi ? 'Faruma' : null,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  @override
  void initState() {
    super.initState();
    _couponEnabled = widget.business.couponEnabled;
    _minimumController = TextEditingController(
      text: widget.business.couponMinimumSpendMvr.toStringAsFixed(2),
    );
    _rewardController = TextEditingController(
      text: widget.business.couponRewardMvr.toStringAsFixed(2),
    );
    _titleController = TextEditingController(
      text: widget.business.couponTitle,
    );
    _termsController = TextEditingController(
      text: widget.business.couponTerms,
    );
  }

  @override
  void dispose() {
    _minimumController.dispose();
    _rewardController.dispose();
    _titleController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await BusinessService.instance.updateBusinessCouponOffer(
        business: widget.business,
        couponEnabled: _couponEnabled,
        couponMinimumSpendMvr:
            double.tryParse(_minimumController.text.trim()) ?? 0,
        couponRewardMvr: double.tryParse(_rewardController.text.trim()) ?? 0,
        couponTitle: _titleController.text,
        couponTerms: _termsController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            text('Coupon settings saved.', 'ކޫޕަން ސެޓިންގްސް ސޭވްކުރެވިއްޖެ.'),
            style: style(color: Colors.white),
          ),
        ),
      );
      Navigator.pop(context);
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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.isDhivehi ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            text('Coupon Settings', 'ކޫޕަން ސެޓިންގްސް'),
            style: style(fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SwitchListTile(
                          value: _couponEnabled,
                          onChanged: (value) =>
                              setState(() => _couponEnabled = value),
                          title: Text(
                            text('Enable coupon offer', 'ކޫޕަން އޮފަރ އެނޭބަލް'),
                            style: style(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text(
                            text(
                              'Client can generate one coupon after seller verifies an eligible order.',
                              'އެލިޖިބަލް އޯޑަރެއް ވެރިފައިކުރުމުން ކްލައިންޓަށް އެއް ކޫޕަން ޖެނެރޭޓްކުރެވޭނެ.',
                            ),
                            style: style(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _minimumController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: text(
                              'Minimum purchase amount (MVR)',
                              'މިނިމަމް ހޯދާ އަގު (MVR)',
                            ),
                            helperText: text(
                              'Example: 500 means coupon appears after order is MVR 500 or more.',
                              'މިސާލު: 500 ޖެހިފައި ވާނަމަ، MVR 500 ނުވަތަ އެއަށް މަތީ އޯޑަރަށް ކޫޕަން ފެންނާނެ.',
                            ),
                          ),
                          validator: (value) {
                            final amount = double.tryParse(value ?? '');
                            if (_couponEnabled && (amount == null || amount <= 0)) {
                              return text('Enter a valid amount.', 'ރަނގަޅު އަގެއް ލިޔޭ.');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _rewardController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: text(
                              'Coupon reward amount (optional)',
                              'ކޫޕަން ރިވޯޑް އަގު (އިޚްތިޔާރީ)',
                            ),
                            helperText: text(
                              'Example: MVR 50 off next purchase. Use 0 for custom seller coupon.',
                              'މިސާލު: ދެން ހޯދާއިރު MVR 50 ޑިސްކައުންޓް. ކަސްޓަމް ކޫޕަނަށް 0 ލިޔޭ.',
                            ),
                          ),
                          validator: (value) {
                            final amount = double.tryParse(value ?? '0');
                            if (amount == null || amount < 0) {
                              return text('Enter 0 or more.', '0 ނުވަތަ އެއަށް މަތީ ލިޔޭ.');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: text('Coupon title', 'ކޫޕަން ޓައިޓަލް'),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _termsController,
                          minLines: 3,
                          maxLines: 5,
                          decoration: InputDecoration(
                            labelText: text('Terms / note', 'ޝަރުތު / ނޯޓް'),
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save_rounded),
                          label: Text(
                            text('Save Coupon Settings', 'ކޫޕަން ސޭވްކުރޭ'),
                            style: style(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
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
