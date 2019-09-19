import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'localization.dart';

class LocalizationDelegate extends LocalizationsDelegate<Localization> {
  const LocalizationDelegate();

  @override
  bool isSupported(Locale locale) => true;// Localization.isSupported(locale);

  @override
  Future<Localization> load(Locale locale) {
    return SynchronousFuture<Localization>(Localization(locale.languageCode));
  }

  @override
  bool shouldReload(LocalizationsDelegate<Localization> old) => false;
  
}