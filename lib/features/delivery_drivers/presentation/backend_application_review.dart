import 'widgets/driver_documents_panel.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/backend/backend_client.dart';
import '../../../core/localization/app_locale.dart';
import 'application_status_screen.dart';

class BackendApplicationInbox extends StatefulWidget {
  const BackendApplicationInbox({super.key});
  @override
  State<BackendApplicationInbox> createState() =>
      _BackendApplicationInboxState();
}

class _BackendApplicationInboxState extends State<BackendApplicationInbox> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true, _failed = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final items =
          await BackendClient.request('/api/admin/applications') as List;
      if (mounted) setState(() => _items = items.cast<Map<String, dynamic>>());
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(
                  child: Text(
                      context.tr(
                          en: 'Driver applications',
                          fr: 'Candidatures des livreurs',
                          ar: 'طلبات السائقين'),
                      style: Theme.of(context).textTheme.titleLarge)),
              IconButton(
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh)),
            ]),
            if (_loading) const LinearProgressIndicator(),
            if (_failed)
              Text(context.tr(
                  en: 'Could not load applications. Retry.',
                  fr: 'Impossible de charger les candidatures. Réessayez.',
                  ar: 'تعذر تحميل الطلبات. حاول مجددًا.')),
            if (!_loading && !_failed && _items.isEmpty)
              Text(context.tr(
                  en: 'No applications submitted.',
                  fr: 'Aucune candidature transmise.',
                  ar: 'لا توجد طلبات مرسلة.')),
            for (final item in _items)
              ListTile(
                  title: Text(item['name'] as String),
                  subtitle: Text(
                      '${item['email']}\n${applicationStatusLabel(context, item['status'] as String)}'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => BackendApplicationReview(
                            id: item['id'] as String)));
                    if (mounted) _load();
                  }),
          ])));
}

class BackendApplicationReview extends StatefulWidget {
  const BackendApplicationReview({super.key, required this.id});
  final String id;
  @override
  State<BackendApplicationReview> createState() =>
      _BackendApplicationReviewState();
}

