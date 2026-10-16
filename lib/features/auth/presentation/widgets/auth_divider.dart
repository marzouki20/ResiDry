import 'package:flutter/material.dart';

import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_theme.dart';

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.line)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            context.tr(
                en: 'or continue with',
                fr: 'ou continuer avec',
                ar: 'أو المتابعة باستخدام'),
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.line)),
      ],
    );
  }
}
