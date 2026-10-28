import 'package:flutter/material.dart';

import '../../../../core/localization/app_locale.dart';

/// Feature translations for repository errors, without editing the shared catalog.
String laundryMessage(BuildContext context, String source) {
  final translation = switch (source) {
    'Vérifiez le tarif et la durée.' => (
      'Check the tariff and duration.',
      'تحقق من التعريفة والمدة.',
    ),
    'Service indisponible.' => ('Service unavailable.', 'الخدمة غير متاحة.'),
    'Ce tarif vient d’être enregistré. Réessayez.' => (
      'This tariff was just saved. Try again.',
      'تم حفظ هذه التعريفة للتو. أعد المحاولة.',
    ),
    'Ajoutez entre 1 et 100 lots distincts.' => (
      'Add between 1 and 100 distinct lots.',
      'أضف بين مجموعة واحدة و100 مجموعة مختلفة.',
    ),
    'Vérifiez les articles, les quantités et les poids.' => (
      'Check the garments, quantities and weights.',
      'تحقق من الملابس والكميات والأوزان.',
    ),
    'Montant trop élevé.' => ('Amount is too large.', 'المبلغ كبير جدًا.'),
    'La demande a changé. Actualisez avant de modifier.' => (
      'The request changed. Refresh before editing.',
      'تغيّر الطلب. حدّثه قبل التعديل.',
    ),
    'La demande a changé. Actualisez.' => (
      'The request changed. Refresh it.',
      'تغيّر الطلب. حدّثه.',
    ),
    'Opération non autorisée.' => (
      'Operation not authorized.',
      'العملية غير مسموح بها.',
    ),
    'L’échéance doit suivre la création de la demande.' => (
      'The deadline must be after request creation.',
      'يجب أن يكون الموعد بعد إنشاء الطلب.',
    ),
    'Les articles pris en charge ne peuvent plus être modifiés.' => (
      'Articles already in treatment cannot be edited.',
      'لا يمكن تعديل الملابس بعد بدء المعالجة.',
    ),
    'Modifiez les articles avec le formulaire détaillé.' => (
      'Use the detailed form to edit articles.',
      'استخدم النموذج المفصل لتعديل الملابس.',
    ),
    _ => null,
  };
  return translation == null
      ? context.localize(source)
      : context.tr(fr: source, en: translation.$1, ar: translation.$2);
}
