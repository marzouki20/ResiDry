import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../core/localization/app_locale.dart';

import '../../core/theme/app_theme.dart';
import '../../models/laundry_role.dart';
import '../../models/user.dart';
import '../auth/presentation/auth_screen.dart';
import 'data/repositories/laundry_repository.dart';
import 'presentation/laundry_page.dart';
import 'presentation/pages/driver_laundry_page.dart';
import 'presentation/pages/pressing_laundry_page.dart';
import 'presentation/pages/resident_laundry_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LaundryDevApp());
}

/// Uses the team's real login. Changing a dropdown never grants another role.
class LaundryDevApp extends StatefulWidget {
  const LaundryDevApp({super.key, this.repository});
  final LaundryRepository? repository;
  @override
  State<LaundryDevApp> createState() => _LaundryDevAppState();
}

class _LaundryDevAppState extends State<LaundryDevApp> {
  final _locale = AppLocaleController(initialLocale: const Locale('en'));

  @override
  void dispose() {
    _locale.dispose();
    super.dispose();
  }

  late final Future<User>? _account = widget.repository?.getCurrentUser();

  @override
  Widget build(BuildContext context) => AppLocaleScope(
    controller: _locale,
    child: AnimatedBuilder(
      animation: _locale,
      builder: (context, _) => MaterialApp(
        locale: _locale.locale,
        supportedLocales: supportedAppLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        title: 'ResiDry - Gestion du linge',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: widget.repository == null
            ? const AuthScreen()
            : FutureBuilder<User>(
                future: _account,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Scaffold(
                      body: Center(child: Text('Connexion requise.')),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final repository = widget.repository!;
                  return switch (laundryRoleFromUserRole(snapshot.data!.role)) {
                    LaundryRole.resident => ResidentLaundryPage(
                      repository: repository,
                    ),
                    LaundryRole.admin => LaundryPage(repository: repository),
                    LaundryRole.driver => Scaffold(
                      appBar: AppBar(
                        title: Text(context.localize('Livraison du linge')),
                      ),
                      body: DriverLaundryPage(repository: repository),
                    ),
                    LaundryRole.pressing => Scaffold(
                      appBar: AppBar(
                        title: Text(context.localize('Gestion du pressing')),
                      ),
                      body: PressingLaundryPage(repository: repository),
                    ),
                    null => const Scaffold(
                      body: Center(child: Text('Rôle non autorisé.')),
                    ),
                  };
                },
              ),
      ),
    ),
  );
}
