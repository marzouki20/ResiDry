import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class AuthIllustration extends StatelessWidget {
  const AuthIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 126,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 126,
            height: 126,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE8FF),
              borderRadius: BorderRadius.circular(40),
            ),
          ),
          Container(
            width: 91,
            height: 91,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF9A82FA), AppColors.purple],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(
              Icons.waving_hand_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
          const Positioned(
            top: 13,
            right: 91,
            child: Icon(Icons.auto_awesome, size: 20, color: AppColors.purple),
          ),
          const Positioned(
            bottom: 16,
            left: 91,
            child: Icon(Icons.circle, size: 10, color: Color(0xFFF5B77C)),
          ),
          const Positioned(
            top: 30,
            right: 65,
            child: Icon(Icons.circle, size: 7, color: Color(0xFFB8A8FF)),
          ),
        ],
      ),
    );
  }
}
