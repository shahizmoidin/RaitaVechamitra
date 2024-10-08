import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import Shared Preferences

class LocaleProvider extends ChangeNotifier {
  Locale _locale = Locale('en'); // Default to English

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale(); // Load the saved locale on initialization
  }

  // Load locale from shared preferences
  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    String? languageCode = prefs.getString('language_code');
    if (languageCode != null) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }

  // Method to update the locale and notify listeners
  Future<void> setLocale(Locale locale) async {
    if (!L10n.all.contains(locale)) return; // Make sure the locale is supported
    _locale = locale;
    notifyListeners();
    await _saveLocale(locale.languageCode); // Save the new locale to shared preferences
  }

  // Save locale to shared preferences
  Future<void> _saveLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
  }

  // Reset to system locale
  void clearLocale() {
    _locale = Locale('en'); // Fallback to default
    notifyListeners();
    _saveLocale('en'); // Save the reset locale to shared preferences
  }
}

// Utility class for supported locales
class L10n {
  static final all = [
    Locale('en'),
    Locale('kn'),
     Locale('hi'),
  ];

  static String getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'kn':
        return 'Kannada';
        case 'hi':
        return 'Hindi';
      default:
        return 'English';
    }
  }
}

// Create a Riverpod provider for LocaleProvider
final localeProviderProvider = ChangeNotifierProvider((ref) => LocaleProvider());
