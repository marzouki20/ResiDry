import 'package:flutter/material.dart';

import '../../../../core/localization/app_locale.dart';
import '../../domain/models/laundry_sorting.dart';

String sortingLabel(BuildContext context, Object value) {
  final (fr, en, ar) = switch (value) {
    LaundryColorFamily.white => ('Blancs', 'Whites', 'أبيض'),
    LaundryColorFamily.light => (
      'Couleurs claires',
      'Light colours',
      'ألوان فاتحة',
    ),
    LaundryColorFamily.dark => (
      'Couleurs foncées',
      'Dark colours',
      'ألوان داكنة',
    ),
    LaundryFabric.cotton => ('Coton', 'Cotton', 'قطن'),
    LaundryFabric.linen => ('Lin', 'Linen', 'كتان'),
    LaundryFabric.synthetic => ('Synthétique', 'Synthetic', 'ألياف صناعية'),
    LaundryFabric.wool => ('Laine', 'Wool', 'صوف'),
    LaundryFabric.silk => ('Soie', 'Silk', 'حرير'),
    LaundryFabric.blend => ('Mélange de fibres', 'Fibre blend', 'خليط ألياف'),
    LaundryFabric.other => ('Autre tissu', 'Other fabric', 'نسيج آخر'),
    LaundryWashCycle.normal => ('Normal', 'Normal', 'عادي'),
    LaundryWashCycle.delicate => ('Délicat', 'Delicate', 'لطيف'),
    LaundryWashCycle.handWash => ('Lavage à la main', 'Hand wash', 'غسيل يدوي'),
    LaundryWashCycle.doNotWash => (
      'Lavage interdit',
      'Do not wash',
      'الغسيل ممنوع',
    ),
    LaundryDyeTransferRisk.unknown => (
      'À vérifier',
      'To check',
      'يحتاج إلى تحقق',
    ),
    LaundryDyeTransferRisk.low => (
      'Faible selon vérification',
      'Low after checking',
      'منخفض بعد التحقق',
    ),
    LaundryDyeTransferRisk.high => (
      'Risque constaté',
      'Risk identified',
      'خطر مثبت',
    ),
    LaundrySortingReason.treatmentAlreadyStarted => (
      'Traitement déjà commencé',
      'Treatment already started',
      'بدأت المعالجة',
    ),
    LaundrySortingReason.notAWashingService => (
      'Service hors lavage : traitement distinct',
      'Non-washing service: separate treatment',
      'خدمة غير الغسيل: معالجة منفصلة',
    ),
    LaundrySortingReason.careNotVerified => (
      'Étiquette non vérifiée',
      'Care label not checked',
      'لم يتم التحقق من ملصق العناية',
    ),
    LaundrySortingReason.unknownColor => (
      'Couleur à préciser',
      'Colour needs checking',
      'يجب تحديد اللون',
    ),
    LaundrySortingReason.unknownFabric => (
      'Composition à vérifier',
      'Fibre composition needs checking',
      'يجب التحقق من تركيب النسيج',
    ),
    LaundrySortingReason.unknownCycle => (
      'Cycle à préciser',
      'Cycle needs checking',
      'يجب تحديد دورة الغسيل',
    ),
    LaundrySortingReason.unknownTemperature => (
      'Température à vérifier',
      'Temperature needs checking',
      'يجب التحقق من الحرارة',
    ),
    LaundrySortingReason.unknownDyeTransferRisk => (
      'Décoloration à vérifier',
      'Dye transfer needs checking',
      'يجب التحقق من انتقال اللون',
    ),
    LaundrySortingReason.unknownSeparationRequirement => (
      'Consigne de séparation inconnue',
      'Separate-wash requirement unknown',
      'تعليمات الفصل غير معروفة',
    ),
    LaundrySortingReason.specialInstructions => (
      'Instructions particulières : examen manuel',
      'Special instructions: manual review',
      'تعليمات خاصة: مراجعة يدوية',
    ),
    LaundrySortingReason.dyeTransferRisk => (
      'Risque de transfert de couleur : isoler',
      'Dye transfer risk: isolate',
      'خطر انتقال اللون: فصل المجموعة',
    ),
    LaundrySortingReason.separateWashRequired => (
      'Étiquette : laver séparément',
      'Label: wash separately',
      'الملصق: يغسل منفصلاً',
    ),
    LaundrySortingReason.handWashOnly => (
      'Lavage à la main : circuit distinct',
      'Hand wash: separate handling',
      'غسيل يدوي: مسار منفصل',
    ),
    LaundrySortingReason.washingProhibited => (
      'Ne pas mettre au lavage',
      'Do not put in a wash',
      'لا يوضع في الغسيل',
    ),
    _ => throw ArgumentError('Unsupported sorting label: $value'),
  };
  return context.tr(fr: fr, en: en, ar: ar);
}
