import 'package:flutter/material.dart';

import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_theme.dart';
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
    required this.emailController,
    required this.passwordController,
    required this.onSignIn,
    required this.isSubmitting,
  });

  final bool passwordVisible;
  final VoidCallback onTogglePassword;
  final VoidCallback onForgotPassword;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSignIn;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthHeading(
          title: context.tr(
              en: 'Welcome back', fr: 'Bienvenue', ar: 'مرحبًا بعودتك'),
          subtitle: context.tr(
            en: 'Good to see you again. Let’s get you signed in.',
            fr: 'Heureux de vous revoir. Connectez-vous à votre compte.',
            ar: 'سعداء برؤيتك مجددًا. سجّل الدخول إلى حسابك.',
          ),
        ),
        const SizedBox(height: 27),
        AuthTextField(
          label: context.tr(
              en: 'Email address',
              fr: 'Adresse e-mail',
              ar: 'البريد الإلكتروني'),
          hint: 'you@example.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          controller: emailController,
        ),
        const SizedBox(height: 17),
        AuthTextField(
          label:
              context.tr(en: 'Password', fr: 'Mot de passe', ar: 'كلمة المرور'),
          hint: context.tr(
            en: 'Enter your password',
            fr: 'Saisissez votre mot de passe',
            ar: 'أدخل كلمة المرور',
          ),
          icon: Icons.lock_outline_rounded,
          obscureText: !passwordVisible,
          controller: passwordController,
          suffix: IconButton(
            tooltip: passwordVisible
                ? context.tr(
                    en: 'Hide password',
                    fr: 'Masquer le mot de passe',
                    ar: 'إخفاء كلمة المرور')
                : context.tr(
                    en: 'Show password',
                    fr: 'Afficher le mot de passe',
                    ar: 'إظهار كلمة المرور'),
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
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onForgotPassword,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.navy,
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            child: Text(
              context.tr(
                  en: 'Forgot password?',
                  fr: 'Mot de passe oublié ?',
                  ar: 'هل نسيت كلمة المرور؟'),
            ),
          ),
        ),
        const SizedBox(height: 9),
        PrimaryAuthButton(
          label: isSubmitting
              ? context.tr(
                  en: 'Signing in...',
                  fr: 'Connexion...',
                  ar: 'جارٍ تسجيل الدخول...')
              : context.tr(
                  en: 'Sign in', fr: 'Se connecter', ar: 'تسجيل الدخول'),
          onPressed: isSubmitting ? null : onSignIn,
        ),
        const SizedBox(height: 22),
        const AuthDivider(),
        const SizedBox(height: 20),
        const GoogleAuthButton(),
      ],
    );
  }
}
