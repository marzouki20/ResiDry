import 'package:flutter/material.dart';

import '../../../core/localization/app_locale.dart';
import '../../../core/theme/app_theme.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('assets/logo.png', height: 180),
                  const SizedBox(height: 24),
                  const Text(
                    'Choose your language\nChoisissez votre langue\nاختر لغتك',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 26,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'You can change this later from the sign-in screen.\n'
                    'Vous pourrez modifier ce choix depuis la connexion.\n'
                    'يمكنك تغيير اللغة لاحقًا من شاشة تسجيل الدخول.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, height: 1.45),
                  ),
                  const SizedBox(height: 30),
                  _LanguageButton(
                    label: 'Français',
                    subtitle: 'Continuer en français',
                    code: 'FR',
                    onPressed: () =>
                        AppLocaleScope.of(context).select(const Locale('fr')),
                  ),
                  const SizedBox(height: 12),
                  _LanguageButton(
                    label: 'English',
                    subtitle: 'Continue in English',
                    code: 'EN',
                    onPressed: () =>
                        AppLocaleScope.of(context).select(const Locale('en')),
                  ),
                  const SizedBox(height: 12),
                  _LanguageButton(
                    label: 'العربية',
                    subtitle: 'المتابعة باللغة العربية',
                    code: 'AR',
                    onPressed: () =>
                        AppLocaleScope.of(context).select(const Locale('ar')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton({
    required this.label,
    required this.subtitle,
    required this.code,
    required this.onPressed,
  });

  final String label;
  final String subtitle;
  final String code;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(18),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navy,
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.cyan.withValues(alpha: 0.16),
            child: Text(
              code,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded),
        ],
      ),
    );
  }
}
