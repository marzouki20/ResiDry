import 'package:flutter/material.dart';

import '../../../../core/localization/app_locale.dart';
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
        AuthHeading(
          title: context.tr(
            en: 'Forgot password?',
            fr: 'Mot de passe oublié ?',
            ar: 'هل نسيت كلمة المرور؟',
          ),
          subtitle: context.tr(
            en: 'No worries. Enter your email and we’ll send you a reset link.',
            fr: 'Saisissez votre e-mail pour recevoir un lien de réinitialisation.',
            ar: 'أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة التعيين.',
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
        ),
        const SizedBox(height: 24),
        PrimaryAuthButton(
          label: context.tr(
            en: 'Send reset link',
            fr: 'Envoyer le lien',
            ar: 'إرسال رابط إعادة التعيين',
          ),
        ),
        const SizedBox(height: 18),
        TextButton.icon(
          onPressed: onBackToSignIn,
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: Text(
            context.tr(
                en: 'Back to sign in',
                fr: 'Retour à la connexion',
                ar: 'العودة إلى تسجيل الدخول'),
          ),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.navy,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
