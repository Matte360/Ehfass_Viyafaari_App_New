import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../data/maldives_islands.dart';
import '../models/app_user.dart';
import '../services/business_service.dart';
import '../utils/image_crop_helper.dart';
import '../utils/map_coordinate_parser.dart';

class AddBusinessPage extends StatefulWidget {
  const AddBusinessPage({
    super.key,
    required this.user,
    required this.isDhivehi,
  });

  final AppUser user;
  final bool isDhivehi;

  @override
  State<AddBusinessPage> createState() => _AddBusinessPageState();
}

class _AddBusinessPageState extends State<AddBusinessPage> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _contactController = TextEditingController(text: '+960');
  final _emailController = TextEditingController();
  final _deliveryDetailsController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _mapLinkController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  String _category = 'Shop';
  String _selectedIsland = '';
  bool _deliveryAvailable = false;
  bool _isSubmitting = false;
  bool _isFindingLocation = false;
  Uint8List? _logoBytes;
  String? _logoFileName;
  double? _latitude;
  double? _longitude;
  String _mapUrl = '';

  static const categories = <String>[
    'Shop',
    'Supermarket',
    'Restaurant',
    'Café',
    'Electronics',
    'Fashion',
    'Pharmacy',
    'Hotel or Guesthouse',
    'Transport',
    'Professional Service',
    'Online Business',
    'Other',
  ];

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
  void dispose() {
    _businessNameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _deliveryDetailsController.dispose();
    _descriptionController.dispose();
    _mapLinkController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final cropped = await pickImageCropAndSet(
      context: context,
      picker: _imagePicker,
      isDhivehi: widget.isDhivehi,
      title: text('Crop Business Image', 'ވިޔަފާރީގެ ފޮޓޯ ކްރޮޕް ކުރޭ'),
      initialMode: ImageCropMode.square,
      imageQuality: 82,
      maxWidth: 1600,
    );

    if (cropped == null || !mounted) return;
    setState(() {
      _logoBytes = cropped.bytes;
      _logoFileName = cropped.fileName;
    });
  }

  void _setLocationFromMapLink() {
    final input = _mapLinkController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            text(
              'Paste a Google Maps link or type coordinates first.',
              'ފުރަތަމަ Google Maps link ނުވަތަ ކޯޑިނޭޓްސް ލިޔޭ.',
            ),
            style: style(color: Colors.white),
          ),
        ),
      );
      return;
    }

    final parsed = _parseCoordinates(input);
    setState(() {
      _mapUrl = input.startsWith('http') ? input : _mapUrl;
      if (parsed != null) {
        _latitude = parsed.$1;
        _longitude = parsed.$2;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: parsed == null ? Colors.orange : null,
        content: Text(
          parsed == null
              ? text(
                  'Map link saved. It will open for clients, but nearby distance needs coordinates or current GPS.',
                  'މެޕް ލިންކް ސޭވްވެއްޖެ. ކްލައިއެންޓުން ހުޅުވޭނެ، ދުރުމިނަށް GPS ނުވަތަ ކޯޑިނޭޓްސް ބޭނުން.',
                )
              : text('Map location added.', 'މެޕް ލޮކޭޝަން އިތުރުވެއްޖެ.'),
          style: style(color: parsed == null ? Colors.white : null),
        ),
      ),
    );
  }

  (double, double)? _parseCoordinates(String value) {
    return parseMapCoordinates(value);
  }

  Future<void> _captureLocation() async {
    setState(() => _isFindingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw StateError(
          text(
            'Please turn on location services.',
            'ލޮކޭޝަން ސާވިސް އޮން ކުރައްވާ.',
          ),
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError(
          text(
            'Location permission was not granted.',
            'ލޮކޭޝަން ހުއްދަ ނުދެވުނު.',
          ),
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            text(
              'Business GPS location added.',
              'ވިޔަފާރީގެ GPS ލޮކޭޝަން އިތުރުކުރެވިއްޖެ.',
            ),
            style: style(),
          ),
        ),
      );
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
      if (mounted) setState(() => _isFindingLocation = false);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await BusinessService.instance.submitBusiness(
        owner: widget.user,
        businessName: _businessNameController.text,
        category: _category,
        contactNumber: _contactController.text,
        email: _emailController.text,
        island: _selectedIsland,
        deliveryAvailable: _deliveryAvailable,
        deliveryDetails: _deliveryDetailsController.text,
        description: _descriptionController.text,
        logoBytes: _logoBytes,
        logoFileName: _logoFileName,
        latitude: _latitude,
        longitude: _longitude,
        mapUrl: _mapUrl,
      );

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            icon: const Icon(
              Icons.hourglass_top_rounded,
              color: Colors.orange,
              size: 48,
            ),
            title: Text(
              text('Submitted for Approval', 'ހުއްދައަށް ހުށަހެޅިއްޖެ'),
              style: style(fontWeight: FontWeight.bold),
            ),
            content: Text(
              text(
                'Your business is pending. It will appear in the app after an administrator approves it.',
                'ތިޔަ ވިޔަފާރި ޕެންޑިންގައި ވެއެވެ. އެޑްމިން ހުއްދަދިނުމުން އެޕްގައި ފެންނާނެއެވެ.',
              ),
              style: style(),
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

      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            '${text('Submission failed', 'ހުށަހެޅުން ނުކުރެވުނު')}: $error',
            style: style(color: Colors.white),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
            text('Add Your Business', 'ތިޔަ ވިޔަފާރި އިތުރުކުރޭ'),
            style: style(fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 650),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GestureDetector(
                        onTap: _pickLogo,
                        child: Container(
                          height: 190,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            borderRadius: BorderRadius.circular(24),
                            image: _logoBytes == null
                                ? null
                                : DecorationImage(
                                    image: MemoryImage(_logoBytes!),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          child: _logoBytes == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.add_photo_alternate_rounded,
                                      size: 55,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      text(
                                        'Upload Business Logo or Image',
                                        'ވިޔަފާރީގެ ލޯގޯ ނުވަތަ ފޮޓޯ އަޕްލޯޑް ކުރޭ',
                                      ),
                                      textAlign: TextAlign.center,
                                      style: style(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              : Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: IconButton.filledTonal(
                                      onPressed: _pickLogo,
                                      icon: const Icon(Icons.edit_rounded),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
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
                        validator: (value) {
                          if (value == null || value.trim().length < 2) {
                            return text(
                              'Please enter the business name.',
                              'ވިޔަފާރީގެ ނަން ލިޔުއްވާ.',
                            );
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        decoration: InputDecoration(
                          labelText: text(
                            'Business Category',
                            'ވިޔަފާރީގެ ބާވަތް',
                          ),
                          prefixIcon: const Icon(Icons.category_rounded),
                        ),
                        items: categories
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _category = value);
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
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: text(
                            'Email or Gmail',
                            'އީމެއިލް ނުވަތަ ޖީމެއިލް',
                          ),
                          prefixIcon: const Icon(Icons.email_rounded),
                        ),
                        validator: (value) {
                          final pattern = RegExp(
                            r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
                          );
                          if (!pattern.hasMatch(value?.trim() ?? '')) {
                            return text(
                              'Please enter a valid email.',
                              'ރަނގަޅު އީމެއިލެއް ލިޔުއްވާ.',
                            );
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      Autocomplete<String>(
                        optionsBuilder: (value) {
                          final query = value.text.trim().toLowerCase();
                          if (query.isEmpty) {
                            return maldivesInhabitedIslands.take(12);
                          }
                          return maldivesInhabitedIslands
                              .where(
                                (island) =>
                                    island.toLowerCase().contains(query),
                              )
                              .take(15);
                        },
                        onSelected: (value) {
                          _selectedIsland = value;
                        },
                        fieldViewBuilder: (
                          context,
                          controller,
                          focusNode,
                          onFieldSubmitted,
                        ) {
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: text(
                                'Island or Location',
                                'ރަށް ނުވަތަ ތަން',
                              ),
                              prefixIcon:
                                  const Icon(Icons.location_on_rounded),
                              hintText: text(
                                'Start typing an island name',
                                'ރަށެއްގެ ނަން ލިޔަން ފަށާ',
                              ),
                            ),
                            onChanged: (value) => _selectedIsland = value,
                            onFieldSubmitted: (_) => onFieldSubmitted(),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return text(
                                  'Please select an island or location.',
                                  'ރަށެއް ނުވަތަ ތަނެއް ހޮވާ.',
                                );
                              }
                              if (!maldivesInhabitedIslands.contains(
                                value.trim(),
                              )) {
                                return text(
                                  'Please select an island from the suggestions.',
                                  'ސަޖެސްޓް ކުރާ ލިސްޓުން ރަށެއް ހޮވާ.',
                                );
                              }
                              return null;
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _mapLinkController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: text(
                            'Google Maps link or coordinates',
                            'Google Maps link ނުވަތަ ކޯޑިނޭޓްސް',
                          ),
                          hintText: 'https://maps.google.com/... or 4.1755, 73.5093',
                          prefixIcon: const Icon(Icons.map_rounded),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _setLocationFromMapLink,
                            icon: const Icon(Icons.add_location_alt_rounded),
                            label: Text(
                              text('Set From Map Link', 'މެޕް ލިންކުން ސެޓް ކުރޭ'),
                              style: style(fontWeight: FontWeight.bold),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _isFindingLocation ? null : _captureLocation,
                            icon: _isFindingLocation
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Icon(
                                    _latitude == null
                                        ? Icons.my_location_rounded
                                        : Icons.check_circle_rounded,
                                  ),
                            label: Text(
                              _latitude == null
                                  ? text('Use Current GPS', 'މިހާރުގެ GPS ބޭނުންކުރޭ')
                                  : text('Location Added', 'ލޮކޭޝަން އިތުރުވެއްޖެ'),
                              style: style(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      if (_mapUrl.isNotEmpty && (_latitude == null || _longitude == null)) ...[
                        const SizedBox(height: 8),
                        Text(
                          text('Map link saved. Nearby distance will show after GPS/coordinates are added.', 'މެޕް ލިންކް ސޭވް. ދުރުމިން ދައްކާނީ GPS/ކޯޑިނޭޓްސް އިތުރުކުރުމުން.'),
                          style: style(fontWeight: FontWeight.bold, color: Colors.orange),
                        ),
                      ],
                      if (_latitude != null && _longitude != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                          style: style(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 15),
                      Card(
                        child: Column(
                          children: [
                            SwitchListTile(
                              value: _deliveryAvailable,
                              secondary:
                                  const Icon(Icons.delivery_dining_rounded),
                              title: Text(
                                text(
                                  'Delivery Available',
                                  'ޑެލިވަރީ ލިބެން ހުރޭ',
                                ),
                                style: style(fontWeight: FontWeight.bold),
                              ),
                              onChanged: (value) {
                                setState(() => _deliveryAvailable = value);
                              },
                            ),
                            if (_deliveryAvailable)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: TextFormField(
                                  controller: _deliveryDetailsController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    labelText: text(
                                      'Delivery Details',
                                      'ޑެލިވަރީގެ ތަފްޞީލު',
                                    ),
                                    alignLabelWithHint: true,
                                  ),
                                  validator: (value) {
                                    if (_deliveryAvailable &&
                                        (value == null ||
                                            value.trim().isEmpty)) {
                                      return text(
                                        'Please enter delivery details.',
                                        'ޑެލިވަރީގެ ތަފްޞީލު ލިޔުއްވާ.',
                                      );
                                    }
                                    return null;
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _descriptionController,
                        minLines: 4,
                        maxLines: 7,
                        decoration: InputDecoration(
                          labelText: text(
                            'Business Description',
                            'ވިޔަފާރީގެ ތަފްޞީލު',
                          ),
                          alignLabelWithHint: true,
                          prefixIcon: const Icon(Icons.description_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 10) {
                            return text(
                              'Please write at least 10 characters.',
                              'މަދުވެގެން 10 އަކުރު ލިޔުއްވާ.',
                            );
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: _isSubmitting ? null : _submit,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  height: 21,
                                  width: 21,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                          label: Text(
                            text(
                              'Submit for Admin Approval',
                              'އެޑްމިން ހުއްދައަށް ހުށަހަޅާ',
                            ),
                            style: style(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
      ),
    );
  }
}
