import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  static AppLocalizations? _current;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static AppLocalizations get current => _current ?? AppLocalizations(const Locale('en'));

  /// Global translation helper that can be called from anywhere
  static String tr(String key, {String? fallback}) {
    return _current?.translate(key, fallback: fallback) ?? fallback ?? key;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  Map<String, String> _localizedStrings = {};
  Map<String, String> _fallbackEnglishStrings = {};

  Future<bool> load() async {
    // 1. Load primary localized strings
    try {
      final jsonString = await rootBundle.loadString('assets/localization/${locale.languageCode}.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
    } catch (_) {
      _localizedStrings = {};
    }

    // 2. Load English as fallback dictionary for any missing keys
    if (locale.languageCode != 'en') {
      try {
        final enString = await rootBundle.loadString('assets/localization/en.json');
        final Map<String, dynamic> enMap = json.decode(enString);
        _fallbackEnglishStrings = enMap.map((key, value) => MapEntry(key, value.toString()));
      } catch (_) {
        _fallbackEnglishStrings = {};
      }
    }

    _current = this;
    return true;
  }

  String translate(String key, {String? fallback}) {
    return _localizedStrings[key] ?? _fallbackEnglishStrings[key] ?? fallback ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'hi', 'as'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension LocalizationExtension on BuildContext {
  String tr(String key, {String? fallback}) {
    return AppLocalizations.of(this)?.translate(key, fallback: fallback) ??
        AppLocalizations.tr(key, fallback: fallback);
  }
}
