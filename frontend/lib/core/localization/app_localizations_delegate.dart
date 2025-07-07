import 'package:flutter/material.dart';
import 'app_localizations.dart';

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'am'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // Force reload from preferences to ensure the latest locale is used
    final actualLocale = await AppLocalizations.getLocale();

    // If loading a specific locale, but preferences has a different one,
    // respect the preference
    if (locale.languageCode != actualLocale.languageCode) {
      debugPrint(
          'Delegate loading ${actualLocale.languageCode} instead of requested ${locale.languageCode}');
      return AppLocalizations(actualLocale);
    }

    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) =>
      true; // Always reload on locale change
}
