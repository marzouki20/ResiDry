import 'package:flutter/material.dart';

import 'app_locale.dart';

/// Displays catalog-backed UI labels, including legacy database status labels.
/// Keep personal names and other user-authored content in ordinary Text widgets.
class LocalizedText extends StatelessWidget {
  const LocalizedText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) => Text(
        context.localize(data),
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
}
