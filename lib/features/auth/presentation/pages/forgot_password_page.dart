import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../widgets/auth_buttons.dart';
import '../widgets/auth_heading.dart';
import '../widgets/auth_text_field.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key, required this.onBackToSignIn});

  final VoidCallback onBackToSignIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthHeading(
          title: 'Forgot password?',
          subtitle:
              'No worries. Enter your email and we’ll send you a reset link.',
        ),
        const SizedBox(height: 27),
        const AuthTextField(
          label: 'Email address',
          hint: 'you@example.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),
        const PrimaryAuthButton(label: 'Send reset link'),
        const SizedBox(height: 18),
        TextButton.icon(
          onPressed: onBackToSignIn,
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('Back to sign in'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.navy,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
