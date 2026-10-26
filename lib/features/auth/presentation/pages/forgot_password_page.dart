import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../widgets/auth_buttons.dart';
import '../widgets/auth_heading.dart';
import '../widgets/auth_text_field.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({
    super.key,
    required this.emailController,
    required this.isSubmitting,
    required this.onSendResetCode,
    required this.onBackToSignIn,
  });

  final TextEditingController emailController;
  final bool isSubmitting;
  final VoidCallback onSendResetCode;
  final VoidCallback onBackToSignIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthHeading(
          title: 'Forgot password?',
          subtitle: 'Enter your email and we’ll send you a reset code.',
        ),
        const SizedBox(height: 27),
        AuthTextField(
          label: 'Email address',
          hint: 'you@example.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          controller: emailController,
        ),
        const SizedBox(height: 24),
        PrimaryAuthButton(
          label: isSubmitting ? 'Sending code...' : 'Send reset code',
          onPressed: isSubmitting ? null : onSendResetCode,
        ),
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
