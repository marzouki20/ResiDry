import 'package:flutter/material.dart';

import '../../../../core/localization/app_locale.dart';
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
      return Center(
        child: Text(
          context.tr(
            en: 'Your account, your orbit.',
            fr: 'Votre compte, votre univers.',
            ar: 'حسابك، عالمك.',
          ),
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
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
            isSignIn
                ? context.tr(
                    en: 'New to ResiDry? ',
                    fr: 'Nouveau sur ResiDry ? ',
                    ar: 'جديد في ResiDry؟ ')
                : context.tr(
                    en: 'Already have an account? ',
                    fr: 'Vous avez déjà un compte ? ',
                    ar: 'لديك حساب بالفعل؟ ',
                  ),
            style: const TextStyle(color: AppColors.muted, fontSize: 14),
          ),
          TextButton(
            onPressed: isSignIn ? onSignUp : onSignIn,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.purple,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            child: Text(
              isSignIn
                  ? context.tr(
                      en: 'Create account',
                      fr: 'Créer un compte',
                      ar: 'إنشاء حساب')
                  : context.tr(
                      en: 'Sign in', fr: 'Se connecter', ar: 'تسجيل الدخول'),
            ),
          ),
        ],
      ),
    );
  }
}
