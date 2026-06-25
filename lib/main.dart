import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'firebase_options.dart';
import 'models/app_language.dart';
import 'models/app_user.dart';
import 'screens/admin_page.dart';
import 'screens/business_portal_page.dart';
import 'screens/client_home_page.dart';
import 'screens/login_page.dart';
import 'services/auth_service.dart';
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: 'https://nhbslwtdpzzehdooueho.supabase.co',
    publishableKey: 'sb_publishable_QN4Ev6jvIj1T57HKXuV0qw_Srp0_lH4',
  );

  await PushNotificationService.instance.initialize();

  runApp(const ViyafaariTownApp());
}

class ViyafaariTownApp extends StatefulWidget {
  const ViyafaariTownApp({super.key});

  @override
  State<ViyafaariTownApp> createState() => _ViyafaariTownAppState();
}

class _ViyafaariTownAppState extends State<ViyafaariTownApp> {
  ThemeMode _themeMode = ThemeMode.light;
  AppLanguage _language = AppLanguage.english;

  bool get _isDarkMode => _themeMode == ThemeMode.dark;

  void _changeTheme(bool darkMode) {
    setState(() {
      _themeMode = darkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _changeLanguage(AppLanguage language) {
    setState(() {
      _language = language;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EHFASS Viyafaari',
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00A878),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7F8),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF17212B),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: Colors.black.withValues(alpha: 0.08),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00C896),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF101417),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF181E22),
          foregroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF20272C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: AuthGate(
        language: _language,
        isDarkMode: _isDarkMode,
        onLanguageChanged: _changeLanguage,
        onThemeChanged: _changeTheme,
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.language,
    required this.isDarkMode,
    required this.onLanguageChanged,
    required this.onThemeChanged,
  });

  final AppLanguage language;
  final bool isDarkMode;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final ValueChanged<bool> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingPage();
        }

        final firebaseUser = authSnapshot.data;
        if (firebaseUser == null) {
          return LoginPage(
            key: const ValueKey<String>('login-page'),
            isDhivehi: language == AppLanguage.dhivehi,
            isDarkMode: isDarkMode,
            onLanguageChanged: () {
              onLanguageChanged(
                language == AppLanguage.dhivehi
                    ? AppLanguage.english
                    : AppLanguage.dhivehi,
              );
            },
            onThemeChanged: () => onThemeChanged(!isDarkMode),
          );
        }

        return StreamBuilder<AppUser?>(
          key: ValueKey<String>('profile-${firebaseUser.uid}'),
          stream: AuthService.instance.watchUser(firebaseUser.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingPage();
            }

            if (profileSnapshot.hasError) {
              return _ProfileErrorPage(
                message: profileSnapshot.error.toString(),
              );
            }

            final profile = profileSnapshot.data;
            if (profile == null) {
              return const _ProfileErrorPage(
                message:
                    'The Firebase account exists, but its Firestore user profile is missing.',
              );
            }

            PushNotificationService.instance.syncTokenForUser(profile);

            if (profile.isBusiness) {
              return BusinessPortalPage(
                key: ValueKey<String>(
                  'business-${profile.uid}-${profile.businessId}',
                ),
                businessUser: profile,
                isDhivehi: language == AppLanguage.dhivehi,
                isDarkMode: isDarkMode,
                onLanguageChanged: (useDhivehi) {
                  onLanguageChanged(
                    useDhivehi ? AppLanguage.dhivehi : AppLanguage.english,
                  );
                },
                onThemeChanged: onThemeChanged,
              );
            }

            if (profile.isAdmin) {
              return AdminPage(
                key: ValueKey<String>('admin-${profile.uid}'),
                admin: profile,
                isDhivehi: language == AppLanguage.dhivehi,
                isDarkMode: isDarkMode,
                onLanguageChanged: (useDhivehi) {
                  onLanguageChanged(
                    useDhivehi ? AppLanguage.dhivehi : AppLanguage.english,
                  );
                },
                onThemeChanged: onThemeChanged,
              );
            }

            return ClientHomePage(
              key: ValueKey<String>('client-${profile.uid}'),
              user: profile,
              language: language,
              isDarkMode: isDarkMode,
              onLanguageChanged: onLanguageChanged,
              onThemeChanged: onThemeChanged,
            );
          },
        );
      },
    );
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ProfileErrorPage extends StatelessWidget {
  const _ProfileErrorPage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Error')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 70),
                const SizedBox(height: 16),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () async {
                    await AuthService.instance.signOut();
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Log Out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
