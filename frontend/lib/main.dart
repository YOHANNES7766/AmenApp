import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'features/user/screens/login_screen.dart';
import 'features/user/screens/register_screen.dart';
import 'features/user/screens/home_screen.dart';
import 'features/admin/screens/admin_home_screen.dart';
import 'shared/services/auth_service.dart';
import 'shared/services/theme_service.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/app_localizations_delegate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

// Language change notifier
class LanguageChangeNotifier extends ChangeNotifier {
  Locale _locale = const Locale('en');
  bool _isChanging = false;

  Locale get locale => _locale;
  bool get isChanging => _isChanging;

  void setLocale(Locale locale) {
    if (_locale.languageCode != locale.languageCode) {
      debugPrint(
          'Changing language from ${_locale.languageCode} to ${locale.languageCode}');
      _locale = locale;
      notifyListeners();
    }
  }

  void setChanging(bool value) {
    _isChanging = value;
    notifyListeners();
  }
}

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Keep the splash screen until the app is fully loaded
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Preload fonts
  await GoogleFonts.pendingFonts([
    GoogleFonts.playfairDisplay(),
  ]);

  final locale = await AppLocalizations.getLocale();
  debugPrint('Initial locale: ${locale.languageCode}');

  // Initialize theme
  final themeService = ThemeService();
  // Set Bible Study as the default theme
  if (themeService.currentTheme != ThemeType.bibleStudy) {
    await themeService.setTheme(ThemeType.bibleStudy);
  }

  // Remove splash screen when initialization is complete
  FlutterNativeSplash.remove();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider.value(value: themeService),
        ChangeNotifierProvider(
            create: (_) => LanguageChangeNotifier()..setLocale(locale)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Use a ValueNotifier to trigger rebuilds without recreating the entire widget tree
  final ValueNotifier<int> _rebuildNotifier = ValueNotifier<int>(0);
  bool _isCheckingLocale = false;

  @override
  void initState() {
    super.initState();
    // Check for language changes when app starts
    _checkLocaleChange();
  }

  @override
  void dispose() {
    _rebuildNotifier.dispose();
    super.dispose();
  }

  // Force rebuild the app without recreating it entirely
  void _rebuildApp() {
    // Just increment the counter to trigger a rebuild
    _rebuildNotifier.value++;
  }

  // Check for language changes safely
  Future<void> _checkLocaleChange() async {
    if (_isCheckingLocale) return;
    _isCheckingLocale = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();

      final languageCode = prefs.getString('languageCode') ?? 'en';
      final languageNotifier =
          Provider.of<LanguageChangeNotifier>(context, listen: false);

      if (languageNotifier.locale.languageCode != languageCode) {
        languageNotifier.setLocale(Locale(languageCode));

        // Delay to ensure the UI has time to update
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          _rebuildApp();
        }
      }
    } catch (e) {
      debugPrint('Error checking locale change: $e');
    } finally {
      _isCheckingLocale = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final authService = Provider.of<AuthService>(context);
    final languageNotifier = Provider.of<LanguageChangeNotifier>(context);

    // Listen to rebuild notifier
    return ValueListenableBuilder<int>(
        valueListenable: _rebuildNotifier,
        builder: (context, _, __) {
          return MaterialApp(
            title: 'Amen App',
            debugShowCheckedModeBanner: false,
            locale: languageNotifier.locale,
            supportedLocales: const [
              Locale('en', ''), // English
              Locale('am', ''), // Amharic
              Locale('or', ''), // Afaan Oromoo (not fully implemented yet)
              Locale('ti', ''), // Tigrinya (not fully implemented yet)
              Locale('so', ''), // Somali (not fully implemented yet)
            ],
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            localeResolutionCallback: (locale, supportedLocales) {
              if (locale == null) {
                return supportedLocales.first;
              }
              for (var supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale.languageCode) {
                  return supportedLocale;
                }
              }
              return supportedLocales.first;
            },
            theme: themeService.theme.copyWith(
              textTheme: GoogleFonts.playfairDisplayTextTheme(
                themeService.theme.textTheme,
              ),
            ),
            initialRoute: '/login',
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/home': (context) => authService.isAdmin
                  ? const AdminHomeScreen()
                  : const HomeScreen(),
            },
          );
        });
  }
}
