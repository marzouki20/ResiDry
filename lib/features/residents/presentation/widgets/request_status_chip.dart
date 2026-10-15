import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class RequestStatusChip extends StatelessWidget {
  const RequestStatusChip({
    super.key,
    required this.status,
    this.compact = false,
  });

  final String status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'New':
      return AppColors.cyan;
    case 'Collection':
      return AppColors.navy;
    case 'Processing':
      return const Color(0xFF7B61FF);
    case 'Ready':
      return const Color(0xFF1EAA8B);
    case 'Delivered':
      return const Color(0xFF2BAA6C);
    case 'Active':
      return AppColors.cyan;
    default:
      return AppColors.navy;
  }
}
