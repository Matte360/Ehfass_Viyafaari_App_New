import 'package:flutter/material.dart';

import '../models/business.dart';
import '../services/marketplace_service.dart';

class BusinessPaymentSettingsPage extends StatefulWidget {
  const BusinessPaymentSettingsPage({
    super.key,
    required this.business,
    required this.isDhivehi,
  });

  final Business business;
  final bool isDhivehi;

  @override
  State<BusinessPaymentSettingsPage> createState() =>
      _BusinessPaymentSettingsPageState();
}

class _BusinessPaymentSettingsPageState
    extends State<BusinessPaymentSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bankController;
  late final TextEditingController _accountNameController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _instructionsController;
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
    _bankController = TextEditingController(text: widget.business.bankName);
    _accountNameController =
        TextEditingController(text: widget.business.accountName);
    _accountNumberController =
        TextEditingController(text: widget.business.accountNumber);
    _instructionsController =
        TextEditingController(text: widget.business.paymentInstructions);
  }

  @override
  void dispose() {
    _bankController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return text('This field is required.', 'މި ފީލްޑް ފުރާ.');
    }
    return null;
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await MarketplaceService.instance.updatePaymentAccount(
        business: widget.business,
        bankName: _bankController.text,
        accountName: _accountNameController.text,
        accountNumber: _accountNumberController.text,
        paymentInstructions: _instructionsController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            text(
              'Money transfer account saved.',
              'ފައިސާ ޓްރާންސްފަރ އެކައުންޓް ސޭވްކުރެވިއްޖެ.',
            ),
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
      textDirection:
          widget.isDhivehi ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            text('Money Transfer Account', 'ފައިސާ ޓްރާންސްފަރ އެކައުންޓް'),
            style: style(fontWeight: FontWeight.bold),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.account_balance_rounded, size: 34),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Text(
                          text(
                            'Clients will see these details before uploading their transfer receipt.',
                            'ކްލައިންޓުން ޓްރާންސްފަރ ރަސީދު އަޕްލޯޑްކުރުމުގެ ކުރިން މި މަޢުލޫމާތު ފެންނާނެ.',
                          ),
                          style: style(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bankController,
                validator: _required,
                decoration: InputDecoration(
                  labelText: text('Bank name', 'ބޭންކްގެ ނަން'),
                  prefixIcon: const Icon(Icons.account_balance_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _accountNameController,
                validator: _required,
                decoration: InputDecoration(
                  labelText: text('Account name', 'އެކައުންޓްގެ ނަން'),
                  prefixIcon: const Icon(Icons.person_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _accountNumberController,
                validator: _required,
                decoration: InputDecoration(
                  labelText: text('Account number', 'އެކައުންޓް ނަންބަރު'),
                  prefixIcon: const Icon(Icons.numbers_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _instructionsController,
                minLines: 4,
                maxLines: 7,
                decoration: InputDecoration(
                  labelText: text(
                    'Transfer instructions (optional)',
                    'ޓްރާންސްފަރ އިންސްޓްރަކްޝަން (އިޚްތިޔާރީ)',
                  ),
                  alignLabelWithHint: true,
                  prefixIcon: const Icon(Icons.info_outline_rounded),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    text('Save Account Details', 'އެކައުންޓް މަޢުލޫމާތު ސޭވްކުރޭ'),
                    style: style(fontWeight: FontWeight.bold),
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
