import 'package:flutter/material.dart';

import 'app_locale.dart';

class LanguagePickerButton extends StatelessWidget {
  const LanguagePickerButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: context.tr(
        en: 'Change language',
        fr: 'Changer de langue',
        ar: 'تغيير اللغة',
      ),
      onPressed: () => showAppLanguagePicker(context),
      icon: const Icon(Icons.language_rounded),
    );
  }
}

Future<void> showAppLanguagePicker(BuildContext context) async {
  final selectedLanguage = Localizations.localeOf(context).languageCode;
  final locale = await showModalBottomSheet<Locale>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr(en: 'Language', fr: 'Langue', ar: 'اللغة'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _LanguageTile(
              code: 'FR',
              label: 'Français',
              locale: const Locale('fr'),
              selected: selectedLanguage == 'fr',
            ),
            _LanguageTile(
              code: 'EN',
              label: 'English',
              locale: const Locale('en'),
              selected: selectedLanguage == 'en',
            ),
            _LanguageTile(
              code: 'AR',
              label: 'العربية',
              locale: const Locale('ar'),
              selected: selectedLanguage == 'ar',
            ),
          ],
        ),
      ),
    ),
  );

  if (locale != null && context.mounted) {
    await AppLocaleScope.of(context).select(locale);
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.code,
    required this.label,
    required this.locale,
    required this.selected,
  });

  final String code;
  final String label;
  final Locale locale;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text(code)),
      title: Text(label),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded)
          : const Icon(Icons.chevron_right_rounded),
      onTap: () => Navigator.pop(context, locale),
    );
  }
}
