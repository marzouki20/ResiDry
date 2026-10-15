import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'translation_catalog.dart';

const supportedAppLocales = <Locale>[
  Locale('fr'),
  Locale('en'),
  Locale('ar'),
];

class AppLocaleController extends ChangeNotifier {
  AppLocaleController({Locale? initialLocale}) : _locale = initialLocale;

  static const _preferenceKey = 'app_language';

  Locale? _locale;

  Locale? get locale => _locale;

  static Future<AppLocaleController> load() async {
    final preferences = await SharedPreferences.getInstance();
    final languageCode = preferences.getString(_preferenceKey);
    final locale = supportedAppLocales
        .where((candidate) => candidate.languageCode == languageCode)
        .firstOrNull;
    return AppLocaleController(initialLocale: locale);
  }

  Future<void> select(Locale locale) async {
    if (!supportedAppLocales.contains(locale)) {
      throw ArgumentError.value(locale, 'locale', 'Unsupported locale');
    }
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferenceKey, locale.languageCode);
  }
}

class AppLocaleScope extends InheritedNotifier<AppLocaleController> {
  const AppLocaleScope({
    super.key,
    required AppLocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppLocaleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();
    assert(scope != null, 'AppLocaleScope is missing above this context.');
    return scope!.notifier!;
  }
}

extension LocalizedBuildContext on BuildContext {
  bool get isFrench => Localizations.localeOf(this).languageCode == 'fr';
  bool get isArabic => Localizations.localeOf(this).languageCode == 'ar';

  String tr({required String en, required String fr, String? ar}) {
    if (isArabic) return ar ?? localize(en);
    return isFrench ? fr : en;
  }

  String localize(String source) =>
      translateDisplayText(source, Localizations.localeOf(this).languageCode);
}
