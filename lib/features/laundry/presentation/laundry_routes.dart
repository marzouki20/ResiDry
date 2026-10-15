import 'driver_laundry_page.dart';

import 'package:flutter/material.dart';

import '../data/repositories/laundry_repository.dart';
import 'laundry_page.dart';
import 'pressing_laundry_page.dart';
import 'resident_laundry_page.dart';

class LaundryRoutes {
  LaundryRoutes._();

  static const String resident = '/laundry/resident';
  static const String pressing = '/laundry/pressing';
  static const String driver = '/laundry/driver';
  static const String admin = '/laundry/admin';

  static Route<void> residentPage({
    required int residentId,
    required String residentName,
    required LaundryRepository repository,
  }) {
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: resident),
      builder: (_) => ResidentLaundryPage(
        residentId: residentId,
        residentName: residentName,
        repository: repository,
      ),
    );
  }

  static Route<void> driverPage({
    required LaundryRepository repository,
    int? userId,
  }) => MaterialPageRoute<void>(
    settings: const RouteSettings(name: driver),
    builder: (_) => Scaffold(
      appBar: AppBar(title: const Text('Livraison du linge')),
      body: DriverLaundryPage(repository: repository, userId: userId),
    ),
  );

  static Route<void> pressingPage({
    required LaundryRepository repository,
    int? userId,
  }) {
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: pressing),
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Société de pressing')),
        body: PressingLaundryPage(repository: repository, userId: userId),
      ),
    );
  }

  static Route<void> adminPage({required LaundryRepository repository}) {
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: admin),
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Gestion du linge')),
        body: LaundryPage(repository: repository),
      ),
    );
  }
}
