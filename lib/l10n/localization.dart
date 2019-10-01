import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'localization_base.dart';
import 'localization_en.dart';

typedef TranslationGetter = LocalizationBase Function();

class Localization {
  static Localization _lastLocalization = Localization('en');

  static Map<String, TranslationGetter> _getLanguage = {
    'en': () => LocalizationEn(),
  };
  final Map<String, String> _baseTranslations = LocalizationEn().translations;
  final _language;
  final Map<String, String> _currentTranslations;

  Localization(String language) : _language = language,  
                                _currentTranslations = _getLanguage.containsKey(language) ? _getLanguage[language]().translations : LocalizationEn().translations;

  static Localization of(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    if (language != _lastLocalization._language) {
      _lastLocalization = Localization(language);
    }
    return Localization(language);
  }

  static bool isSupported(Locale locale) {
    return _getLanguage.containsKey(locale.languageCode);
  }

  String tr(String id) => _currentTranslations.containsKey(id) ? _currentTranslations[id] : _baseTranslations.containsKey(id) ? _baseTranslations[id] : 'Invalid string resource: \"$id\"';
  String ttr(String id) => _currentTranslations.containsKey(id) ? _currentTranslations[id] : _baseTranslations.containsKey(id) ? _baseTranslations[id] : id;
  
}