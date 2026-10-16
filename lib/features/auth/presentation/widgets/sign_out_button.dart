import 'package:flutter/material.dart';

import '../../../../core/localization/app_locale.dart';
import '../auth_screen.dart';
import '../../../../core/backend/backend_client.dart';

Future<void> confirmSignOut(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
          context.tr(en: 'Sign out', fr: 'Déconnexion', ar: 'تسجيل الخروج')),
      content: Text(context.tr(
        en: 'Do you want to sign out of your account?',
        fr: 'Voulez-vous vous déconnecter de votre compte ?',
        ar: 'هل تريد تسجيل الخروج من حسابك؟',
      )),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(context.tr(en: 'Cancel', fr: 'Annuler', ar: 'إلغاء')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(context.tr(
              en: 'Sign out', fr: 'Se déconnecter', ar: 'تسجيل الخروج')),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  if (BackendClient.enabled) {
    try {
      await BackendClient.logout();
    } catch (_) {/* Session is cleared locally. */}
    if (!context.mounted) return;
  }
  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
    (_) => false,
  );
}

class SignOutButton extends StatelessWidget {
  const SignOutButton({super.key});

  @override
  Widget build(BuildContext context) => TextButton.icon(
        onPressed: () => confirmSignOut(context),
        icon: const Icon(Icons.logout_rounded),
        label: Text(context.tr(
            en: 'Sign out', fr: 'Se déconnecter', ar: 'تسجيل الخروج')),
        style: TextButton.styleFrom(foregroundColor: Colors.red),
      );
}
