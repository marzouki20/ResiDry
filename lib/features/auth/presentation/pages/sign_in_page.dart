import 'package:flutter/material.dart';

import '../widgets/auth_buttons.dart';
import '../widgets/auth_divider.dart';
import '../widgets/auth_heading.dart';
import '../widgets/auth_text_field.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({
    super.key,
    required this.passwordVisible,
    required this.onTogglePassword,
    required this.onForgotPassword,
  });

  final bool passwordVisible;
  final VoidCallback onTogglePassword;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthHeading(
          title: 'Welcome back',
          subtitle: 'Good to see you again. Let’s get you signed in.',
        ),
        const SizedBox(height: 27),
        const AuthTextField(
          label: 'Email address',
          hint: 'you@example.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 17),
        AuthTextField(
          label: 'Password',
          hint: 'Enter your password',
          icon: Icons.lock_outline_rounded,
          obscureText: !passwordVisible,
          suffix: IconButton(
            tooltip: passwordVisible ? 'Hide password' : 'Show password',
            onPressed: onTogglePassword,
            icon: Icon(
              passwordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: const Color(0xFF858493),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onForgotPassword,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF7457E8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            child: const Text('Forgot password?'),
          ),
        ),
        const SizedBox(height: 9),
        const PrimaryAuthButton(label: 'Sign in'),
        const SizedBox(height: 22),
        const AuthDivider(),
        const SizedBox(height: 20),
        const GoogleAuthButton(),
      ],
    );
  }
}
