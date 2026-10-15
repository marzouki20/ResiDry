import 'package:flutter/material.dart';

import '../../../../models/laundry_role.dart';
import '../../data/repositories/laundry_repository.dart';
import 'pressing_laundry_page.dart';

/// Delivery has its own destination and never builds administrator controls.
class DriverLaundryPage extends StatelessWidget {
  const DriverLaundryPage({super.key, required this.repository, this.userId});
  final LaundryRepository repository;
  final int? userId;

  @override
  Widget build(BuildContext context) => LaundryWorkflowView(
    repository: repository,
    role: LaundryRole.driver,
    userId: userId,
  );
}
