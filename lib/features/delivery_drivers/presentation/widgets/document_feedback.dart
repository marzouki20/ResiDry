import 'package:flutter/material.dart';
import '../../../../core/localization/app_locale.dart';

class DocumentIssue {
  const DocumentIssue(this.code, this.slots, [this.details = const {}]);
  final String code;
  final List<String> slots;
  final Map<String, dynamic> details;
}

String documentIssueMessage(BuildContext context, DocumentIssue issue) {
  String dateLabel(dynamic value) {
    if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return '—';
    }
    final date = DateTime.tryParse(value);
    if (date == null || date.toIso8601String().substring(0, 10) != value) {
      return '—';
    }
    return '${value.substring(8, 10)}/${value.substring(5, 7)}/${value.substring(0, 4)}';
  }

  if (issue.code == 'document_expired') {
    final date = dateLabel(issue.details['expires_on']);
    return context.tr(
        en: 'Expired document: the expiry date read is $date. Add an up-to-date document.',
        fr: 'Document expiré : la date de fin lue est le $date. Ajoutez un document à jour.',
        ar: 'الوثيقة منتهية الصلاحية: تاريخ الانتهاء المقروء هو $date. أضف وثيقة سارية.');
  }
  if (issue.code == 'not_yet_valid') {
    final date = dateLabel(issue.details['starts_on']);
    return context.tr(
        en: 'This document is not yet valid. The start date read is $date. Add proof valid today.',
        fr: 'Ce document n’est pas encore valable. La date de début lue est le $date. Ajoutez un justificatif valable aujourd’hui.',
        ar: 'هذه الوثيقة لم تبدأ صلاحيتها بعد. تاريخ البداية المقروء هو $date. أضف إثباتاً سارياً اليوم.');
  }
  if (issue.code == 'date_unreadable') {
    return context.tr(
        en: 'The validity dates could not be read. Retake this photo with the dates clearly visible.',
        fr: 'Les dates de validité n’ont pas pu être lues. Reprenez cette photo avec les dates bien visibles.',
        ar: 'تعذر قراءة تواريخ الصلاحية. أعد التقاط الصورة مع ظهور التواريخ بوضوح.');
  }
  if (issue.code == 'category_dates_unclear') {
    return context.tr(
        en: 'The dates for the required licence category are unclear. Retake the licence back.',
        fr: 'Les dates de la catégorie du permis ne sont pas claires. Reprenez le verso du permis.',
        ar: 'تواريخ فئة الرخصة غير واضحة. أعد تصوير الوجه الخلفي للرخصة.');
  }
  if (issue.code == 'wrong_document_type') {
    const kinds = <String, List<String>>{
      'TECHNICAL_INSPECTION': [
        'technical-inspection certificate',
        'certificat de visite technique',
        'شهادة فحص فني'
      ],
      'DRIVING_LICENSE': [
        'driving licence',
        'permis de conduire',
        'رخصة قيادة'
      ],
      'REGISTRATION': [
        'registration certificate',
        'certificat d’immatriculation',
        'بطاقة تسجيل'
      ],
      'INSURANCE': [
        'insurance document',
        'document d’assurance',
        'وثيقة تأمين'
      ],
      'AUTHORIZATION': [
        'vehicle-use authorization',
        'autorisation d’utilisation',
        'ترخيص استعمال المركبة'
      ],
    };
    final name = kinds[issue.details['detected_kind']];
    if (name != null) {
      return context.tr(
          en: 'This photo shows a ${name[0]}, instead of the requested document. Replace it with the correct document.',
          fr: 'Cette photo montre un ${name[1]}, au lieu du document demandé. Remplacez-la par le bon document.',
          ar: 'تُظهر هذه الصورة ${name[2]} بدلاً من الوثيقة المطلوبة. استبدلها بالوثيقة الصحيحة.');
    }
  }
  if (issue.code == 'load_within_payload') {
    final payload = issue.details['payload_kg'];
    final declared = issue.details['declared_kg'];
    final reserve = issue.details['reserve_kg'];
    if (payload is num &&
        declared is num &&
        reserve is num &&
        payload.isFinite &&
        declared.isFinite &&
        reserve.isFinite &&
        declared + reserve > payload) {
      final total = declared + reserve;
      return context.tr(
          en: 'Requested load ($declared kg) + occupants/equipment ($reserve kg) = $total kg. Documented payload: $payload kg. Reduce the requested load or correct the entered weights.',
          fr: 'Capacité demandée ($declared kg) + occupants/équipements ($reserve kg) = $total kg. Charge utile du document : $payload kg. Réduisez la capacité demandée ou corrigez les poids saisis.',
          ar: 'الحمولة المطلوبة ($declared كغ) + الركاب والمعدات ($reserve كغ) = $total كغ. الحد الموثق: $payload كغ. خفّض الحمولة المطلوبة أو صحح الأوزان المدخلة.');
    }
  }
  return documentCorrection(context, issue.code);
}

