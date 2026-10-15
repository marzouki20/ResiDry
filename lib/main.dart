import 'package:flutter/material.dart';

import 'app.dart';
import 'features/laundry_companies/data/sample_laundry_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LaundryRepository.instance.initDatabase();
  runApp(const OrbitApp());
}
