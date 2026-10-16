import 'package:flutter/material.dart';

import '../../../../models/user.dart';
import '../../data/repositories/laundry_repository.dart';
import '../laundry_page.dart';
import '../pages/driver_laundry_page.dart';
import '../pages/pressing_laundry_page.dart';
import '../pages/resident_laundry_page.dart';

class LaundryRoutes {
  LaundryRoutes._();

  static const String resident = '/laundry/resident';
  static const String pressing = '/laundry/pressing';
  static const String driver = '/laundry/driver';
  static const String admin = '/laundry/admin';

  static Route<void> residentPage({
    int? residentId,
    String? residentName,
    User? currentUser,
    LaundryRepository? repository,
  }) {
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: resident),
      builder: (_) => ResidentLaundryPage(
        residentId: currentUser?.id ?? residentId ?? 0,
        residentName: currentUser?.name ?? residentName ?? '',
        currentUser: currentUser,
        repository: repository,
      ),
    );
  }

  static Route<void> driverPage({
    LaundryRepository? repository,
    int? userId,
    User? currentUser,
  }) => MaterialPageRoute<void>(
    settings: const RouteSettings(name: driver),
    builder: (_) => Scaffold(
      appBar: AppBar(title: const Text('Livraison du linge')),
      body: DriverLaundryPage(
        repository: repository,
        userId: currentUser?.id ?? userId,
        currentUser: currentUser,
      ),
    ),
  );

  static Route<void> pressingPage({
    LaundryRepository? repository,
    int? userId,
    User? currentUser,
  }) {
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: pressing),
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Société de pressing')),
        body: PressingLaundryPage(
          repository: repository,
          userId: currentUser?.id ?? userId,
          currentUser: currentUser,
        ),
      ),
    );
  }

  static Route<void> adminPage({
    LaundryRepository? repository,
    User? currentUser,
  }) {
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: admin),
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Gestion du linge')),
        body: LaundryPage(
          repository: repository,
          currentUser: currentUser,
          showAppBar: false,
        ),
      ),
    );
  }
}
