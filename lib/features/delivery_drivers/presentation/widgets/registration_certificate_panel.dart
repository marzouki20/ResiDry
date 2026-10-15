import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/localization/app_locale.dart';
import '../../data/registration_verification_service.dart';
import '../../domain/vehicle_capacity_evidence.dart';
import '../../../../core/backend/backend_client.dart';

class RegistrationCertificatePanel extends StatefulWidget {
  const RegistrationCertificatePanel(
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
  State<RegistrationCertificatePanel> createState() =>
      _RegistrationCertificatePanelState();
}

class _RegistrationCertificatePanelState
    extends State<RegistrationCertificatePanel> {
  final _picker = ImagePicker();
  late final _reserve = TextEditingController(
      text: widget.initialEvidence?.reserveKg?.toString() ?? '');
  String? _front, _back;
  RegistrationResult? _result;
  bool _busy = false, _consent = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final front = widget.initialEvidence?.imagePath;
    _front = front == null || front.isEmpty ? null : front;
    final back = widget.initialEvidence?.backImagePath;
    _back = back == null || back.isEmpty ? null : back;
    final initial = widget.initialEvidence;
    if (BackendClient.enabled) _consent = initial?.ownerConfirmed ?? false;
    if (initial?.source == 'registration' &&
        _back != null &&
        initial!.isComplete) {
      _consent = true;
      _result = RegistrationResult(
          status: 'passed',
          reason: initial.registrationText,
          brand: initial.brand,
          model: initial.model,
          year: initial.year,
          payloadKg: initial.payloadKg);
    }
    // Old local evidence is not an online certificate verification.
  }

  @override
  void dispose() {
    _reserve.dispose();
    super.dispose();
  }

  void _invalidate() {
    _result = null;
    _error = null;
    final reserve = double.tryParse(_reserve.text.replaceAll(',', '.'));
    widget.onChanged(BackendClient.enabled
        ? VehicleCapacityEvidence(
            imagePath: _front ?? '',
            backImagePath: _back ?? '',
            source: 'registration',
            brand: '',
            model: '',
            year: '',
            payloadKg: null,
            reserveKg: reserve != null && reserve.isFinite && reserve >= 0
                ? reserve
                : null,
            ownerConfirmed: _consent)
        : null);
  }

  void _setBusy(bool value) {
    setState(() => _busy = value);
    widget.onBusyChanged(value);
  }

