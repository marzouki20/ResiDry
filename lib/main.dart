import 'package:flutter/material.dart';

import 'app.dart';
import 'core/localization/app_locale.dart';
import 'features/laundry_companies/data/sample_laundry_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localeController = await AppLocaleController.load();
  await LaundryRepository.instance.initDatabase();
  runApp(OrbitApp(localeController: localeController));
}
