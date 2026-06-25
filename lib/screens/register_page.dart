import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/app_logo.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
    required this.isDhivehi,
  });

  final bool isDhivehi;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController(text: '+960');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _isLoading = false;

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
    _fullNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AuthService.instance.register(
        fullName: _fullNameController.text,
        username: _usernameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      final message = switch (error.code) {
        'email-already-in-use' => text(
            'This email already has an account.',
            'މި އީމެއިލްއަށް އެކައުންޓެއް ހުރެއެވެ.',
          ),
        'username-already-in-use' => text(
            'This username is already in use.',
            'މި ޔޫޒަރނޭމް ބޭނުންކުރެވިފައި ވެއެވެ.',
          ),
        'weak-password' => text(
            'The password is too weak.',
            'ޕާސްވޯޑް ވަރަށް ދެރަ.',
          ),
        'invalid-email' => text(
            'The email address is not valid.',
            'އީމެއިލް އެޑްރެސް ރަނގަޅެއް ނޫން.',
          ),
        'invalid-username' => error.message ?? 'Invalid username.',
        _ => error.message ??
            text('Registration failed.', 'ރަޖިސްޓަރ ނުކުރެވުނު.'),
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(message, style: style(color: Colors.white)),
        ),
      );
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Firebase registration error: ${error.code}');
      debugPrint(error.message ?? error.toString());
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      final message = switch (error.code) {
        'permission-denied' => text(
            'Firestore permission denied. Publish the supplied Firestore rules, wait one minute, and try again.',
            'ފަޔަރސްޓޯރ ހުއްދަ ނުދެއެވެ. Firestore Rules ޕަބްލިޝްކޮށް މިނިޓެއް ފަހުން އަލުން ބަލާ.',
          ),
        'unavailable' => text(
            'Firebase is temporarily unavailable. Check your internet connection and try again.',
            'ފަޔަރބޭސް މިހާރު ނުލިބެއެވެ. އިންޓަނެޓް ބަލައި އަލުން ބަލާ.',
          ),
        'failed-precondition' => text(
            'Firestore is not ready. Confirm that the Firestore database was created in this Firebase project.',
            'Firestore ތައްޔާރެއް ނޫން. މި Firebase project ގައި Firestore database ހެދިފައިވޭތޯ ބަލާ.',
          ),
        _ => error.message ??
            text('Firebase registration failed.',
                'Firebase ރަޖިސްޓަރ ނުކުރެވުނު.'),
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(message, style: style(color: Colors.white)),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Unexpected registration error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            text(
              'Unexpected registration error. Check the Debug Console for the real error.',
              'ރަޖިސްޓަރކުރުމުގައި ނޭނގޭ މައްސަލައެއް ދިމާވެއްޖެ. Debug Console ބަލާ.',
            ),
            style: style(color: Colors.white),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.isDhivehi ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            text('Create Account', 'އެކައުންޓް ހަދާ'),
            style: style(fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const AppLogo(height: 120, showCard: true),
                      const SizedBox(height: 16),
                      Text(
                        text(
                          'Create your customer account',
                          'ތިޔަ ކަސްޓަމަރ އެކައުންޓް ހަދާ',
                        ),
                        textAlign: TextAlign.center,
                        style: style(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 26),
                      TextFormField(
                        controller: _fullNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: text('Full name', 'ފުރިހަމަ ނަން'),
                          prefixIcon: const Icon(Icons.badge_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 3) {
                            return text(
                              'Please enter your full name.',
                              'ފުރިހަމަ ނަން ލިޔުއްވާ.',
                            );
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _usernameController,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: text('Username', 'ޔޫޒަރނޭމް'),
                          prefixIcon: const Icon(Icons.person_rounded),
                          helperText: 'Letters, numbers, dot and underscore',
                        ),
                        validator: (value) {
                          final username = value?.trim().toLowerCase() ?? '';
                          if (!RegExp(r'^[a-z0-9._]{3,30}$')
                              .hasMatch(username)) {
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
                          labelText: text('Phone number', 'ފޯނު ނަންބަރު'),
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
                          labelText: text('Email', 'އީމެއިލް'),
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
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _hidePassword,
                        decoration: InputDecoration(
                          labelText: text('Password', 'ޕާސްވޯޑް'),
                          prefixIcon: const Icon(Icons.lock_rounded),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() => _hidePassword = !_hidePassword);
                            },
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if ((value ?? '').length < 6) {
                            return text(
                              'Password must have at least 6 characters.',
                              'ޕާސްވޯޑްގައި މަދުވެގެން 6 އަކުރު ހުންނަންވާނެ.',
                            );
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _hideConfirmPassword,
                        decoration: InputDecoration(
                          labelText: text(
                            'Re-enter password',
                            'ޕާސްވޯޑް އަލުން ލިޔޭ',
                          ),
                          prefixIcon: const Icon(Icons.lock_reset_rounded),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _hideConfirmPassword = !_hideConfirmPassword;
                              });
                            },
                            icon: Icon(
                              _hideConfirmPassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return text(
                              'Passwords do not match.',
                              'ދެ ޕާސްވޯޑް އެއްގޮތެއް ނޫން.',
                            );
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        height: 53,
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _register,
                          icon: _isLoading
                              ? const SizedBox(
                                  height: 21,
                                  width: 21,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.person_add_rounded),
                          label: Text(
                            text('Register', 'ރަޖިސްޓަރ'),
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
