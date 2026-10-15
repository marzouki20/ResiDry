import 'package:flutter/material.dart';
import '../localization/app_locale.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, required this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: context.tr(en: 'Back', fr: 'Retour', ar: 'رجوع'),
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_back_rounded),
      );
}
