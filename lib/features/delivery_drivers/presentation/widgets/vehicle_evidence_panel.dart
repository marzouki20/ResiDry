import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/localization/app_locale.dart';
import '../../data/vehicle_evidence_service.dart';
import '../../domain/vehicle_capacity_evidence.dart';

class VehicleEvidencePanel extends StatefulWidget {
  const VehicleEvidencePanel(
      {super.key,
      required this.declaredKg,
      required this.onChanged,
      required this.onBusyChanged,
      this.anchorKey,
      this.showValidationErrors = false,
      this.initialEvidence});
  final Key? anchorKey;
  final bool showValidationErrors;
  final VehicleCapacityEvidence? initialEvidence;
  final double declaredKg;
  final ValueChanged<VehicleCapacityEvidence?> onChanged;
  final ValueChanged<bool> onBusyChanged;
  @override
  State<VehicleEvidencePanel> createState() => _VehicleEvidencePanelState();
}

class _VehicleEvidencePanelState extends State<VehicleEvidencePanel> {
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController();
  final _reserve = TextEditingController();
  final _picker = ImagePicker();
  VehicleCapacityEvidence? _evidence;
  bool _confirmed = false;
  bool _busy = false;
  bool _failed = false;
  String? _imagePath;
  double? _payload;
  String _source = 'gallery';

  @override
  void initState() {
    super.initState();
    final initial = widget.initialEvidence;
    if (initial != null) {
      _brand.text = initial.brand;
      _model.text = initial.model;
      _year.text = initial.year;
      _reserve.text = initial.reserveKg?.toString() ?? '';
      _imagePath = initial.imagePath.isEmpty ? null : initial.imagePath;
      _source = initial.source;
      _payload = initial.payloadKg;
      _confirmed = initial.ownerConfirmed;
      _evidence = initial;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      _recoverImage();
    }
  }

