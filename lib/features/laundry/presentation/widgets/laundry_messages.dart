import 'package:flutter/material.dart';

import '../../../../core/localization/app_locale.dart';

/// Feature translations for repository errors, without editing the shared catalog.
String laundryMessage(BuildContext context, String source) {
  final translation = switch (source) {
    'Identifiant de lot déjà utilisé ou invalide.' => (
      'Lot identifier already used or invalid.',
      'معرّف المجموعة مستخدم أو غير صالح.',
    ),
    'Photo inaccessible. Vérifiez les autorisations et réessayez.' => (
      'Photo unavailable. Check permissions and try again.',
      'الصورة غير متاحة. تحقق من الأذونات وأعد المحاولة.',
    ),
    'Cette demande doit être conservée : une réclamation y est liée.' => (
      'This request must be kept: it has a complaint.',
      'يجب الاحتفاظ بهذا الطلب لارتباطه بشكوى.',
    ),
    'Réclamation introuvable.' => (
      'Complaint not found.',
      'لم يتم العثور على الشكوى.',
    ),
    'Cette réclamation ne vous appartient pas.' => (
      'This complaint does not belong to you.',
      'هذه الشكوى لا تخصك.',
    ),
    'Décrivez le problème en 10 à 2000 caractères.' => (
      'Describe the issue in 10 to 2000 characters.',
      'صف المشكلة باستخدام 10 إلى 2000 حرف.',
    ),
    'Une réclamation pour ce motif est déjà en cours.' => (
      'A complaint for this reason is already open.',
      'توجد شكوى مفتوحة لهذا السبب.',
    ),
    'Sélectionnez un lot de cette demande.' => (
      'Select a lot from this request.',
      'اختر مجموعة من هذا الطلب.',
    ),
    'Aucun retard de traitement vérifiable pour cette demande.' => (
      'No verifiable treatment delay for this request.',
      'لا يوجد تأخر معالجة قابل للتحقق لهذا الطلب.',
    ),
    'Photos invalides : 3 maximum, 2 Mo par photo (JPEG, PNG ou WebP).' => (
      'Invalid photos: up to 3, 2 MB each (JPEG, PNG or WebP).',
      'صور غير صالحة: 3 كحد أقصى و2 ميغابايت لكل صورة (JPEG أو PNG أو WebP).',
    ),
    'La réclamation a changé. Actualisez.' => (
      'The complaint changed. Refresh it.',
      'تغيرت الشكوى. حدّثها.',
    ),
    'Transition de réclamation non autorisée.' => (
      'Complaint transition not allowed.',
      'تغيير حالة الشكوى غير مسموح.',
    ),
    'Motivez la décision en 10 à 2000 caractères.' => (
      'Explain the decision in 10 to 2000 characters.',
      'برر القرار باستخدام 10 إلى 2000 حرف.',
    ),
    'Réclamation non enregistrée. Réessayez.' => (
      'Complaint not saved. Try again.',
      'لم يتم حفظ الشكوى. أعد المحاولة.',
    ),
    'Vérifiez la température indiquée sur l’étiquette.' => (
      'Check the temperature on the care label.',
      'تحقق من الحرارة المحددة على ملصق العناية.',
    ),
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