/// Cross-document checks identify every relevant photo, without guessing which is wrong.
List<DocumentIssue> documentIssues(Map<String, dynamic>? report) {
  if (report == null || report['status'] == 'UNAVAILABLE') return [];
  final issues = <DocumentIssue>[];
  for (final doc in (report['documents'] as List? ?? [])) {
    if (doc['status'] == 'PASS') continue;
    for (final reason in (doc['reasons'] as List? ?? ['unreadable_photo'])) {
      issues.add(DocumentIssue(reason as String, [doc['slot'] as String],
          Map<String, dynamic>.from(doc['details'] as Map? ?? {})));
    }
  }
  const affected = <String, List<String>>{
    'tunisian_registration': ['FRONT', 'BACK'],
    'registration_sides_match': ['FRONT', 'BACK'],
    'vehicle_plate': ['FRONT'],
    'vehicle_brand': ['FRONT'],
    'vehicle_model': ['FRONT'],
    'registration_date': ['FRONT'],
    'tunisian_license': ['LICENSE_FRONT', 'LICENSE_BACK'],
    'license_sides_match': ['LICENSE_FRONT', 'LICENSE_BACK'],
    'driver_name_matches_license': ['LICENSE_FRONT'],
    'vehicle_type_matches': ['FRONT', 'BACK'],
    'license_validity': [
      'The licence identity or document is unclear. Add clear photos of both sides; no expiry date is required for this check.',
      'L’identité ou le permis est illisible. Ajoutez des photos nettes des deux faces ; aucune date d’expiration n’est requise pour ce contrôle.',
      'هوية صاحب الرخصة أو الوثيقة غير واضحة. أضف صوراً واضحة للوجهين؛ لا يشترط تاريخ انتهاء لهذا الفحص.'
    ],
    'license_category': ['LICENSE_BACK', 'BACK'],
    'payload_readable': ['BACK'],
    'weight_values_consistent': ['BACK'],
    'load_within_payload': ['BACK'],
    'inspection_validity': ['TECHNICAL_INSPECTION'],
    'tunisian_inspection': ['TECHNICAL_INSPECTION'],
    'inspection_center': ['TECHNICAL_INSPECTION'],
    'inspection_vehicle_matches': ['TECHNICAL_INSPECTION', 'FRONT'],
    'inspection_vin_matches': ['TECHNICAL_INSPECTION', 'FRONT'],
    'insurance_validity': ['INSURANCE'],
    'insurance_issuer': ['INSURANCE'],
    'insurance_vehicle_matches': ['INSURANCE', 'FRONT'],
    'insurance_vin_matches': ['INSURANCE', 'FRONT'],
    'delivery_insurance_coverage': ['INSURANCE'],
    'vehicle_use_authorization': ['AUTHORIZATION', 'FRONT', 'LICENSE_FRONT'],
    'registered_owner_matches': ['FRONT', 'LICENSE_FRONT'],
  };
  for (final check in (report['checks'] as List? ?? [])) {
    if (check['status'] == 'PASS') continue;
    final code = check['code'] as String;
    final details = Map<String, dynamic>.from(check['details'] as Map? ?? {});
    issues.add(DocumentIssue(
        details['reason'] is String &&
                [
                  'document_expired',
                  'date_unreadable',
                  'not_yet_valid',
                  'category_dates_unclear'
                ].contains(details['reason'])
            ? details['reason'] as String
            : code,
        affected[code] ?? [],
        details));
  }
  return issues;
}

