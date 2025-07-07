import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeType { classic, day, tinted, night, bibleStudy }

class ThemeService extends ChangeNotifier {
  ThemeType _currentTheme = ThemeType.classic;
  bool _autoNightMode = false;
  String _fontFamily = 'Default';
  Color _nameColor = Colors.purple;
  ThemeData? _cachedTheme;

  ThemeType get currentTheme => _currentTheme;
  bool get autoNightMode => _autoNightMode;
  String get fontFamily => _fontFamily;
  Color get nameColor => _nameColor;

  ThemeService() {
    _loadThemePreferences();
  }

  ThemeData get theme {
    if (_cachedTheme != null) {
      return _cachedTheme!;
    }
    _cachedTheme = _buildTheme();
    return _cachedTheme!;
  }

  ThemeData _buildTheme() {
    final isDark =
        _currentTheme == ThemeType.tinted || _currentTheme == ThemeType.night;
    final primaryColor = _getPrimaryColor();
    final backgroundColor = _getBackgroundColor();

    final base = isDark ? ThemeData.dark() : ThemeData.light();
    return base.copyWith(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: base.colorScheme.copyWith(
        primary: isDark ? const Color(0xFF64B5F6) : Colors.blue,
        surface: isDark ? const Color(0xFF1E2732) : Colors.white,
        onSurface: isDark ? Colors.white : Colors.black87,
        secondary: const Color(0xFF64B5F6),
        onPrimary: Colors.white,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ),
      brightness: isDark ? Brightness.dark : Brightness.light,
      drawerTheme: DrawerThemeData(
        backgroundColor: isDark ? const Color(0xFF1E2732) : Colors.white,
        scrimColor: Colors.black54,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF1E2732) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black87,
        ),
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: const Color(0xFF1E2732),
                systemNavigationBarIconBrightness: Brightness.light,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.white,
                systemNavigationBarIconBrightness: Brightness.dark,
              ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1E2732) : Colors.white,
        indicatorColor: isDark
            ? const Color(0xFF64B5F6).withOpacity(0.2)
            : Colors.blue.withOpacity(0.1),
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.all(
          IconThemeData(
            color: isDark ? Colors.white70 : Colors.black54,
            size: 24,
          ),
        ),
        height: 80,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1E2732) : Colors.white,
        selectedItemColor: isDark ? const Color(0xFF64B5F6) : Colors.blue,
        unselectedItemColor: isDark ? Colors.white60 : Colors.black54,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1E2732) : Colors.grey[100],
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.black54,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.white60 : Colors.black45,
          fontSize: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white24 : Colors.black12,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white24 : Colors.black12,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF64B5F6) : Colors.blue,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.5,
          ),
        ),
      ),
      cardTheme: CardTheme(
        color: isDark ? const Color(0xFF1E2732) : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
            width: 1,
          ),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: isDark ? Colors.white : Colors.black87,
        displayColor: isDark ? Colors.white : Colors.black87,
      ),
      iconTheme: IconThemeData(
        color: isDark ? const Color(0xFF64B5F6) : Colors.blue,
        size: 24,
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.white12 : Colors.black12,
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF64B5F6);
          }
          return isDark ? Colors.grey : Colors.grey[400];
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF64B5F6).withOpacity(0.5);
          }
          return isDark ? Colors.white24 : Colors.black12;
        }),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: isDark ? const Color(0xFF64B5F6) : Colors.blue,
        textColor: isDark ? Colors.white : Colors.black87,
        tileColor: Colors.transparent,
      ),
    );
  }

  Color _getPrimaryColor() {
    switch (_currentTheme) {
      case ThemeType.classic:
        return Colors.green[200]!;
      case ThemeType.day:
        return Colors.blue[200]!;
      case ThemeType.tinted:
        return const Color(0xFF242F3D);
      case ThemeType.night:
        return const Color(0xFF1E2732);
      case ThemeType.bibleStudy:
        return const Color(0xFF8c6d46);
    }
  }

  Color _getBackgroundColor() {
    switch (_currentTheme) {
      case ThemeType.classic:
      case ThemeType.day:
        return Colors.white;
      case ThemeType.tinted:
        return const Color(0xFF17212B);
      case ThemeType.night:
        return const Color(0xFF141D26);
      case ThemeType.bibleStudy:
        return const Color(0xFFf8f4e3);
    }
  }

  Future<void> _loadThemePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentTheme = ThemeType.values[prefs.getInt('themeType') ?? 0];
      _autoNightMode = prefs.getBool('autoNightMode') ?? false;
      _fontFamily = prefs.getString('fontFamily') ?? 'Default';
      _nameColor = Color(prefs.getInt('nameColor') ?? Colors.purple.value);
      _cachedTheme = null; // Clear cache to rebuild with new preferences
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme preferences: $e');
    }
  }

  Future<void> setTheme(ThemeType theme) async {
    if (_currentTheme == theme) return;
    _currentTheme = theme;
    _cachedTheme = null; // Clear cache to rebuild with new theme
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('themeType', theme.index);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  Future<void> setAutoNightMode(bool value) async {
    _autoNightMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoNightMode', value);
    notifyListeners();
  }

  Future<void> setFontFamily(String family) async {
    _fontFamily = family;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fontFamily', family);
    notifyListeners();
  }

  Future<void> setNameColor(Color color) async {
    _nameColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('nameColor', color.value);
    notifyListeners();
  }
}
