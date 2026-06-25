import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/advertisement_service.dart';

class AdvertisementRequestPage extends StatefulWidget {
  const AdvertisementRequestPage({
    super.key,
    required this.user,
    required this.isDhivehi,
  });

  final AppUser user;
  final bool isDhivehi;

  @override
  State<AdvertisementRequestPage> createState() =>
      _AdvertisementRequestPageState();
}

class _AdvertisementRequestPageState
    extends State<AdvertisementRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _titleController = TextEditingController();
  final _contactController = TextEditingController(text: '+960');
  final _detailsController = TextEditingController();

  String _duration = '7 Days';
  bool _isLoading = false;

  String text(String english, String dhivehi) {
    return widget.isDhivehi ? dhivehi : english;
  }

  TextStyle style({FontWeight? fontWeight, Color? color}) {
    return TextStyle(
      fontFamily: widget.isDhivehi ? 'Faruma' : null,
      fontWeight: fontWeight,
      color: color,
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _titleController.dispose();
    _contactController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await AdvertisementService.instance.submit(
        owner: widget.user,
        businessName: _businessNameController.text,
        title: _titleController.text,
        contactNumber: _contactController.text,
        duration: _duration,
        details: _detailsController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            text(
              'Advertisement request submitted for approval.',
              'އިޢުލާނުގެ ރިކުއެސްޓް ހުއްދައަށް ހުށަހެޅިއްޖެ.',
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
          content: Text('$error', style: style(color: Colors.white)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            text(
              'Request Advertisement',
              'އިޢުލާނެއް ރިކުއެސްޓް ކުރޭ',
            ),
            style: style(fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _businessNameController,
                      decoration: InputDecoration(
                        labelText: text(
                          'Business Name',
                          'ވިޔަފާރީގެ ނަން',
                        ),
                        prefixIcon:
                            const Icon(Icons.storefront_rounded),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? text(
                                  'Please enter the business name.',
                                  'ވިޔަފާރީގެ ނަން ލިޔުއްވާ.',
                                )
                              : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: text(
                          'Advertisement Title',
                          'އިޢުލާނުގެ ސުރުޚީ',
                        ),
                        prefixIcon: const Icon(Icons.title_rounded),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? text(
                                  'Please enter an advertisement title.',
                                  'އިޢުލާނުގެ ސުރުޚީ ލިޔުއްވާ.',
                                )
                              : null,
                    ),
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      initialValue: _duration,
                      decoration: InputDecoration(
                        labelText: text(
                          'Advertisement Duration',
                          'އިޢުލާނުގެ މުއްދަތު',
                        ),
                        prefixIcon: const Icon(Icons.schedule_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: '7 Days',
                          child: Text('7 Days'),
                        ),
                        DropdownMenuItem(
                          value: '14 Days',
                          child: Text('14 Days'),
                        ),
                        DropdownMenuItem(
                          value: '30 Days',
                          child: Text('30 Days'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _duration = value);
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _contactController,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        labelText: text(
                          'Contact Number',
                          'ގުޅޭނެ ނަންބަރު',
                        ),
                        prefixIcon: const Icon(Icons.phone_rounded),
                      ),
                      validator: (value) {
                        if (!RegExp(r'^\+960\d{7}$')
                            .hasMatch(value?.trim() ?? '')) {
                          return text(
                            'Use this format: +9607936300',
                            'މި ފޯމެޓް ބޭނުންކުރޭ: +9607936300',
                          );
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _detailsController,
                      minLines: 4,
                      maxLines: 7,
                      decoration: InputDecoration(
                        labelText: text(
                          'Advertisement Details',
                          'އިޢުލާނުގެ ތަފްޞީލު',
                        ),
                        alignLabelWithHint: true,
                        prefixIcon: const Icon(Icons.description_rounded),
                      ),
                      validator: (value) =>
                          value == null || value.trim().length < 10
                              ? text(
                                  'Please enter at least 10 characters.',
                                  'މަދުވެގެން 10 އަކުރު ލިޔުއްވާ.',
                                )
                              : null,
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 53,
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : _submit,
                        icon: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.campaign_rounded),
                        label: Text(
                          text('Send Request', 'ރިކުއެސްޓް ފޮނުވާ'),
                          style: style(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
