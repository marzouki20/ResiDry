import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../widgets/auth_buttons.dart';
import '../widgets/auth_heading.dart';
import '../widgets/auth_text_field.dart';

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({
    super.key,
    required this.email,
    required this.codeController,
    required this.passwordController,
    required this.passwordVisible,
    required this.isSubmitting,
    required this.onTogglePassword,
    required this.onResetPassword,
    required this.onResendCode,
  });

  final String email;
  final TextEditingController codeController;
  final TextEditingController passwordController;
  final bool passwordVisible;
  final bool isSubmitting;
  final VoidCallback onTogglePassword;
  final VoidCallback onResetPassword;
  final VoidCallback onResendCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthHeading(
          title: 'Reset your password',
          subtitle:
              'Enter the code sent to your email and choose a new password.',
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
          label: 'Reset code',
          hint: '123456',
          icon: Icons.password_rounded,
          keyboardType: TextInputType.number,
          controller: codeController,
        ),
        const SizedBox(height: 15),
        AuthTextField(
          label: 'New password',
          hint: 'Create a new password',
          icon: Icons.lock_outline_rounded,
          obscureText: !passwordVisible,
          controller: passwordController,
          suffix: IconButton(
            tooltip: passwordVisible ? 'Hide password' : 'Show password',
            onPressed: onTogglePassword,
            icon: Icon(
              passwordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: AppColors.muted,
            ),
          ),
        ),
        const SizedBox(height: 24),
        PrimaryAuthButton(
          label: isSubmitting ? 'Updating password...' : 'Update password',
          onPressed: isSubmitting ? null : onResetPassword,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: isSubmitting ? null : onResendCode,
          child: const Text('Resend reset code'),
        ),
      ],
    );
  }
}
