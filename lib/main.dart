import 'package:flutter/material.dart';

import 'app.dart';
import 'core/localization/app_locale.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localeController = await AppLocaleController.load();
  runApp(OrbitApp(localeController: localeController));
}
