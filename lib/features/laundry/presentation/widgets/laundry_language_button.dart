import 'package:flutter/material.dart';

import '../../../../core/localization/app_locale.dart';
import '../../../../core/localization/language_picker_button.dart';
import '../../../../core/theme/app_theme.dart';

/// Reuses the team's picker and controller; never creates a second locale.
class LaundryLanguageButton extends StatelessWidget {
  const LaundryLanguageButton({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) {
    // A host without the shared scope may still render a fixed-locale preview.
    if (context.dependOnInheritedWidgetOfExactType<AppLocaleScope>() == null) {
      return const SizedBox.shrink();
    }
    if (compact) return const LanguagePickerButton();
    final code = Localizations.localeOf(context).languageCode;
    final language = switch (code) {
      'fr' => 'Français',
      'ar' => 'العربية',
      _ => 'English',
    };
    return Tooltip(
      message: context.tr(
        fr: 'Changer de langue',
        en: 'Change language',
        ar: 'تغيير اللغة',
      ),
      child: OutlinedButton.icon(
        onPressed: () => showAppLanguagePicker(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          backgroundColor: Colors.white,
          side: BorderSide(color: AppColors.cyan.withValues(alpha: .35)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.language_rounded, size: 19),
        label: Text(language),
      ),
    );
  }
}
