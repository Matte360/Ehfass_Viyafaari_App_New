import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'register_page.dart';
import '../widgets/app_logo.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.isDhivehi,
    required this.isDarkMode,
    required this.onLanguageChanged,
    required this.onThemeChanged,
  });

  final bool isDhivehi;
  final bool isDarkMode;
  final VoidCallback onLanguageChanged;
  final VoidCallback onThemeChanged;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _hidePassword = true;
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
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.instance.signIn(
        emailOrUsername: _identifierController.text,
        password: _passwordController.text,
      );

      // Do not call setState, Navigator, or show a SnackBar here.
      // AuthGate listens to Firebase and replaces LoginPage automatically.
      return;
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      final message = switch (error.code) {
        'invalid-credential' => text(
            'Incorrect email, username or password.',
            'އީމެއިލް، ޔޫޒަރނޭމް ނުވަތަ ޕާސްވޯޑް ރަނގަޅެއް ނޫން.',
          ),
        'user-not-found' => text(
            'No account was found.',
            'އެކައުންޓެއް ނުފެނުނު.',
          ),
        'too-many-requests' => text(
            'Too many attempts. Please try again later.',
            'ވަރަށް ގިނަ ފަހަރު ބަލާފައިވާތީ ފަހުން އަލުން ބަލާ.',
          ),
        _ => error.message ?? text(
            'Login failed.',
            'ލޮގިން ނުކުރެވުނު.',
          ),
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            message,
            style: style(color: Colors.white),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            '${text('Login failed', 'ލޮގިން ނުކުރެވުނު')}: $error',
            style: style(color: Colors.white),
          ),
        ),
      );
    }
  }

  Future<void> _resetPassword() async {
    final controller = TextEditingController(
      text: _identifierController.text.contains('@')
          ? _identifierController.text.trim()
          : '',
    );

    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            text('Reset Password', 'ޕާސްވޯޑް ރީސެޓް ކުރޭ'),
            style: style(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: text('Email', 'އީމެއިލް'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(text('Cancel', 'ކެންސަލް'), style: style()),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                controller.text.trim(),
              ),
              child: Text(text('Send', 'ފޮނުވާ'), style: style()),
            ),
          ],
        );
      },
    );

    controller.dispose();
    if (email == null || email.isEmpty) return;

    try {
      await AuthService.instance.sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            text(
              'Password reset email sent.',
              'ޕާސްވޯޑް ރީސެޓް އީމެއިލް ފޮނުވިއްޖެ.',
            ),
            style: style(),
          ),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            error.message ?? text('Request failed.', 'ރިކުއެސްޓް ނުފޮނުވުނު.'),
            style: style(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          widget.isDhivehi ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 470),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: widget.onThemeChanged,
                          icon: Icon(
                            widget.isDarkMode
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: widget.onLanguageChanged,
                          icon: const Icon(Icons.language_rounded),
                          label: Text(
                            widget.isDhivehi ? 'English' : 'ދިވެހި',
                            style: TextStyle(
                              fontFamily:
                                  widget.isDhivehi ? null : 'Faruma',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    const AppLogo(height: 150, showCard: true),
                    const SizedBox(height: 18),
                    Text(
                      text(
                        'Log in to continue',
                        'ކުރިއަށް ދިއުމަށް ލޮގިން ކުރައްވާ',
                      ),
                      style: style(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        text(
                          'Client • Admin • Business Login',
                          'ކްލައިންޓް • އެޑްމިން • ވިޔަފާރި ލޮގިން',
                        ),
                        style: style(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _identifierController,
                                textDirection: TextDirection.ltr,
                                decoration: InputDecoration(
                                  labelText: text(
                                    'Email or username',
                                    'އީމެއިލް ނުވަތަ ޔޫޒަރނޭމް',
                                  ),
                                  prefixIcon:
                                      const Icon(Icons.person_rounded),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return text(
                                      'Please enter your email or username.',
                                      'އީމެއިލް ނުވަތަ ޔޫޒަރނޭމް ލިޔުއްވާ.',
                                    );
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _hidePassword,
                                onFieldSubmitted: (_) => _login(),
                                decoration: InputDecoration(
                                  labelText: text('Password', 'ޕާސްވޯޑް'),
                                  prefixIcon:
                                      const Icon(Icons.lock_rounded),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _hidePassword = !_hidePassword;
                                      });
                                    },
                                    icon: Icon(
                                      _hidePassword
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return text(
                                      'Please enter your password.',
                                      'ޕާސްވޯޑް ލިޔުއްވާ.',
                                    );
                                  }
                                  return null;
                                },
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _resetPassword,
                                  child: Text(
                                    text(
                                      'Forgot password?',
                                      'ޕާސްވޯޑް ހަނދާން ނެތުނީ؟',
                                    ),
                                    style: style(),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: FilledButton(
                                  onPressed: _isLoading ? null : _login,
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 23,
                                          width: 23,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          text('Login', 'ލޮގިން'),
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
                    const SizedBox(height: 18),
                    Text(
                      text(
                        'Do not have an account?',
                        'އެކައުންޓެއް ނެތްތޯ؟',
                      ),
                      style: style(),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RegisterPage(
                              isDhivehi: widget.isDhivehi,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        text('Register Now', 'މިހާރު ރަޖިސްޓަރ ކުރޭ'),
                        style: style(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