  Future<void> _pick(bool front, ImageSource source) async {
    _setBusy(true);
    try {
      final image = await _picker.pickImage(
          source: source, imageQuality: 90, maxWidth: 2400, maxHeight: 2400);
      if (!mounted || image == null) return;
      setState(() {
        if (front) {
          _front = image.path;
        } else {
          _back = image.path;
        }
        _invalidate();
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'photo');
    } finally {
      if (mounted) _setBusy(false);
    }
  }

  Future<void> _verify() async {
    final reserve = double.tryParse(_reserve.text.replaceAll(',', '.'));
    if (_front == null ||
        _back == null ||
        !_consent ||
        reserve == null ||
        !reserve.isFinite ||
        reserve < 0) {
      setState(() => _error = 'required');
      return;
    }
    _setBusy(true);
    _invalidate();
    try {
      final result = await RegistrationVerificationService().verify(
          frontPath: _front!,
          backPath: _back!,
          vehicleType: widget.vehicleType,
          declaredKg: widget.declaredKg,
          reserveKg: reserve);
      if (!mounted) return;
      setState(() => _result = result);
      if (result.passed) {
        widget.onChanged(VehicleCapacityEvidence(
            imagePath: _front!,
            backImagePath: _back!,
            source: 'registration',
            brand: result.brand!,
            model: result.model!,
            year: result.year!,
            payloadKg: result.payloadKg,
            reserveKg: reserve,
            ownerConfirmed: true,
            registrationText: result.reason));
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error =
            error is StateError && error.message == 'service_not_configured'
                ? 'configuration'
                : 'network');
      }
    } finally {
      if (mounted) _setBusy(false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (BackendClient.enabled && widget.vehicleType == 'Vélo')
            Text(context.tr(
                en: 'Bicycle application',
                fr: 'Candidature à vélo',
                ar: 'طلب العمل بالدراجة الهوائية')),
          if (!(BackendClient.enabled && widget.vehicleType == 'Vélo'))
            Text(
                context.tr(
                    en: 'Registration certificate verification',
                    fr: 'Vérification du certificat d’immatriculation',
                    ar: 'التحقق من شهادة تسجيل المركبة'),
                style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (!(BackendClient.enabled && widget.vehicleType == 'Vélo'))
            Text(context.tr(
                en: 'Required: add readable front and back photos of your Tunisian registration certificate. Confirm the weight and your consent before continuing.',
                fr: 'Obligatoire : ajoutez des photos lisibles du recto et du verso du certificat d’immatriculation tunisien. Renseignez le poids et confirmez votre accord avant de continuer.',
                ar: 'إلزامي: أضف صورًا واضحة لوجهي شهادة تسجيل المركبة التونسية. أدخل الوزن وأكد موافقتك قبل المتابعة.')),
          if (BackendClient.enabled && widget.vehicleType == 'Vélo')
            Text(context.tr(
                en: 'A registration certificate is not requested for this bicycle application. Enter the equipment/occupant weight and confirm your application for manual review.',
                fr: 'Aucun certificat d’immatriculation n’est demandé pour cette candidature à vélo. Renseignez le poids des équipements/occupants et confirmez votre dossier pour examen manuel.',
                ar: 'لا تُطلب شهادة تسجيل لهذا الطلب بالدراجة الهوائية. أدخل وزن المعدات والركاب وأكد الطلب للمراجعة اليدوية.')),
          Text(context.tr(
              en: 'Declared capacity: ${widget.declaredKg} kg',
              fr: 'Capacité déclarée : ${widget.declaredKg} kg',
              ar: 'السعة المعلنة: ${widget.declaredKg} كغ')),
          for (final front
              in (BackendClient.enabled && widget.vehicleType == 'Vélo'
                  ? <bool>[]
                  : [true, false])) ...[
            const SizedBox(height: 16),
            Text(front
                ? context.tr(
                    en: 'Front — required',
                    fr: 'Recto — obligatoire',
                    ar: 'الوجه الأمامي — إلزامي')
                : context.tr(
                    en: 'Back — required',
                    fr: 'Verso — obligatoire',
                    ar: 'الوجه الخلفي — إلزامي')),
            if ((front ? _front : _back) != null)
              Image.file(File((front ? _front : _back)!),
                  height: 140,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.broken_image_outlined)),
            Wrap(spacing: 8, children: [
              OutlinedButton.icon(
                  onPressed:
                      _busy ? null : () => _pick(front, ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(context.tr(
                      en: 'Take photo',
                      fr: 'Prendre une photo',
                      ar: 'التقاط صورة'))),
              OutlinedButton.icon(
                  onPressed:
                      _busy ? null : () => _pick(front, ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(
                      context.tr(en: 'Gallery', fr: 'Galerie', ar: 'المعرض'))),
            ]),
          ],
          TextField(
              controller: _reserve,
              enabled: !_busy,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(_invalidate),
              decoration: InputDecoration(
                  labelText: context.tr(
                      en: 'Occupants and equipment weight (kg) — required',
                      fr: 'Poids des occupants et équipements (kg) — obligatoire',
                      ar: 'وزن الركاب والمعدات (كغ) — إلزامي'))),
          CheckboxListTile(
              value: _consent,
              onChanged: _busy
                  ? null
                  : (value) => setState(() {
                        _consent = value ?? false;
                        _invalidate();
                      }),
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr(
                  en: 'This certificate belongs to the selected vehicle. I agree to send both photos to the verification server and AI provider for analysis.',
                  fr: 'Ce certificat correspond au véhicule sélectionné. J’accepte l’envoi des deux photos au serveur de vérification et au fournisseur IA pour analyse.',
                  ar: 'هذه الشهادة تخص المركبة المختارة. أوافق على إرسال الصورتين إلى خادم التحقق ومزود الذكاء الاصطناعي للتحليل.'))),
          if (BackendClient.enabled)
            Text(context.tr(
                en: 'Continue after adding your documents. AI analysis runs after submission; an outage leaves your application pending for review.',
                fr: 'Continuez après avoir ajouté vos documents. L’analyse IA suit l’envoi ; une panne laisse votre candidature en attente d’examen.',
                ar: 'تابع بعد إضافة الوثائق. يبدأ تحليل الذكاء الاصطناعي بعد الإرسال، ويبقى الطلب قيد المراجعة عند التعطل.')),
          if (!BackendClient.enabled)
            FilledButton.icon(
                onPressed: _busy ? null : _verify,
                icon: const Icon(Icons.fact_check_outlined),
                label: Text(context.tr(
                    en: 'Verify with AI',
                    fr: 'Vérifier avec l’IA',
                    ar: 'التحقق بالذكاء الاصطناعي'))),
          if (_busy) const LinearProgressIndicator(),
          if (_result != null) ...[
            Text(_result!.passed
                ? context.tr(
                    en: 'Capacity check passed. You may continue.',
                    fr: 'Contrôle de capacité réussi. Vous pouvez continuer.',
                    ar: 'نجح فحص السعة. يمكنك المتابعة.')
                : _result!.status == 'rejected'
                    ? context.tr(
                        en:
                            'Capacity check rejected. Correct your capacity or document.',
                        fr:
                            'Contrôle refusé. Corrigez la capacité ou le document.',
                        ar: 'تم رفض الفحص. صحح السعة أو الوثيقة.')
                    : context.tr(
                        en: 'Verification inconclusive. Provide clearer photos; Continue is blocked.',
                        fr: 'Vérification incertaine. Fournissez des photos plus nettes ; Continuer reste bloqué.',
                        ar: 'التحقق غير حاسم. قدم صورًا أوضح؛ المتابعة محظورة.')),
            if (_result!.payloadKg != null)
              Text(_result!.reason == 'declared_load_exceeds_payload'
                  ? context.tr(
                      en:
                          'Declared capacity plus occupants/equipment exceeds the document limit. Go back and reduce the capacity.',
                      fr:
                          'La capacité déclarée et les occupants/équipements dépassent la limite documentée. Revenez en arrière et réduisez la capacité.',
                      ar:
                          'السعة المعلنة مع الركاب والمعدات تتجاوز الحد الموثق. ارجع وخفض السعة.')
                  : _result!.reason == 'vehicle_type_mismatch'
                      ? context.tr(
                          en: 'The certificate vehicle type differs from your selection.',
                          fr: 'Le type de véhicule du certificat diffère de votre sélection.',
                          ar: 'نوع المركبة في الشهادة يختلف عن اختيارك.')
                      : ''),
            if (_result!.reason == 'duplicate_sides')
              Text(context.tr(
                  en: 'The same image was supplied twice. Add the front and the back.',
                  fr: 'La même image a été fournie deux fois. Ajoutez le recto et le verso.',
                  ar: 'تم إرسال الصورة نفسها مرتين. أضف الوجه الأمامي والخلفي.')),
            if (_result!.payloadKg != null)
              Text(context.tr(
                  en: 'Documented payload: ${_result!.payloadKg} kg',
                  fr: 'Charge utile documentée : ${_result!.payloadKg} kg',
                  ar: 'الحمولة الموثقة: ${_result!.payloadKg} كغ')),
            if (_result!.passed)
              Text('${_result!.brand} ${_result!.model} · ${_result!.year}'),
          ],
          if (_error != null)
            Text(
                _error == 'configuration'
                    ? context.tr(
                        en:
                            'The online verification service has not been configured. Continue is blocked.',
                        fr:
                            'Le service de vérification en ligne n’est pas configuré. Continuer reste bloqué.',
                        ar:
                            'لم يتم إعداد خدمة التحقق عبر الإنترنت. المتابعة محظورة.')
                    : _error == 'required'
                        ? context.tr(
                            en:
                                'Add both photos, enter a valid weight and confirm consent.',
                            fr:
                                'Ajoutez les deux photos, saisissez un poids valide et confirmez votre accord.',
                            ar: 'أضف الصورتين وأدخل وزنًا صحيحًا وأكد موافقتك.')
                        : context.tr(
                            en: 'Verification unavailable. Check the connection or photo permissions and retry.',
                            fr: 'Vérification indisponible. Vérifiez la connexion ou les autorisations photo et réessayez.',
                            ar: 'التحقق غير متاح. تحقق من الاتصال أو أذونات الصور وحاول مجددًا.'),
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 12),
          Text(context.tr(
              en: 'Passing checks document data and load consistency, not authenticity. Final administrator approval remains required.',
              fr: 'La réussite vérifie les données et la cohérence de la charge, pas l’authenticité. La validation finale de l’administrateur reste requise.',
              ar: 'النجاح يفحص بيانات الوثيقة وتوافق الحمولة، ولا يثبت الأصالة. تبقى الموافقة النهائية للمسؤول مطلوبة.')),
        ],
      );
}
