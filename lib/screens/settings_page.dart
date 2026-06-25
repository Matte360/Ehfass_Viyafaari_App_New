import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../utils/image_crop_helper.dart';
import '../widgets/user_avatar.dart';
import 'add_business_page.dart';
import 'advertisement_request_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.user,
    required this.isDhivehi,
    required this.isDarkMode,
    required this.onLanguageChanged,
    required this.onThemeChanged,
  });

  final AppUser user;
  final bool isDhivehi;
  final bool isDarkMode;
  final ValueChanged<bool> onLanguageChanged;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _isDhivehi;
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDhivehi = widget.isDhivehi;
    _isDarkMode = widget.isDarkMode;
  }

  String text(String english, String dhivehi) {
    return _isDhivehi ? dhivehi : english;
  }

  TextStyle style({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: _isDhivehi ? 'Faruma' : null,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isDhivehi ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            text('Settings', 'ސެޓިންގްސް'),
            style: style(fontWeight: FontWeight.bold),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    UserAvatar(user: widget.user, radius: 34),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.user.fullName,
                            style: style(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('@${widget.user.username}', style: style()),
                          Text(widget.user.email, style: style()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            _sectionTitle(text('Appearance', 'ފެންނަ ގޮތް')),
            Card(
              child: SwitchListTile(
                value: _isDarkMode,
                secondary: Icon(
                  _isDarkMode
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                ),
                title: Text(
                  text(
                    _isDarkMode ? 'Dark Mode' : 'Light Mode',
                    _isDarkMode ? 'ޑާކް މޯޑް' : 'ލައިޓް މޯޑް',
                  ),
                  style: style(fontWeight: FontWeight.bold),
                ),
                onChanged: (value) {
                  setState(() => _isDarkMode = value);
                  widget.onThemeChanged(value);
                },
              ),
            ),
            const SizedBox(height: 18),
            _sectionTitle(text('Language', 'ބަސް')),
            Card(
              child: RadioGroup<bool>(
                groupValue: _isDhivehi,
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _isDhivehi = value;
                  });

                  widget.onLanguageChanged(value);
                },
                child: const Column(
                  children: [
                    RadioListTile<bool>(
                      value: false,
                      title: Text('English'),
                    ),
                    RadioListTile<bool>(
                      value: true,
                      title: Text(
                        'ދިވެހި',
                        style: TextStyle(fontFamily: 'Faruma'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            _sectionTitle(
              text('Account and Business', 'އެކައުންޓް އަދި ވިޔަފާރި'),
            ),
            Card(
              child: Column(
                children: [
                  _tile(
                    Icons.manage_accounts_rounded,
                    text(
                      'Edit User Information',
                      'ޔޫޒަރގެ މަޢުލޫމާތު ބަދަލުކުރޭ',
                    ),
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfilePage(
                            user: widget.user,
                            isDhivehi: _isDhivehi,
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _tile(
                    Icons.add_business_rounded,
                    text(
                      'Add Your Business',
                      'ތިޔަ ވިޔަފާރި އިތުރުކުރޭ',
                    ),
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddBusinessPage(
                            user: widget.user,
                            isDhivehi: _isDhivehi,
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _tile(
                    Icons.campaign_rounded,
                    text(
                      'Request Advertisement',
                      'އިޢުލާނެއް ރިކުއެސްޓް ކުރޭ',
                    ),
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdvertisementRequestPage(
                            user: widget.user,
                            isDhivehi: _isDhivehi,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 0, 5, 8),
      child: Text(
        title,
        style: style(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: style(fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 17),
      onTap: onTap,
    );
  }
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
    required this.user,
    required this.isDhivehi,
  });

  final AppUser user;
  final bool isDhivehi;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _phoneController;
  final _picker = ImagePicker();
  Uint8List? _profileImageBytes;
  String? _profileImageName;
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
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.user.fullName);
    _usernameController = TextEditingController(text: widget.user.username);
    _phoneController = TextEditingController(text: widget.user.phone);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final cropped = await pickImageCropAndSet(
      context: context,
      picker: _picker,
      isDhivehi: widget.isDhivehi,
      title: text('Crop Profile Image', 'ޕްރޮފައިލް ފޮޓޯ ކްރޮޕް ކުރޭ'),
      initialMode: ImageCropMode.square,
      imageQuality: 88,
      maxWidth: 1200,
    );
    if (cropped == null || !mounted) return;

    setState(() {
      _profileImageBytes = cropped.bytes;
      _profileImageName = cropped.fileName;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await AuthService.instance.updateProfile(
        currentUser: widget.user,
        fullName: _fullNameController.text,
        username: _usernameController.text,
        phone: _phoneController.text,
        profileImageBytes: _profileImageBytes,
        profileImageFileName: _profileImageName,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            text(
              'Profile updated successfully.',
              'ޕްރޮފައިލް އަޕްޑޭޓް ކުރެވިއްޖެ.',
            ),
            style: style(color: Colors.white),
          ),
        ),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            error.message ?? text('Update failed.', 'އަޕްޑޭޓް ނުކުރެވުނު.'),
            style: style(color: Colors.white),
          ),
        ),
      );
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
            text('Edit User Information', 'ޔޫޒަރ މަޢުލޫމާތު ބަދަލުކުރޭ'),
            style: style(fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        UserAvatar(
                          user: widget.user,
                          radius: 48,
                          imageBytes: _profileImageBytes,
                          onTap: _isLoading ? null : _pickProfileImage,
                        ),
                        IconButton.filled(
                          onPressed: _isLoading ? null : _pickProfileImage,
                          icon: const Icon(Icons.photo_camera_rounded, size: 18),
                          tooltip: text('Choose profile image', 'ޕްރޮފައިލް ފޮޓޯ ހޮވާ'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      text('Tap the photo to crop and set profile image.', 'ފޮޓޯއަށް ފިއްތައި ކްރޮޕް ކޮށް ސެޓް ކުރޭ.'),
                      textAlign: TextAlign.center,
                      style: style(color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        labelText: text('Full Name', 'ފުރިހަމަ ނަން'),
                        prefixIcon: const Icon(Icons.badge_rounded),
                      ),
                      validator: (value) =>
                          value == null || value.trim().length < 3
                              ? text(
                                  'Please enter your full name.',
                                  'ފުރިހަމަ ނަން ލިޔުއްވާ.',
                                )
                              : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _usernameController,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        labelText: text('Username', 'ޔޫޒަރނޭމް'),
                        prefixIcon: const Icon(Icons.person_rounded),
                      ),
                      validator: (value) {
                        if (!RegExp(r'^[a-zA-Z0-9._]{3,30}$')
                            .hasMatch(value?.trim() ?? '')) {
                          return text(
                            'Use 3-30 letters, numbers, dots or underscores.',
                            '3-30 އަކުރު، ނަންބަރު، ޑޮޓް ނުވަތަ އަންޑަސްކޯރ ބޭނުންކުރޭ.',
                          );
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        labelText: text('Phone Number', 'ފޯނު ނަންބަރު'),
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
                      initialValue: widget.user.email,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: text('Email', 'އީމެއިލް'),
                        prefixIcon: const Icon(Icons.email_rounded),
                        helperText: text(
                          'Email changes require account verification.',
                          'އީމެއިލް ބަދަލުކުރުމަށް އެކައުންޓް ވެރިފައި ކުރަންޖެހޭ.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : _save,
                        icon: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(
                          text('Save Changes', 'ބަދަލުތައް ސޭވްކުރޭ'),
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