String documentCorrection(BuildContext context, String code) {
  const messages = <String, List<String>>{
    'tunisian_inspection': [
      'Add a clear Tunisian technical-inspection certificate.',
      'Ajoutez une photo nette du certificat tunisien de visite technique.',
      'أضف صورة واضحة لشهادة الفحص الفني التونسية.'
    ],
    'inspection_validity': [
      'Check the inspection issue and expiry dates. Add a current certificate with readable dates.',
      'Vérifiez les dates de délivrance et de fin de validité. Ajoutez un certificat en cours avec des dates lisibles.',
      'تحقق من تاريخ التسليم وانتهاء الصلاحية. أضف شهادة سارية بتواريخ واضحة.'
    ],
    'inspection_vehicle_matches': [
      'The inspection certificate does not match the registration number. Check both documents and use the same vehicle.',
      'L’immatriculation de la visite technique ne correspond pas. Vérifiez les deux documents et utilisez ceux du même véhicule.',
      'رقم التسجيل في شهادة الفحص غير مطابق. تحقق من الوثيقتين واستخدم وثائق المركبة نفسها.'
    ],
    'inspection_vin_matches': [
      'The chassis numbers do not match. Check the inspection certificate and registration.',
      'Les numéros de châssis ne correspondent pas. Vérifiez la visite technique et l’immatriculation.',
      'أرقام الهيكل غير متطابقة. تحقق من شهادة الفحص وبطاقة التسجيل.'
    ],
    'inspection_center': [
      'The inspection centre or certificate information is unreadable. Retake the complete certificate.',
      'Le centre de contrôle ou les informations du certificat sont illisibles. Reprenez le certificat en entier.',
      'مركز الفحص أو معلومات الشهادة غير مقروءة. أعد تصوير الشهادة كاملة.'
    ],
    'wrong_document_type': [
      'Wrong document: replace this photo with the requested document.',
      'Mauvais document : remplacez cette photo par le document demandé.',
      'وثيقة غير صحيحة: استبدل هذه الصورة بالوثيقة المطلوبة.'
    ],
    'wrong_document_side': [
      'Wrong or uncertain side: photograph the requested front/back.',
      'Face incorrecte ou incertaine : photographiez le recto ou verso demandé.',
      'وجه غير صحيح أو غير مؤكد: صوّر الوجه المطلوب.'
    ],
    'unreadable_photo': [
      'Unreadable photo: retake it without blur or glare, with all edges visible.',
      'Photo illisible : reprenez-la sans flou ni reflet, avec tous les bords visibles.',
      'صورة غير مقروءة: أعد التقاطها دون ضبابية أو انعكاس مع ظهور كل الحواف.'
    ],
    'missing_or_ambiguous_photo': [
      'Missing or unidentified photo: add a clear photo in this field.',
      'Photo manquante ou non identifiée : ajoutez une photo nette dans ce champ.',
      'صورة مفقودة أو غير محددة: أضف صورة واضحة في هذا الحقل.'
    ],
    'duplicate_photo': [
      'Repeated photo: each field needs its own document and side.',
      'Photo répétée : chaque champ doit contenir son document et sa face distincte.',
      'صورة مكررة: يجب أن يحتوي كل حقل على الوثيقة والوجه الخاص به.'
    ],
    'registration_sides_match': [
      'Check both registration photos: they must belong to the same vehicle.',
      'Vérifiez les deux photos d’immatriculation : elles doivent correspondre au même véhicule.',
      'تحقق من صورتي التسجيل: يجب أن تخصا المركبة نفسها.'
    ],
    'license_sides_match': [
      'Check both licence photos: they must belong to the same person.',
      'Vérifiez les deux photos du permis : elles doivent appartenir à la même personne.',
      'تحقق من صورتي الرخصة: يجب أن تخصا الشخص نفسه.'
    ],
    'tunisian_registration': [
      'Use both sides of the Tunisian registration certificate.',
      'Utilisez les deux faces du certificat d’immatriculation tunisien.',
      'استخدم وجهي بطاقة التسجيل التونسية.'
    ],
    'tunisian_license': [
      'Use both sides of the Tunisian driving licence.',
      'Utilisez les deux faces du permis de conduire tunisien.',
      'استخدم وجهي رخصة القيادة التونسية.'
    ],
    'driver_name_matches_license': [
      'Check the account name and licence holder name; they could not be matched.',
      'Vérifiez le nom du compte et celui du titulaire du permis : leur correspondance n’a pas été confirmée.',
      'تحقق من اسم الحساب وحامل الرخصة: لم يتم تأكيد التطابق.'
    ],
    'vehicle_type_matches': [
      'Check the selected vehicle type against the registration certificate.',
      'Vérifiez le type de véhicule choisi par rapport au certificat.',
      'تحقق من نوع المركبة المختار مقارنة ببطاقة التسجيل.'
    ],
    'license_validity': [
      'Expired or unclear validity: provide a valid licence with readable dates.',
      'Validité expirée ou incertaine : fournissez un permis valide avec des dates lisibles.',
      'صلاحية منتهية أو غير واضحة: أضف رخصة سارية بتواريخ مقروءة.'
    ],
    'license_category': [
      'Check the licence category and vehicle weight. Add readable proof of the appropriate category.',
      'Vérifiez la catégorie du permis et le poids du véhicule. Ajoutez une preuve lisible de la catégorie adaptée.',
      'تحقق من فئة الرخصة ووزن المركبة وأضف إثباتاً واضحاً للفئة المناسبة.'
    ],
    'payload_readable': [
      'Retake the back of the registration certificate: weight labels, values and units must be readable.',
      'Reprenez le verso de l’immatriculation : les libellés, valeurs et unités des poids doivent être lisibles.',
      'أعد تصوير ظهر بطاقة التسجيل: يجب وضوح تسميات الأوزان والقيم والوحدات.'
    ],
    'weight_values_consistent': [
      'Weight readings disagree. Retake the back with PTAC, empty weight and payload clearly visible.',
      'Les poids relevés sont incohérents. Reprenez le verso avec PTAC, poids à vide et charge utile visibles.',
      'قراءات الأوزان غير متناسقة. أعد تصوير الظهر مع وضوح الوزن الإجمالي والفارغ والحمولة.'
    ],
    'load_within_payload': [
      'Check declared capacity and occupants/equipment weight against the documented payload. A new photo alone does not fix overload.',
      'Vérifiez la capacité déclarée et le poids des occupants/équipements par rapport à la charge utile. Changer la photo ne corrige pas une surcharge.',
      'تحقق من الحمولة المصرح بها ووزن الركاب والمعدات مقارنة بالحد الموثق. تغيير الصورة وحده لا يصحح تجاوز الحمولة.'
    ],
    'insurance_validity': [
      'Expired, future or unclear insurance: provide current proof with readable start and end dates.',
      'Assurance expirée, future ou incertaine : ajoutez un justificatif en cours avec les dates de début et fin lisibles.',
      'تأمين منتهٍ أو مستقبلي أو غير واضح: أضف إثباتاً سارياً بتواريخ بداية ونهاية مقروءة.'
    ],
    'insurance_issuer': [
      'Retake the insurance photo with the insurer name visible.',
      'Reprenez la photo d’assurance avec le nom de l’assureur visible.',
      'أعد تصوير التأمين مع ظهور اسم شركة التأمين.'
    ],
    'insurance_vehicle_matches': [
      'Compare registration numbers on insurance and registration; provide documents for the same vehicle.',
      'Comparez les immatriculations sur l’assurance et le certificat ; fournissez les documents du même véhicule.',
      'قارن أرقام التسجيل على التأمين والبطاقة وأضف وثائق المركبة نفسها.'
    ],
    'insurance_vin_matches': [
      'Compare vehicle identifiers on insurance and registration; they disagree.',
      'Comparez les identifiants du véhicule sur l’assurance et l’immatriculation : ils ne correspondent pas.',
      'قارن معرفات المركبة على التأمين والتسجيل: إنها غير متطابقة.'
    ],
    'delivery_insurance_coverage': [
      'Delivery coverage is excluded or unconfirmed. Obtain explicit coverage proof from your insurer.',
      'La couverture des livraisons est exclue ou non confirmée. Demandez un justificatif explicite à votre assureur.',
      'تغطية التوصيل مستثناة أو غير مؤكدة. اطلب إثباتاً صريحاً من شركة التأمين.'
    ],
    'vehicle_use_authorization': [
      'If this vehicle belongs to another person or a company, select the borrowed/company vehicle option. Administrator/HR review is required.',
      'Si ce véhicule appartient à un tiers ou une société, cochez l’option correspondante. Le responsable/RH examinera cette situation.',
      'إذا كانت المركبة لشخص آخر أو شركة، حدد الخيار المناسب لمراجعة المسؤول.'
    ],
  };
  final value = messages[code];
  return value == null
      ? context.tr(
          en: 'Required information is unclear. Check and retake the indicated photo.',
          fr: 'Une information obligatoire est incertaine. Vérifiez et reprenez la photo indiquée.',
          ar: 'معلومة مطلوبة غير مؤكدة. تحقق من الصورة المحددة وأعد التقاطها.')
      : context.tr(en: value[0], fr: value[1], ar: value[2]);
}
