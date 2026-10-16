import 'document_feedback.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/backend/backend_client.dart';
import '../../../../core/localization/app_locale.dart';
import '../../domain/vehicle_capacity_evidence.dart';

String documentLabel(BuildContext context, String slot) {
  final labels = <String, List<String>>{
    'FRONT': [
      'Registration — front',
      'Immatriculation — recto',
      'بطاقة التسجيل — الوجه الأمامي'
    ],
    'BACK': [
      'Registration — back',
      'Immatriculation — verso',
      'بطاقة التسجيل — الوجه الخلفي'
    ],
    'LICENSE_FRONT': [
      'Driving licence — front',
      'Permis de conduire — recto',
      'رخصة القيادة — الوجه الأمامي'
    ],
    'LICENSE_BACK': [
      'Driving licence — back',
      'Permis de conduire — verso',
      'رخصة القيادة — الوجه الخلفي'
    ],
    'INSURANCE': [
      'Insurance and delivery coverage',
      'Assurance et couverture des livraisons',
      'التأمين وتغطية التوصيل'
    ],
    'TECHNICAL_INSPECTION': [
      'Technical-inspection certificate',
      'Certificat de visite technique',
      'شهادة الفحص الفني'
    ],
    'VEHICLE_PHOTO': ['Vehicle photo', 'Photo du véhicule', 'صورة المركبة'],
    'AUTHORIZATION': [
      'Vehicle use authorization',
      'Autorisation d’utilisation du véhicule',
      'ترخيص استعمال المركبة'
    ],
  };
  final value = labels[slot];
  return value == null
      ? slot
      : context.tr(en: value[0], fr: value[1], ar: value[2]);
}

String verificationCheckLabel(BuildContext context, String code) {
  const labels = <String, List<String>>{
    'tunisian_registration': [
      'Tunisian registration certificate',
      'Certificat d’immatriculation tunisien',
      'بطاقة تسجيل تونسية'
    ],
    'registration_sides_match': [
      'Registration sides match',
      'Correspondance recto/verso de l’immatriculation',
      'تطابق وجهي بطاقة التسجيل'
    ],
    'tunisian_license': [
      'Tunisian driving licence',
      'Permis tunisien',
      'رخصة قيادة تونسية'
    ],
    'license_sides_match': [
      'Licence sides match',
      'Correspondance recto/verso du permis',
      'تطابق وجهي الرخصة'
    ],
    'driver_name_matches_license': [
      'Account name matches licence',
      'Nom du compte conforme au permis',
      'تطابق اسم الحساب مع الرخصة'
    ],
    'vehicle_type_matches': [
      'Selected vehicle type',
      'Type de véhicule choisi',
      'نوع المركبة المختار'
    ],
    'license_validity': [
      'Readable licence identity and categories',
      'Identité et catégories du permis lisibles',
      'هوية وفئات الرخصة مقروءة'
    ],
    'license_category': [
      'Licence category for this vehicle',
      'Catégorie du permis adaptée au véhicule',
      'فئة الرخصة المناسبة للمركبة'
    ],
    'payload_readable': [
      'Documented payload',
      'Charge utile lisible et documentée',
      'حمولة موثقة ومقروءة'
    ],
    'load_within_payload': [
      'Capacity plus occupants within payload',
      'Capacité et occupants dans la charge utile',
      'الحمولة مع وزن الركاب ضمن الحد'
    ],
    'weight_values_consistent': [
      'Weight values agree',
      'Cohérence des poids',
      'تناسق الأوزان'
    ],
    'tunisian_inspection': [
      'Tunisian technical-inspection certificate',
      'Certificat tunisien de visite technique',
      'شهادة فحص فني تونسية'
    ],
    'inspection_validity': [
      'Inspection validity',
      'Validité de la visite technique',
      'صلاحية الفحص الفني'
    ],
    'inspection_vehicle_matches': [
      'Inspection registration matches vehicle',
      'Immatriculation de la visite technique conforme',
      'تطابق ترقيم المركبة في شهادة الفحص'
    ],
    'inspection_vin_matches': [
      'Inspection chassis number matches',
      'Numéro de châssis de la visite technique conforme',
      'تطابق رقم الهيكل في شهادة الفحص'
    ],
    'inspection_center': [
      'Readable inspection centre',
      'Centre de contrôle lisible',
      'مركز الفحص مقروء'
    ],
    'insurance_validity': [
      'Insurance validity',
      'Validité de l’assurance',
      'صلاحية التأمين'
    ],
    'insurance_issuer': [
      'Identifiable insurer',
      'Assureur identifiable',
      'شركة تأمين معروفة'
    ],
    'insurance_vehicle_matches': [
      'Insured registration matches vehicle',
      'Immatriculation assurée conforme',
      'تطابق ترقيم المركبة المؤمنة'
    ],
    'insurance_vin_matches': [
      'Vehicle identifiers match',
      'Identifiants du véhicule conformes',
      'تطابق معرفات المركبة'
    ],
    'delivery_insurance_coverage': [
      'Explicit delivery coverage',
      'Couverture explicite des livraisons',
      'تغطية صريحة للتوصيل'
    ],
    'vehicle_use_authorization': [
      'Owner authorization matches',
      'Autorisation du propriétaire conforme',
      'ترخيص المالك مطابق'
    ],
    'registered_owner_matches': [
      'Registered owner matches driver',
      'Propriétaire conforme au livreur',
      'تطابق المالك مع السائق'
    ],
    'vehicle_plate': [
      'Readable registration number',
      'Immatriculation lisible',
      'رقم تسجيل مقروء'
    ],
    'vehicle_brand': [
      'Readable vehicle brand',
      'Marque lisible',
      'علامة المركبة مقروءة'
    ],
    'vehicle_model': [
      'Readable vehicle model',
      'Modèle lisible',
      'طراز المركبة مقروء'
    ],
    'registration_date': [
      'Registration date',
      'Date de mise en circulation',
      'تاريخ التسجيل'
    ],
  };
  final value = labels[code];
  return value == null
      ? code
      : context.tr(en: value[0], fr: value[1], ar: value[2]);
}

