import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/maldives_islands.dart';
import '../models/business.dart';
import '../services/business_service.dart';
import '../utils/map_coordinate_parser.dart';

class BusinessLocationSettingsPage extends StatefulWidget {
  const BusinessLocationSettingsPage({
    super.key,
    required this.business,
    required this.isDhivehi,
  });

  final Business business;
  final bool isDhivehi;

  @override
  State<BusinessLocationSettingsPage> createState() => _BusinessLocationSettingsPageState();
}

class _BusinessLocationSettingsPageState extends State<BusinessLocationSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _islandController;
  late final TextEditingController _mapLinkController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  bool _saving = false;
  bool _locating = false;

  String text(String english, String dhivehi) => widget.isDhivehi ? dhivehi : english;

  TextStyle style({double? fontSize, FontWeight? fontWeight, Color? color}) {
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
    _islandController = TextEditingController(text: widget.business.island);
    _mapLinkController = TextEditingController(text: widget.business.mapUrl);
    _latitudeController = TextEditingController(
      text: widget.business.latitude == null ? '' : widget.business.latitude!.toStringAsFixed(7),
    );
    _longitudeController = TextEditingController(
      text: widget.business.longitude == null ? '' : widget.business.longitude!.toStringAsFixed(7),
    );
  }

  @override
  void dispose() {
    _islandController.dispose();
    _mapLinkController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw StateError(text('Please turn on location services.', 'ލޮކޭޝަން ސާވިސް އޮން ކުރައްވާ.'));
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw StateError(text('Location permission was not granted.', 'ލޮކޭޝަން ހުއްދަ ނުދެވުނު.'));
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      setState(() {
        _latitudeController.text = position.latitude.toStringAsFixed(7);
        _longitudeController.text = position.longitude.toStringAsFixed(7);
      });
    } catch (error) {
      if (!mounted) return;
      _showError(error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _setFromMapLink() {
    final input = _mapLinkController.text.trim();
    if (input.isEmpty) {
      _showError(text(
        'Paste a Google Maps link or type coordinates first.',
        'ފުރަތަމަ Google Maps link ނުވަތަ ކޯޑިނޭޓްސް ލިޔޭ.',
      ));
      return;
    }

    final parsed = _parseCoordinates(input);
    if (parsed != null) {
      setState(() {
        _latitudeController.text = parsed.$1.toStringAsFixed(7);
        _longitudeController.text = parsed.$2.toStringAsFixed(7);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text('Map coordinates added.', 'މެޕް ކޯޑިނޭޓްސް އިތުރުވެއްޖެ.'), style: style())),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.orange,
        content: Text(
          text(
            'Map link saved. It will open for clients, but nearby distance needs coordinates or current GPS.',
            'މެޕް ލިންކް ސޭވްވެއްޖެ. ކްލައިއެންޓުން ހުޅުވޭނެ، ދުރުމިނަށް GPS ނުވަތަ ކޯޑިނޭޓްސް ބޭނުން.',
          ),
          style: style(color: Colors.white),
        ),
      ),
    );
  }

  (double, double)? _parseCoordinates(String value) {
    return parseMapCoordinates(value);
  }

  Future<void> _openGoogleMaps() async {
    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());
    final mapLink = _mapLinkController.text.trim();
    final uri = latitude != null && longitude != null
        ? Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude')
        : mapLink.startsWith('http')
            ? (Uri.tryParse(mapLink) ?? Uri.parse('https://www.google.com/maps'))
            : Uri.parse('https://www.google.com/maps');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;

    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());

    setState(() => _saving = true);
    try {
      await BusinessService.instance.updateBusinessLocation(
        business: widget.business,
        island: _islandController.text,
        latitude: latitude,
        longitude: longitude,
        mapUrl: _mapLinkController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(text('Business location saved.', 'ވިޔަފާރީގެ ލޮކޭޝަން ސޭވްވެއްޖެ.'), style: style(color: Colors.white)),
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      _showError(error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.red, content: Text(message, style: style(color: Colors.white))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.isDhivehi ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(text('Shop Location', 'ފިހާރައިގެ ލޮކޭޝަން'), style: style(fontWeight: FontWeight.bold)),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          text('Set seller location from current GPS, Google Maps link, or manual coordinates.', 'ސެލަރ ލޮކޭޝަން GPS، Google Maps link، ނުވަތަ ކޯޑިނޭޓްސްއިން ސެޓް ކުރޭ.'),
                          style: style(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Autocomplete<String>(
                          initialValue: TextEditingValue(text: _islandController.text),
                          optionsBuilder: (value) {
                            final query = value.text.trim().toLowerCase();
                            if (query.isEmpty) return maldivesInhabitedIslands.take(12);
                            return maldivesInhabitedIslands.where((island) => island.toLowerCase().contains(query)).take(15);
                          },
                          onSelected: (value) => _islandController.text = value,
                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                            if (controller.text != _islandController.text) {
                              controller.text = _islandController.text;
                            }
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: text('Island or location name', 'ރަށް ނުވަތަ ތަނުގެ ނަން'),
                                prefixIcon: const Icon(Icons.place_rounded),
                              ),
                              onChanged: (value) => _islandController.text = value,
                              validator: (value) => value == null || value.trim().isEmpty
                                  ? text('Enter island or location name.', 'ރަށް ނުވަތަ ތަނެއް ލިޔޭ.')
                                  : null,
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _mapLinkController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: text('Google Maps link or coordinates', 'Google Maps link ނުވަތަ ކޯޑިނޭޓްސް'),
                            hintText: 'https://maps.google.com/... or 4.1755, 73.5093',
                            prefixIcon: const Icon(Icons.map_rounded),
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _setFromMapLink,
                          icon: const Icon(Icons.add_location_alt_rounded),
                          label: Text(text('Set From Link', 'ލިންކުން ސެޓް ކުރޭ'), style: style(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _latitudeController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                decoration: InputDecoration(labelText: text('Latitude', 'ލެޓިޓިއުޑް')),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _longitudeController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                decoration: InputDecoration(labelText: text('Longitude', 'ލޮންޖިޓިއުޑް')),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _locating ? null : _useCurrentLocation,
                              icon: _locating
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.my_location_rounded),
                              label: Text(text('Use Current GPS', 'މިހާރުގެ GPS ބޭނުންކުރޭ'), style: style(fontWeight: FontWeight.bold)),
                            ),
                            OutlinedButton.icon(
                              onPressed: _openGoogleMaps,
                              icon: const Icon(Icons.map_outlined),
                              label: Text(text('Open Google Maps', 'Google Maps ހުޅުވާ'), style: style(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_rounded),
                    label: Text(text('Save Location', 'ލޮކޭޝަން ސޭވްކުރޭ'), style: style(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
