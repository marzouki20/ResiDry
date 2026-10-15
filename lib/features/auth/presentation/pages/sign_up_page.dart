import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/app_locale.dart';
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
    required this.phoneController,
    required this.phoneError,
    required this.onPhoneChanged,
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
  final TextEditingController phoneController;
  final String? phoneError;
  final ValueChanged<String> onPhoneChanged;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback onSignUp;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthHeading(
          title: context.tr(
            en: 'Create your account',
            fr: 'Créer votre compte',
            ar: 'أنشئ حسابك',
          ),
          subtitle: context.tr(
            en: 'Start your journey with ResiDry today.',
            fr: 'Commencez votre expérience ResiDry dès aujourd’hui.',
            ar: 'ابدأ رحلتك مع ResiDry اليوم.',
          ),
        ),
        const SizedBox(height: 27),
        AuthTextField(
          label: context.tr(
              en: 'Full name', fr: 'Nom complet', ar: 'الاسم الكامل'),
          hint: context.tr(
            en: 'How should we call you?',
            fr: 'Comment devons-nous vous appeler ?',
            ar: 'بماذا نناديك؟',
          ),
          icon: Icons.person_outline_rounded,
          textCapitalization: TextCapitalization.words,
          controller: nameController,
        ),
        const SizedBox(height: 15),
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
        const SizedBox(height: 15),
        AuthTextField(
          label:
              context.tr(en: 'Password', fr: 'Mot de passe', ar: 'كلمة المرور'),
          hint: context.tr(
            en: 'Create a password',
            fr: 'Créez un mot de passe',
            ar: 'أنشئ كلمة مرور',
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
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: selectedRole,
          decoration: InputDecoration(
            labelText: context.tr(en: 'Role', fr: 'Rôle', ar: 'الدور'),
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
          items: [
            DropdownMenuItem(
              value: 'Résident',
              child:
                  Text(context.tr(en: 'Resident', fr: 'Résident', ar: 'مقيم')),
            ),
            DropdownMenuItem(
              value: 'Livreur',
              child: Text(
                  context.tr(en: 'Driver', fr: 'Livreur', ar: 'عامل التوصيل')),
            ),
            DropdownMenuItem(
              value: 'Société de lavage',
              child: Text(
                context.tr(
                    en: 'Laundry company',
                    fr: 'Société de lavage',
                    ar: 'شركة غسيل'),
              ),
            ),
            DropdownMenuItem(
              value: 'Administrateur',
              child: Text(context.tr(
                  en: 'Administrator', fr: 'Administrateur', ar: 'مسؤول')),
            ),
          ],
          onChanged: (role) {
            if (role != null) onRoleChanged(role);
          },
        ),
        const SizedBox(height: 12),
        if (selectedRole == 'Livreur') ...[
          Text(
              context.tr(
                  en: 'Phone number — required',
                  fr: 'Téléphone — obligatoire',
                  ar: 'رقم الهاتف — إلزامي'),
              style: const TextStyle(
                  color: AppColors.navy, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Directionality(
              textDirection: TextDirection.ltr,
              child: TextField(
                key: const ValueKey('driver-phone-field'),
                controller: phoneController,
                enabled: !isSubmitting,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumberNational],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8)
                ],
                onChanged: onPhoneChanged,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.phone_outlined),
                  prefixText: '+216 ',
                  hintText: '55 123 456',
                  errorText: phoneError,
                  helperText: context.tr(
                      en: '8 digits starting with 2, 3, 4, 5, 7 or 9; omit +216.',
                      fr: '8 chiffres commençant par 2, 3, 4, 5, 7 ou 9 ; sans +216.',
                      ar: '8 أرقام تبدأ بـ 2 أو 3 أو 4 أو 5 أو 7 أو 9، دون +216.'),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              )),
          const SizedBox(height: 12),
        ],
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
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(
                      text: context.tr(
                        en: 'I agree to the ',
                        fr: 'J’accepte les ',
                        ar: 'أوافق على ',
                      ),
                    ),
                    TextSpan(
                      text: context.tr(
                        en: 'Terms of Service',
                        fr: 'Conditions d’utilisation',
                        ar: 'شروط الاستخدام',
                      ),
                      style: const TextStyle(
                        color: AppColors.purple,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                        text: context.tr(en: ' and ', fr: ' et la ', ar: ' و')),
                    TextSpan(
                      text: context.tr(
                        en: 'Privacy Policy',
                        fr: 'Politique de confidentialité',
                        ar: 'سياسة الخصوصية',
                      ),
                      style: const TextStyle(
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
          label: isSubmitting
              ? context.tr(
                  en: 'Creating account...',
                  fr: 'Création du compte...',
                  ar: 'جارٍ إنشاء الحساب...')
              : context.tr(
                  en: 'Create account',
                  fr: 'Créer un compte',
                  ar: 'إنشاء حساب'),
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
