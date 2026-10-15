import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/localization/app_locale.dart';
import '../data/driver_profile_repository.dart';
import '../data/vehicle_evidence_service.dart';
import '../domain/vehicle_capacity_evidence.dart';

class CapacityReviewScreen extends StatefulWidget {
  const CapacityReviewScreen(
      {super.key,
      required this.driverId,
      required this.driverName,
      required this.reviewer});
  final String driverId;
  final String driverName;
  final String reviewer;
  @override
  State<CapacityReviewScreen> createState() => _CapacityReviewScreenState();
}

class _CapacityReviewScreenState extends State<CapacityReviewScreen> {
  final _repository = DriverProfileRepository();
  final _payload = TextEditingController();
  final _reserve = TextEditingController();
  Map<String, Object?>? _record;
  bool _loading = true;
  bool _busy = false;
  bool _confirmed = false;
  bool _failed = false;
  bool _imageReady = false;
  String? _aiText;
  double? _aiPayload;
  bool _analyzing = false;
  bool _analysisFailed = false;

  Future<void> _analyze() async {
    setState(() {
      _analyzing = true;
      _analysisFailed = false;
      _aiText = null;
      _aiPayload = null;
    });
    try {
      final text = await VehicleEvidenceService()
          .readText(_record!['photo_path']! as String);
      if (!mounted) return;
      setState(() {
        _aiText = text;
        _aiPayload = VehicleCapacityEvidence.extractPayload(text);
      });
    } catch (_) {
      if (mounted) setState(() => _analysisFailed = true);
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final record = await _repository.getEvidence(widget.driverId);
      if (!mounted) return;
      setState(() {
        _record = record;
        _payload.text = record?['payload_kg']?.toString() ?? '';
        _reserve.text = record?['reserve_kg']?.toString() ?? '';
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _payload.dispose();
    _reserve.dispose();
    super.dispose();
  }

  Future<void> _submit(bool approved) async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await _repository.reviewEvidence(
          driverId: widget.driverId,
          recordedAt: _record!['recorded_at']! as String,
          reviewer: widget.reviewer,
          approved: approved,
          payloadKg: double.tryParse(_payload.text.replaceAll(',', '.')),
          reserveKg: double.tryParse(_reserve.text.replaceAll(',', '.')));
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = _record;
    final photo = record == null ? null : File(record['photo_path']! as String);
    final available = photo?.existsSync() ?? false;
    return Scaffold(
      appBar: AppBar(
          title: Text(context.tr(
              en: 'Driver and vehicle verification',
              fr: 'Vérification du livreur et du véhicule',
              ar: 'التحقق من السائق والمركبة'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(widget.driverName,
                    style: Theme.of(context).textTheme.titleLarge),
                if (record == null)
                  Text(context.tr(
                      en: 'No capacity evidence submitted.',
                      fr: 'Aucune preuve de capacité transmise.',
                      ar: 'لم يتم تقديم دليل للسعة.'))
                else ...[
                  Text(
                      '${record['brand']} ${record['model']} · ${record['vehicle_year']}'),
                  Text(context.tr(
                      en: 'Declared laundry capacity: ${record['declared_kg']} kg',
                      fr: 'Capacité de linge déclarée : ${record['declared_kg']} kg',
                      ar: 'سعة الملابس المعلنة: ${record['declared_kg']} كغ')),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed:
                        !available || _busy || _analyzing ? null : _analyze,
                    icon: const Icon(Icons.document_scanner_outlined),
                    label: Text(context.tr(
                        en: 'AI document analysis',
                        fr: 'Analyse IA du document',
                        ar: 'تحليل الوثيقة بالذكاء الاصطناعي')),
                  ),
                  if (_analyzing) const LinearProgressIndicator(),
                  if (_aiText != null || _analysisFailed) ...[
                    Text(_aiPayload == null
                        ? context.tr(
                            en:
                                'AI recommendation: manual review. No unique labelled payload could be read reliably.',
                            fr:
                                'Recommandation IA : examen manuel. Aucune charge utile explicite et unique n’a pu être lue de manière fiable.',
                            ar:
                                'توصية الذكاء الاصطناعي: مراجعة يدوية. تعذرت قراءة حمولة واضحة وفريدة بشكل موثوق.')
                        : context.tr(
                            en: 'Detected payload: $_aiPayload kg. Compare it with the document before approval.',
                            fr: 'Charge utile détectée : $_aiPayload kg. Comparez-la au document avant validation.',
                            ar: 'الحمولة المكتشفة: $_aiPayload كغ. قارنها بالوثيقة قبل الموافقة.')),
                    if (_aiPayload != null)
                      Text((record['declared_kg']! as num).toDouble() +
                                  ((record['reserve_kg'] as num?)?.toDouble() ??
                                      0) >
                              _aiPayload!
                          ? context.tr(
                              en:
                                  'AI recommendation: correct the declared capacity. The total load exceeds the detected payload.',
                              fr:
                                  'Recommandation IA : corriger la capacité déclarée. La charge totale dépasse la charge utile détectée.',
                              ar:
                                  'توصية الذكاء الاصطناعي: تصحيح السعة المعلنة. الوزن الإجمالي يتجاوز الحمولة المكتشفة.')
                          : context.tr(
                              en: 'AI recommendation: load is consistent. Verify document authenticity and vehicle identity before approval.',
                              fr: 'Recommandation IA : charge cohérente. Vérifiez l’authenticité du document et l’identité du véhicule avant validation.',
                              ar: 'توصية الذكاء الاصطناعي: الوزن متوافق. تحقق من صحة الوثيقة وهوية المركبة قبل الموافقة.')),
                    if (_aiPayload != null)
                      Text(context.tr(
                          en: 'Available for laundry: ${_aiPayload! - ((record['reserve_kg'] as num?)?.toDouble() ?? 0)} kg; declared: ${record['declared_kg']} kg.',
                          fr: 'Disponible pour le linge : ${_aiPayload! - ((record['reserve_kg'] as num?)?.toDouble() ?? 0)} kg ; déclaré : ${record['declared_kg']} kg.',
                          ar: 'المتاح للملابس: ${_aiPayload! - ((record['reserve_kg'] as num?)?.toDouble() ?? 0)} كغ؛ المعلن: ${record['declared_kg']} كغ.')),
                    if (_aiText != null)
                      ExpansionTile(
                        title: Text(context.tr(
                            en: 'Extracted document text',
                            fr: 'Texte extrait du document',
                            ar: 'النص المستخرج من الوثيقة')),
                        children: [SelectableText(_aiText!)],
                      ),
                  ],
                  if (available)
                    SizedBox(
                        height: 300,
                        child: InteractiveViewer(
                            child: Image.file(photo!,
                                fit: BoxFit.contain,
                                frameBuilder:
                                    (context, child, frame, syncLoaded) {
                                  if ((syncLoaded || frame != null) &&
                                      !_imageReady) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      if (mounted && !_imageReady) {
                                        setState(() => _imageReady = true);
                                      }
                                    });
                                  }
                                  return child;
                                },
                                errorBuilder: (_, __, ___) => Text(context.tr(
                                    en: 'Image unavailable. Request new evidence.',
                                    fr: 'Image indisponible. Demandez une nouvelle preuve.',
                                    ar: 'الصورة غير متاحة. اطلب دليلاً جديدًا.'))))),
                  if ((record['back_photo_path'] as String? ?? '')
                      .isNotEmpty) ...[
                    Text(context.tr(
                        en: 'Certificate back',
                        fr: 'Verso du certificat',
                        ar: 'الوجه الخلفي للشهادة')),
                    SizedBox(
                        height: 250,
                        child: InteractiveViewer(
                            child: Image.file(
                                File(record['back_photo_path']! as String),
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image_outlined)))),
                  ],
                  Text(context.tr(
                      en: 'Inspect the document and enter the confirmed payload and occupants/equipment weight. OCR does not prove authenticity or vehicle identity.',
                      fr: 'Examinez le document et confirmez la charge utile et le poids des occupants/équipements. L’OCR ne prouve ni l’authenticité ni l’identité du véhicule.',
                      ar: 'افحص الوثيقة وأدخل الحمولة المؤكدة ووزن الركاب والمعدات. قراءة النص لا تثبت أصالة الوثيقة أو هوية المركبة.')),
                  TextField(
                      controller: _payload,
                      enabled: !_busy,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                          labelText: context.tr(
                              en: 'Confirmed payload (kg)',
                              fr: 'Charge utile confirmée (kg)',
                              ar: 'الحمولة المؤكدة (كغ)'))),
                  TextField(
                      controller: _reserve,
                      enabled: !_busy,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                          labelText: context.tr(
                              en: 'Occupants and equipment (kg)',
                              fr: 'Occupants et équipements (kg)',
                              ar: 'الركاب والمعدات (كغ)'))),
                  CheckboxListTile(
                      value: _confirmed,
                      onChanged: _busy
                          ? null
                          : (value) =>
                              setState(() => _confirmed = value ?? false),
                      title: Text(context.tr(
                          en: 'I checked the vehicle identity and the documented weight limits.',
                          fr: 'J’ai vérifié l’identité du véhicule et les limites de poids documentées.',
                          ar: 'تحققت من هوية المركبة وحدود الوزن الموثقة.'))),
                  FilledButton(
                      onPressed: _busy ||
                              _analyzing ||
                              !_confirmed ||
                              !available ||
                              !_imageReady
                          ? null
                          : () => _submit(true),
                      child: Text(context.tr(
                          en: 'Approve capacity',
                          fr: 'Valider la capacité',
                          ar: 'الموافقة على السعة'))),
                  OutlinedButton(
                      onPressed: _busy ? null : () => _submit(false),
                      child: Text(context.tr(
                          en: 'Reject evidence',
                          fr: 'Refuser la preuve',
                          ar: 'رفض الدليل'))),
                ],
                if (_failed)
                  Text(context.tr(
                      en: 'Review failed. Check the weights or reopen the latest evidence.',
                      fr: 'Échec de l’examen. Vérifiez les poids ou rouvrez la dernière preuve.',
                      ar: 'فشل الفحص. تحقق من الأوزان أو افتح أحدث دليل.')),
              ],
            ),
    );
  }
}
