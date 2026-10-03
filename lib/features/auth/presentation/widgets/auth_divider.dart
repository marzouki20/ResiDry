import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.line)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or continue with',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ),
        Expanded(child: Divider(color: AppColors.line)),
      ],
    );
  }
}