class _BackendApplicationReviewState extends State<BackendApplicationReview> {
  Map<String, dynamic>? _item;
  final _payload = TextEditingController(),
      _reserve = TextEditingController(),
      _reason = TextEditingController();
  final Map<String, Uint8List> _photos = {};
  final Set<String> _loadedPhotos = {};
  bool _loading = true,
      _busy = false,
      _failed = false,
      _identityChecked = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _payload.dispose();
    _reserve.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final item =
          await BackendClient.request('/api/admin/applications/${widget.id}')
              as Map<String, dynamic>;
      final documents =
          (item['documents'] as List).cast<Map<String, dynamic>>();
      final photos = await Future.wait(documents.map((doc) async => MapEntry(
          doc['side'] as String,
          Uint8List.fromList(await BackendClient.document(
              '/api/admin/applications/${widget.id}/documents/${doc['side']}')))));
      if (!mounted) return;
      setState(() {
        _item = item;
        _photos.addEntries(photos);
        _reserve.text = item['reserve_kg'].toString();
        if (item['ai_result'] != null) {
          try {
            _payload.text =
                (jsonDecode(item['ai_result'] as String) as Map)['payload_kg']
                        ?.toString() ??
                    '';
          } catch (_) {}
        }
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _review(String status) async {
    if (_reason.text.trim().isEmpty) {
      setState(() => _failed = true);
      return;
    }
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await BackendClient.request('/api/admin/applications/${widget.id}/review',
          method: 'POST',
          body: {
            'revision': _item!['revision'],
            'status': status,
            'reason': _reason.text.trim(),
            'identityChecked': _identityChecked,
            'payloadKg': double.tryParse(_payload.text.replaceAll(',', '.')),
            'reserveKg': double.tryParse(_reserve.text.replaceAll(',', '.')),
          });
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewable = ['SUBMITTED', 'UNDER_REVIEW'].contains(_item?['status']);
    return Scaffold(
        appBar: AppBar(
            title: Text(context.tr(
                en: 'Review application',
                fr: 'Examiner la candidature',
                ar: 'مراجعة الطلب'))),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(padding: const EdgeInsets.all(24), children: [
                if (_item != null) ...[
                  Text(
                      '${_item!['name']}\n${_item!['phone']}\n${_item!['vehicle_type']} · ${_item!['declared_kg']} kg'),
                  if (_item?['borrowed'] == true)
                    Text(context.tr(
                        en: 'Borrowed or company vehicle: administrator/HR must review the right to use this vehicle.',
                        fr: 'Véhicule prêté ou de société : le responsable/RH doit examiner le droit d’utilisation du véhicule.',
                        ar: 'مركبة مستعارة أو تابعة لشركة: يراجع المسؤول حق الاستخدام.')),
                  Text(applicationStatusLabel(
                      context, _item!['status'] as String)),
                  Text(context.tr(
                      en: 'AI analysis assists review; it does not approve the driver.',
                      fr: 'L’analyse IA aide à l’examen ; elle n’approuve pas le livreur.',
                      ar: 'تحليل الذكاء الاصطناعي يساعد المراجعة ولا يوافق على السائق.')),
                  Text(_item!['ai_status'] == 'CONSISTENT'
                      ? context.tr(
                          en: 'AI found consistent capacity data.',
                          fr:
                              'L’IA a relevé des données de capacité cohérentes.',
                          ar: 'وجد الذكاء الاصطناعي بيانات سعة متوافقة.')
                      : _item!['ai_status'] == 'FLAGGED'
                          ? context.tr(
                              en:
                                  'AI flagged an inconsistency. Inspect the evidence.',
                              fr:
                                  'L’IA a signalé une incohérence. Examinez les preuves.',
                              ar:
                                  'أشار الذكاء الاصطناعي إلى تناقض. افحص الأدلة.')
                          : context.tr(
                              en: 'Manual review is needed, or analysis is pending.',
                              fr: 'Un examen manuel est requis ou l’analyse est en attente.',
                              ar: 'تلزم مراجعة يدوية أو التحليل قيد الانتظار.')),
                  if (_item?['ai_result'] is String)
                    for (final check
                        in (jsonDecode(_item!['ai_result'] as String)['checks']
                                as List? ??
                            []))
                      Text(
                          '${check['status'] == 'PASS' ? 'OK' : '!'} ${verificationCheckLabel(context, check['code'] as String)}'),
                  for (final entry in _photos.entries) ...[
                    Text(documentLabel(context, entry.key)),
                    SizedBox(
                        height: 220,
                        child: InteractiveViewer(
                            child: Image.memory(entry.value,
                                fit: BoxFit.contain,
                                frameBuilder: (context, child, frame, sync) {
                                  if ((sync || frame != null) &&
                                      !_loadedPhotos.contains(entry.key)) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      if (mounted) {
                                        setState(
                                            () => _loadedPhotos.add(entry.key));
                                      }
                                    });
                                  }
                                  return child;
                                },
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image_outlined)))),
                  ],
                  if (reviewable) ...[
                    TextField(
                        controller: _payload,
                        enabled: !_busy,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                            labelText: context.tr(
                                en: 'Confirmed payload (kg)',
                                fr: 'Charge utile confirmée (kg)',
                                ar: 'الحمولة المؤكدة (كغ)'))),
                    TextField(
                        controller: _reserve,
                        enabled: !_busy,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                            labelText: context.tr(
                                en: 'Confirmed occupants/equipment (kg)',
                                fr: 'Occupants/équipements confirmés (kg)',
                                ar: 'وزن الركاب والمعدات المؤكد (كغ)'))),
                    TextField(
                        controller: _reason,
                        enabled: !_busy,
                        maxLines: 3,
                        maxLength: 2000,
                        decoration: InputDecoration(
                            labelText: context.tr(
                                en: 'Decision reason — required',
                                fr: 'Motif de décision — obligatoire',
                                ar: 'سبب القرار — إلزامي'))),
                    CheckboxListTile(
                        value: _identityChecked,
                        onChanged: _busy
                            ? null
                            : (value) => setState(
                                () => _identityChecked = value ?? false),
                        title: Text(context.tr(
                            en: 'I checked the driver/vehicle documents and weight limits.',
                            fr: 'J’ai vérifié les documents du livreur/véhicule et les limites de poids.',
                            ar: 'تحققت من وثائق السائق والمركبة وحدود الوزن.'))),
                    FilledButton(
                        onPressed: _busy ||
                                (!['V\u00e9lo']
                                        .contains(_item?['vehicle_type']) &&
                                    _item?['ai_status'] != 'CONSISTENT') ||
                                !_identityChecked ||
                                (_photos.isNotEmpty &&
                                    _loadedPhotos.length != _photos.length)
                            ? null
                            : () => _review('APPROVED'),
                        child: Text(context.tr(
                            en: 'Approve application',
                            fr: 'Approuver la candidature',
                            ar: 'الموافقة على الطلب'))),
                    OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () => _review('CORRECTION_REQUESTED'),
                        child: Text(context.tr(
                            en: 'Request corrections',
                            fr: 'Demander des corrections',
                            ar: 'طلب تصحيحات'))),
                    TextButton(
                        onPressed: _busy ? null : () => _review('REJECTED'),
                        child: Text(context.tr(
                            en: 'Reject application',
                            fr: 'Refuser la candidature',
                            ar: 'رفض الطلب'))),
                  ],
                  if (_item!['review_reason'] != null)
                    Text(_item!['review_reason'] as String),
                ],
                if (_failed)
                  Text(context.tr(
                      en: 'Check the reason, weights and latest application. The request could not be completed.',
                      fr: 'Vérifiez le motif, les poids et la version du dossier. La demande n’a pas abouti.',
                      ar: 'تحقق من السبب والأوزان وأحدث نسخة للطلب. تعذر إتمام الطلب.')),
              ]));
  }
}
