import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/localization/app_locale.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/language/presentation/language_selection_screen.dart';

class OrbitApp extends StatefulWidget {
  const OrbitApp({super.key, this.localeController});

  final AppLocaleController? localeController;

  @override
  State<OrbitApp> createState() => _OrbitAppState();
}

class _OrbitAppState extends State<OrbitApp> {
  late final AppLocaleController _localeController = widget.localeController ??
      AppLocaleController(initialLocale: const Locale('en'));

  @override
  Widget build(BuildContext context) {
    return AppLocaleScope(
      controller: _localeController,
      child: AnimatedBuilder(
        animation: _localeController,
        builder: (context, _) => MaterialApp(
          title: 'ResiDry',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: _localeController.locale,
          supportedLocales: supportedAppLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: _localeController.locale == null
              ? const LanguageSelectionScreen()
              : const AuthScreen(),
        ),
      ),
    );
  }
}