class DriverDocumentsPanel extends StatefulWidget {
  const DriverDocumentsPanel(
      {super.key,
      required this.vehicleType,
      required this.declaredKg,
      required this.onChanged,
      required this.onBusyChanged,
      this.initialEvidence});
  final String vehicleType;
  final double declaredKg;
  final VehicleCapacityEvidence? initialEvidence;
  final ValueChanged<VehicleCapacityEvidence?> onChanged;
  final ValueChanged<bool> onBusyChanged;
  @override
  State<DriverDocumentsPanel> createState() => _DriverDocumentsPanelState();
}

class _DriverDocumentsPanelState extends State<DriverDocumentsPanel> {
  final _picker = ImagePicker();
  final Map<String, String> _paths = {};
  late final _reserve = TextEditingController(
      text: widget.initialEvidence?.reserveKg?.toString() ?? '');
  bool _consent = false, _borrowed = false, _busy = false;
  Map<String, dynamic>? _report;
  String? _receipt;
  String _photoSource = '';
  bool get _motorcycle => widget.vehicleType == 'Moto';
  @override
  void initState() {
    super.initState();
    final initial = widget.initialEvidence;
    if (initial != null) {
      if (initial.imagePath.isNotEmpty) _paths['FRONT'] = initial.imagePath;
      if (initial.backImagePath.isNotEmpty) {
        _paths['BACK'] = initial.backImagePath;
      }
      _paths.addAll(initial.supportingPaths);
      _paths.remove('AUTHORIZATION');
      _consent = initial.ownerConfirmed;
      _borrowed = initial.borrowed;
      _photoSource = initial.vehiclePhotoSource.isNotEmpty
          ? initial.vehiclePhotoSource
          : initial.source == 'vehicle_photo_camera'
              ? 'camera'
              : '';
      // A reopened screen always requests a fresh server verification.
    }
  }

  @override
  void dispose() {
    _reserve.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(VehicleCapacityEvidence(
        imagePath: _paths['FRONT'] ?? '',
        backImagePath: _paths['BACK'] ?? '',
        source: 'registration',
        vehiclePhotoSource: _photoSource,
        brand: '',
        model: '',
        year: '',
        payloadKg: (_report?['payload_kg'] as num?)?.toDouble(),
        reserveKg: double.tryParse(_reserve.text.replaceAll(',', '.')),
        ownerConfirmed: _consent,
        supportingPaths: Map.of(_paths)
          ..remove('FRONT')
          ..remove('BACK'),
        borrowed: _borrowed,
        verificationId: _receipt,
        verifiedCapacity: _receipt == null ? null : widget.declaredKg,
        verifiedVehicle: _receipt == null ? null : widget.vehicleType));
  }

