import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../widgets/auth_buttons.dart';
import '../widgets/auth_heading.dart';
import '../widgets/auth_text_field.dart';

class VerifyEmailPage extends StatelessWidget {
  const VerifyEmailPage({
    super.key,
    required this.email,
    required this.codeController,
    required this.isSubmitting,
    required this.onVerify,
    required this.onResend,
  });

  final String email;
  final TextEditingController codeController;
  final bool isSubmitting;
  final VoidCallback onVerify;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthHeading(
          title: 'Verify your email',
          subtitle: 'Enter the 6-digit code we sent to your inbox.',
        ),
        const SizedBox(height: 12),
        Text(
          email,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 27),
        AuthTextField(
          label: 'Verification code',
          hint: '123456',
          icon: Icons.mark_email_read_outlined,
          keyboardType: TextInputType.number,
          controller: codeController,
        ),
        const SizedBox(height: 24),
        PrimaryAuthButton(
          label: isSubmitting ? 'Verifying...' : 'Verify email',
          onPressed: isSubmitting ? null : onVerify,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: isSubmitting ? null : onResend,
          child: const Text('Resend code'),
        ),
      ],
    );
  }
}
