import 'package:flutter/material.dart';

import '../../../../models/laundry_role.dart';
import '../../../../models/user.dart';
import '../../data/repositories/laundry_repository.dart';
import 'pressing_laundry_page.dart';

/// Delivery has its own destination and never builds administrator controls.
class DriverLaundryPage extends StatelessWidget {
  const DriverLaundryPage({
    super.key,
    this.repository,
    this.userId,
    this.currentUser,
    this.driverName,
  });

  final LaundryRepository? repository;
  final int? userId;
  final User? currentUser;
  final String? driverName;

  @override
  Widget build(BuildContext context) => LaundryWorkflowView(
    repository: (repository ?? LaundryRepository()).forUser(currentUser),
    role: LaundryRole.driver,
    userId: currentUser?.id ?? userId,
  );
}
