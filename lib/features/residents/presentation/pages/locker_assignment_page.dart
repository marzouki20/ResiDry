import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../mock/residents_mock_data.dart';
import '../widgets/locker_card.dart';

class LockerAssignmentPage extends StatelessWidget {
  const LockerAssignmentPage({super.key, required this.assignment});

  final LockerAssignment assignment;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        LockerCard(
          number: assignment.number,
          location: assignment.location,
          status: assignment.status,
          assignmentDate: assignment.assignmentDate,
          accessCode: assignment.accessCode,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.navy),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Keep your access code private and use it only when collecting your laundry.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