  Future<void> _recoverImage() async {
    try {
      final lost = await _picker.retrieveLostData();
      if (!mounted || lost.files == null || lost.files!.isEmpty) return;
      await _read(lost.files!.first, 'recovered');
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    for (final controller in [_brand, _model, _year, _reserve]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _update() {
    final path = _imagePath;
    final evidence = VehicleCapacityEvidence(
        imagePath: path ?? '',
        source: _source,
        brand: _brand.text.trim(),
        model: _model.text.trim(),
        year: _year.text.trim(),
        payloadKg: _payload,
        reserveKg: double.tryParse(_reserve.text.replaceAll(',', '.')),
        ownerConfirmed: _confirmed);
    setState(() => _evidence = evidence);
    widget.onChanged(evidence);
  }

  Future<void> _choose(ImageSource source) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    widget.onBusyChanged(true);
    try {
      final image = await _picker.pickImage(
          source: source, imageQuality: 90, maxWidth: 2400, maxHeight: 2400);
      if (image != null && mounted) await _read(image, source.name);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        widget.onBusyChanged(false);
      }
    }
  }

  Future<void> _read(XFile image, String source) async {
    // Invalidate previous evidence before processing the replacement image.
    _imagePath = image.path;
    _payload = null;
    _confirmed = false;
    _source = source;
    _update();
    try {
      final payload = await VehicleEvidenceService().readPayload(image.path);
      if (!mounted) return;
      _payload = payload;
      _update();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final supported = !kIsWeb &&
        [TargetPlatform.android, TargetPlatform.iOS]
            .contains(defaultTargetPlatform);
    final result = _evidence?.assess(widget.declaredKg) ??
        CapacityAssessment.reviewRequired;
    return Column(
        key: widget.anchorKey,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 32),
          Text(
              context.tr(
                  en: 'AI-assisted capacity check',
                  fr: 'Contrôle de capacité assisté par IA',
                  ar: 'فحص السعة بمساعدة الذكاء الاصطناعي'),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(context.tr(
              en: 'Required before continuing: complete all vehicle details, attach a clear photo of the load plate or manufacturer document, and confirm that it belongs to your vehicle. If automatic reading is inconclusive, an administrator will review your submission.',
              fr: 'Étape obligatoire : renseignez toutes les caractéristiques du véhicule, joignez une photo lisible de la plaque de charge ou du document constructeur et confirmez qu’il correspond à votre véhicule. Si la lecture automatique est incertaine, un administrateur examinera votre dossier.',
              ar: 'خطوة إلزامية: أدخل جميع بيانات المركبة وأرفق صورة واضحة للوحة الحمولة أو وثيقة الشركة المصنعة وأكد أنها تخص مركبتك. إذا كانت القراءة الآلية غير حاسمة، فسيراجع المسؤول ملفك.')),
          const SizedBox(height: 8),
          Text(context.tr(
              en: 'Photograph a load plate or manufacturer document showing Payload / Charge utile in kg. A vehicle exterior photo cannot establish capacity.',
              fr: 'Photographiez une plaque ou un document constructeur indiquant Payload / Charge utile en kg. Une photo extérieure ne permet pas de déterminer la capacité.',
              ar: 'صوّر لوحة الحمولة أو وثيقة الصانع التي تعرض Payload / Charge utile بالكغ. صورة المركبة من الخارج لا تحدد السعة.')),
          for (final field in [
            (
              _brand,
              context.tr(en: 'Brand', fr: 'Marque', ar: 'العلامة التجارية')
            ),
            (
              _model,
              context.tr(
                  en: 'Model / variant',
                  fr: 'Modèle / variante',
                  ar: 'الطراز / النسخة')
            ),
            (_year, context.tr(en: 'Year', fr: 'Année', ar: 'السنة')),
            (
              _reserve,
              context.tr(
                  en: 'Occupants and equipment weight (kg)',
                  fr: 'Poids des occupants et équipements (kg)',
                  ar: 'وزن الركاب والمعدات (كغ)')
            ),
          ])
            Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TextField(
                  controller: field.$1,
                  enabled: !_busy,
                  keyboardType: field.$1 == _year || field.$1 == _reserve
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.text,
                  decoration: InputDecoration(
                      labelText: '${field.$2} *',
                      errorText: widget.showValidationErrors &&
                              (field.$1.text.trim().isEmpty ||
                                  (field.$1 == _year &&
                                      _evidence?.hasValidYear != true) ||
                                  (field.$1 == _reserve &&
                                      _evidence?.hasValidReserve != true))
                          ? context.tr(
                              en: 'Please enter a valid value to continue.',
                              fr: 'Veuillez renseigner une valeur valide pour poursuivre.',
                              ar: 'يرجى إدخال قيمة صحيحة للمتابعة.')
                          : null),
                  onChanged: (_) => _update(),
                )),
          const SizedBox(height: 12),
          if (widget.showValidationErrors && _imagePath == null)
            Text(
                context.tr(
                    en: 'A supporting photo is required. Take a photo or select one from your gallery.',
                    fr: 'Une photo justificative est obligatoire. Prenez une photo ou sélectionnez-en une dans votre galerie.',
                    ar: 'الصورة الداعمة إلزامية. التقط صورة أو اختر واحدة من المعرض.'),
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          if (supported)
            Wrap(spacing: 8, children: [
              OutlinedButton.icon(
                  onPressed: _busy ? null : () => _choose(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(context.tr(
                      en: 'Take photo',
                      fr: 'Prendre une photo',
                      ar: 'التقاط صورة'))),
              OutlinedButton.icon(
                  onPressed: _busy ? null : () => _choose(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(
                      context.tr(en: 'Gallery', fr: 'Galerie', ar: 'المعرض'))),
            ])
          else
            Text(context.tr(
                en: 'Photo reading is available on Android and iOS.',
                fr: 'La lecture photo est disponible sur Android et iOS.',
                ar: 'قراءة الصور متاحة على Android وiOS.')),
          if (_busy) const LinearProgressIndicator(),
          if (_imagePath != null) ...[
            const SizedBox(height: 12),
            Image.file(File(_imagePath!),
                height: 160,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image_outlined)),
            CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _confirmed,
                onChanged: _busy
                    ? null
                    : (value) {
                        _confirmed = value ?? false;
                        _update();
                      },
                title: Text(context.tr(
                    en: 'This document belongs to the vehicle I selected.',
                    fr: 'Ce document correspond au véhicule sélectionné.',
                    ar: 'هذه الوثيقة تخص المركبة التي اخترتها.'))),
            if (_payload != null)
              Text(context.tr(
                  en: 'Read payload: $_payload kg',
                  fr: 'Charge utile lue : $_payload kg',
                  ar: 'الحمولة المقروءة: $_payload كغ')),
            if (widget.showValidationErrors && !_confirmed)
              Text(
                  context.tr(
                      en: 'Please confirm that the document belongs to the selected vehicle.',
                      fr: 'Veuillez confirmer que le document correspond au véhicule sélectionné.',
                      ar: 'يرجى تأكيد أن الوثيقة تخص المركبة المحددة.'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 8),
          Text(
              switch (result) {
                CapacityAssessment.consistent => context.tr(
                    en: 'Capacity consistent with the readable evidence. Administrator approval is still required.',
                    fr: 'Capacité cohérente avec le document lisible. La validation administrateur reste nécessaire.',
                    ar: 'السعة متوافقة مع المعلومات المقروءة. ما زالت موافقة المسؤول مطلوبة.'),
                CapacityAssessment.exceedsLimit => context.tr(
                    en: 'Declared load plus occupants/equipment exceeds the documented payload. Reduce the capacity or provide corrected evidence.',
                    fr: 'La charge déclarée et les occupants/équipements dépassent la charge utile documentée. Réduisez la capacité ou fournissez une preuve corrigée.',
                    ar: 'الحمولة المعلنة مع الركاب والمعدات تتجاوز الحمولة الموثقة. خفّض السعة أو قدم دليلاً مصححًا.'),
                _ => context.tr(
                    en: 'Administrator review required: evidence is missing, incomplete or ambiguous.',
                    fr: 'Examen administrateur requis : preuve absente, incomplète ou ambiguë.',
                    ar: 'يلزم فحص المسؤول: الدليل مفقود أو غير مكتمل أو غير واضح.'),
              },
              style: TextStyle(
                  color: result == CapacityAssessment.exceedsLimit
                      ? Colors.red
                      : null)),
          if (_failed)
            Text(context.tr(
                en: 'Could not read the image. Check permissions and try a sharper photo. French/English text is supported; Arabic-only documents require review.',
                fr: 'Image illisible. Vérifiez les autorisations et essayez une photo plus nette. Le français/anglais sont pris en charge ; les documents uniquement en arabe nécessitent un examen.',
                ar: 'تعذرت قراءة الصورة. تحقق من الأذونات وصوّر بوضوح. يدعم القارئ الفرنسية والإنجليزية؛ الوثائق العربية فقط تتطلب فحصًا.')),
        ]);
  }
}
