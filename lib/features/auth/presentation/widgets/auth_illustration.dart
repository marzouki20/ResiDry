import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class AuthIllustration extends StatelessWidget {
  const AuthIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(52),
            ),
          ),
          Image.asset(
            'assets/logo.png',
            width: 180,
            height: 180,
            fit: BoxFit.contain,
          ),
          const Positioned(
            top: 12,
            right: 105,
            child: Icon(Icons.auto_awesome, size: 20, color: AppColors.cyan),
          ),
          const Positioned(
            bottom: 20,
            left: 105,
            child: Icon(Icons.circle, size: 10, color: AppColors.coral),
          ),
          const Positioned(
            top: 38,
            right: 70,
            child: Icon(Icons.circle, size: 7, color: AppColors.navy),
          ),
        ],
      ),
    );
  }
}
