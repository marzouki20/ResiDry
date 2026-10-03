import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../auth_page.dart';

class AuthFooter extends StatelessWidget {
  const AuthFooter({
    super.key,
    required this.page,
    required this.onSignIn,
    required this.onSignUp,
  });

  final AuthPage page;
  final VoidCallback onSignIn;
  final VoidCallback onSignUp;

  @override
  Widget build(BuildContext context) {
    if (page == AuthPage.forgotPassword) {
      return const Center(
        child: Text(
          'Your account, your orbit.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      );
    }
    final isSignIn = page == AuthPage.signIn;
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            isSignIn ? 'New to Orbit? ' : 'Already have an account? ',
            style: const TextStyle(color: AppColors.muted, fontSize: 14),
          ),
          TextButton(
            onPressed: isSignIn ? onSignUp : onSignIn,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.purple,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            child: Text(isSignIn ? 'Create account' : 'Sign in'),
          ),
        ],
      ),
    );
  }
}
