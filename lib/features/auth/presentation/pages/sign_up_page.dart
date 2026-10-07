import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../widgets/auth_buttons.dart';
import '../widgets/auth_divider.dart';
import '../widgets/auth_heading.dart';
import '../widgets/auth_text_field.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({
    super.key,
    required this.passwordVisible,
    required this.acceptedTerms,
    required this.onTogglePassword,
    required this.onToggleTerms,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.onSignUp,
    required this.isSubmitting,
  });

  final bool passwordVisible;
  final bool acceptedTerms;
  final VoidCallback onTogglePassword;
  final ValueChanged<bool?> onToggleTerms;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onSignUp;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthHeading(
          title: 'Create your account',
          subtitle: 'Start your journey with ResiDry today.',
        ),
        const SizedBox(height: 27),
        AuthTextField(
          label: 'Full name',
          hint: 'How should we call you?',
          icon: Icons.person_outline_rounded,
          textCapitalization: TextCapitalization.words,
          controller: nameController,
        ),
        const SizedBox(height: 15),
        AuthTextField(
          label: 'Email address',
          hint: 'you@example.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          controller: emailController,
        ),
        const SizedBox(height: 15),
        AuthTextField(
          label: 'Password',
          hint: 'Create a password',
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
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: selectedRole,
          decoration: InputDecoration(
            labelText: 'Role',
            prefixIcon: const Icon(Icons.badge_outlined),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.line),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'Résident', child: Text('Résident')),
            DropdownMenuItem(value: 'Livreur', child: Text('Livreur')),
            DropdownMenuItem(
              value: 'Société de lavage',
              child: Text('Société de lavage'),
            ),
            DropdownMenuItem(
              value: 'Administrateur',
              child: Text('Administrateur'),
            ),
          ],
          onChanged: (role) {
            if (role != null) onRoleChanged(role);
          },
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: acceptedTerms,
                onChanged: onToggleTerms,
                activeColor: AppColors.cyan,
                side: const BorderSide(color: AppColors.line),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const SizedBox(width: 9),
            const Expanded(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Terms of Service',
                      style: TextStyle(
                        color: AppColors.purple,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        color: AppColors.purple,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        PrimaryAuthButton(
          label: isSubmitting ? 'Creating account...' : 'Create account',
          onPressed: isSubmitting ? null : onSignUp,
        ),
        const SizedBox(height: 20),
        const AuthDivider(),
        const SizedBox(height: 18),
        const GoogleAuthButton(),
      ],
    );
  }
}