  void _invalidate() {
    _receipt = null;
    _report = null;
    _emit();
  }

  Future<void> _pick(String slot, ImageSource source) async {
    setState(() => _busy = true);
    widget.onBusyChanged(true);
    try {
      final photo = await _picker.pickImage(
          source: source, maxWidth: 2200, imageQuality: 90);
      if (photo != null && mounted) {
        setState(() {
          _paths[slot] = photo.path;
          if (slot == 'VEHICLE_PHOTO') {
            _photoSource = source == ImageSource.camera ? 'camera' : 'gallery';
          }
          _invalidate();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _report = {'status': 'UNAVAILABLE'});
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        widget.onBusyChanged(false);
      }
    }
  }

  Future<void> _verify() async {
    setState(() {
      _busy = true;
      _receipt = null;
      _report = null;
    });
    widget.onBusyChanged(true);
    _emit();
    try {
      final documents = <String, String>{};
      for (final entry in _paths.entries) {
        documents[entry.key] =
            base64Encode(await File(entry.value).readAsBytes());
      }
      final report = await BackendClient.request(
          '/api/driver/application/verify-documents',
          method: 'POST',
          body: {
            'vehicleType': widget.vehicleType,
            'declaredKg': widget.declaredKg,
            'reserveKg': double.parse(_reserve.text.replaceAll(',', '.')),
            'zones': <String>[],
            'consent': _consent,
            'borrowed': _borrowed,
            'front': documents['FRONT'],
            'back': documents['BACK'],
            'licenseFront': documents['LICENSE_FRONT'],
            'licenseBack': documents['LICENSE_BACK'],
            'insurance': documents['INSURANCE'],
            'technicalInspection': documents['TECHNICAL_INSPECTION'],
            'vehiclePhoto': documents['VEHICLE_PHOTO'],
            'vehiclePhotoSource': _photoSource,
          }) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _report = report;
          _receipt = report['status'] == 'PASSED'
              ? report['verificationId'] as String?
              : null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _report = {'status': 'UNAVAILABLE'});
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _emit();
        widget.onBusyChanged(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final slots = [
      'FRONT',
      'BACK',
      'LICENSE_FRONT',
      'LICENSE_BACK',
      'INSURANCE',
      if (!_motorcycle) 'TECHNICAL_INSPECTION',
      if (_motorcycle) 'VEHICLE_PHOTO',
    ];
    final reserve = double.tryParse(_reserve.text.replaceAll(',', '.'));
    final ready = _consent &&
        reserve != null &&
        reserve.isFinite &&
        reserve >= 0 &&
        reserve <= 10000 &&
        slots.every(_paths.containsKey) &&
        (!_motorcycle || _photoSource == 'camera');
    final issues = documentIssues(_report);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
          context.tr(
              en: 'Required driver documents',
              fr: 'Documents obligatoires du livreur',
              ar: 'وثائق السائق الإلزامية'),
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      Text(context.tr(
          en: 'Use clear, complete photos of your documents. AI checks every photo and compares the licence, vehicle, insurance and capacity. An uncertain or failed check blocks Continue. Internet is required.',
          fr: 'Ajoutez des photos nettes et complètes de vos documents. L’IA examine chaque photo et compare permis, véhicule, assurance et capacité. Tout contrôle incertain ou échoué bloque Continuer. Internet est requis.',
          ar: 'أضف صوراً واضحة وكاملة لوثائقك. يفحص الذكاء الاصطناعي كل صورة ويقارن الرخصة والمركبة والتأمين والحمولة. أي نتيجة غير مؤكدة أو فاشلة تمنع المتابعة. يلزم الإنترنت.')),
      CheckboxListTile(
          value: _borrowed,
          onChanged: _busy
              ? null
              : (value) => setState(() {
                    _borrowed = value ?? false;
                    _paths.remove('AUTHORIZATION');
                    _invalidate();
                  }),
          title: Text(context.tr(
              en: 'Borrowed or company vehicle',
              fr: 'Véhicule prêté ou appartenant à une société',
              ar: 'مركبة مستعارة أو تابعة لشركة'))),
      for (final slot in slots) ...[
        const SizedBox(height: 16),
        Text('${documentLabel(context, slot)} *'),
        if (_paths.containsKey(slot))
          Image.file(File(_paths[slot]!),
              height: 140,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
        for (final issue in issues.where((item) => item.slots.contains(slot)))
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(documentIssueMessage(context, issue),
                  style: const TextStyle(color: Colors.red))),
        Wrap(spacing: 8, children: [
          OutlinedButton.icon(
              onPressed: _busy ? null : () => _pick(slot, ImageSource.camera),
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(context.tr(
                  en: 'Camera', fr: 'Prendre une photo', ar: 'التقاط صورة'))),
          if (slot != 'VEHICLE_PHOTO')
            OutlinedButton.icon(
                onPressed:
                    _busy ? null : () => _pick(slot, ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(
                    context.tr(en: 'Gallery', fr: 'Galerie', ar: 'المعرض'))),
        ]),
      ],
      const SizedBox(height: 16),
      TextField(
          controller: _reserve,
          enabled: !_busy,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(_invalidate),
          decoration: InputDecoration(
              labelText: context.tr(
                  en: 'Occupants and equipment weight (kg) *',
                  fr: 'Poids des occupants et équipements (kg) *',
                  ar: 'وزن الركاب والمعدات (كغ) *'))),
      CheckboxListTile(
          value: _consent,
          onChanged: _busy
              ? null
              : (value) => setState(() {
                    _consent = value ?? false;
                    _invalidate();
                  }),
          title: Text(context.tr(
              en: 'I agree to send these documents to ResiDry and its AI provider for verification.',
              fr: 'J’accepte l’envoi de ces documents à ResiDry et à son fournisseur IA pour vérification.',
              ar: 'أوافق على إرسال الوثائق إلى ريزيدراي ومزود الذكاء الاصطناعي للتحقق.'))),
      FilledButton.icon(
          onPressed: _busy || !ready ? null : _verify,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.document_scanner_outlined),
          label: Text(context.tr(
              en: 'Analyse every document with AI',
              fr: 'Analyser tous les documents avec l’IA',
              ar: 'تحليل كل الوثائق بالذكاء الاصطناعي'))),
      if (_report != null && (_receipt != null || issues.isEmpty)) ...[
        const SizedBox(height: 12),
        Text(
            _report?['status'] == 'UNAVAILABLE'
                ? context.tr(
                    en:
                        'Verification service unavailable. No photo has been validated or rejected. Retry when the service is available.',
                    fr:
                        'Service de vérification indisponible. Aucune photo n’a été validée ou refusée. Réessayez lorsque le service est disponible.',
                    ar:
                        'خدمة التحقق غير متاحة. لم يتم قبول أي صورة أو رفضها. أعد المحاولة لاحقاً.')
                : _receipt != null
                    ? context.tr(
                        en: 'Checks passed. You may continue.',
                        fr: 'Contrôles réussis. Vous pouvez continuer.',
                        ar: 'نجحت الفحوصات. يمكنك المتابعة.')
                    : context.tr(
                        en:
                            'Verification failed or unavailable. Correct the documents and retry; Continue remains blocked.',
                        fr:
                            'Vérification échouée ou indisponible. Corrigez les documents et réessayez ; Continuer reste bloqué.',
                        ar:
                            'فشل التحقق أو تعذر إجراؤه. صحح الوثائق وأعد المحاولة؛ المتابعة محظورة.'),
            style:
                TextStyle(color: _receipt != null ? Colors.green : Colors.red)),
        if (_receipt != null)
          for (final check in (_report!['checks'] as List? ?? []))
            Text(
                'OK: ${verificationCheckLabel(context, check['code'] as String)}'),
      ],
      const SizedBox(height: 12),
      Text(context.tr(
          en: 'AI checks document data; it cannot certify authenticity. Administrator approval remains required. Any change requires a new scan.',
          fr: 'L’IA contrôle les données, sans certifier l’authenticité. L’approbation administrative reste obligatoire. Toute modification exige une nouvelle analyse.',
          ar: 'يفحص الذكاء الاصطناعي البيانات ولا يثبت أصالة الوثائق. تبقى موافقة الإدارة إلزامية. كل تعديل يتطلب تحليلاً جديداً.')),
    ]);
  }
}
