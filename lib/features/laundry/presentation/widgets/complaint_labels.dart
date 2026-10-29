import 'package:flutter/material.dart';

import '../../../../core/localization/app_locale.dart';
import '../../domain/models/laundry_complaint.dart';
import '../../domain/services/complaint_service.dart';
import 'laundry_design.dart';

String complaintLabel(BuildContext context, Object value) {
  final (fr, en, ar) = switch (value) {
    ComplaintReason.damaged => (
      'Vêtement endommagé',
      'Damaged garment',
      'ملابس متضررة',
    ),
    ComplaintReason.missing => (
      'Vêtement manquant',
      'Missing garment',
      'ملابس مفقودة',
    ),
    ComplaintReason.poorCleaning => (
      'Nettoyage insatisfaisant',
      'Unsatisfactory cleaning',
      'تنظيف غير مرضٍ',
    ),
    ComplaintReason.treatmentDelay => (
      'Retard de traitement',
      'Treatment delay',
      'تأخر المعالجة',
    ),
    ComplaintReason.other => ('Autre problème', 'Other issue', 'مشكلة أخرى'),
    ComplaintStatus.submitted => ('Envoyée', 'Submitted', 'مرسلة'),
    ComplaintStatus.reviewing => (
      'En cours d’examen',
      'Under review',
      'قيد المراجعة',
    ),
    ComplaintStatus.resolved => ('Résolue', 'Resolved', 'تم الحل'),
    ComplaintStatus.rejected => ('Refusée', 'Rejected', 'مرفوضة'),
    _ => throw ArgumentError('Unsupported complaint label'),
  };
  return context.tr(fr: fr, en: en, ar: ar);
}

Color complaintColor(ComplaintStatus status) => switch (status) {
  ComplaintStatus.submitted => LaundryPalette.sky,
  ComplaintStatus.reviewing => LaundryPalette.lilac,
  ComplaintStatus.resolved => LaundryPalette.mint,
  ComplaintStatus.rejected => LaundryPalette.peach,
};

String? complaintTextError(BuildContext context, String? text) =>
    text == null || !const ComplaintService().validText(text)
    ? context.tr(
        fr: 'Entre 10 et 2000 caractères sont nécessaires.',
        en: 'Enter between 10 and 2000 characters.',
        ar: 'أدخل بين 10 و2000 حرف.',
      )
    : null;
