import 'package:flutter/material.dart';
import '../../../core/backend/backend_client.dart';
import '../../../core/localization/app_locale.dart';
import '../../auth/presentation/widgets/sign_out_button.dart';
import 'driver_onboarding_page.dart';
import '../domain/vehicle_capacity_evidence.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

String applicationStatusLabel(BuildContext context, String status) =>
    switch (status) {
      'DRAFT' => context.tr(en: 'Draft', fr: 'Brouillon', ar: 'مسودة'),
      'SUBMITTED' =>
        context.tr(en: 'Submitted', fr: 'Dossier transmis', ar: 'تم الإرسال'),
      'UNDER_REVIEW' => context.tr(
          en: 'Under review', fr: 'En cours d’examen', ar: 'قيد المراجعة'),
      'CORRECTION_REQUESTED' => context.tr(
          en: 'Correction requested',
          fr: 'Correction demandée',
          ar: 'مطلوب تصحيح'),
      'APPROVED' =>
        context.tr(en: 'Approved', fr: 'Approuvé', ar: 'تمت الموافقة'),
      'REJECTED' => context.tr(en: 'Rejected', fr: 'Refusé', ar: 'مرفوض'),
      _ => context.tr(
          en: 'Not submitted', fr: 'Non transmis', ar: 'لم يتم الإرسال'),
    };

class ApplicationStatusScreen extends StatefulWidget {
  const ApplicationStatusScreen({super.key});
  @override
  State<ApplicationStatusScreen> createState() =>
      _ApplicationStatusScreenState();
}

class _ApplicationStatusScreenState extends State<ApplicationStatusScreen> {
  Map<String, dynamic>? _application;
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
      final value = await BackendClient.request('/api/driver/application')
          as Map<String, dynamic>;
      if (mounted) setState(() => _application = value);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit() async {
    final account = BackendClient.account!;
    Directory? directory;
    VehicleCapacityEvidence? evidence;
    try {
      if (_application?['has_front'] == true ||
          _application?['has_back'] == true ||
          (_application?['document_slots'] as List? ?? [])
              .contains('VEHICLE_PHOTO')) {
        directory = await Directory(
                '${(await getTemporaryDirectory()).path}/application-${DateTime.now().microsecondsSinceEpoch}')
            .create();
        var front = '', back = '';
        if (_application?['has_front'] == true) {
          front = (await File('${directory.path}/front.jpg').writeAsBytes(
                  await BackendClient.document(
                      '/api/driver/application/documents/FRONT')))
              .path;
        }
        if (_application?['has_back'] == true) {
          back = (await File('${directory.path}/back.jpg').writeAsBytes(
                  await BackendClient.document(
                      '/api/driver/application/documents/BACK')))
              .path;
        }
        final supporting = <String, String>{};
        for (final slot in (_application?['document_slots'] as List? ?? [])) {
          if (slot == 'FRONT' || slot == 'BACK') continue;
          supporting[slot as String] =
              (await File('${directory.path}/$slot.jpg').writeAsBytes(
                      await BackendClient.document(
                          '/api/driver/application/documents/$slot')))
                  .path;
        }
        evidence = VehicleCapacityEvidence(
            supportingPaths: supporting,
            vehiclePhotoSource:
                _application?['vehicle_photo_source'] as String? ?? '',
            borrowed: _application?['borrowed'] == true,
            imagePath: front,
            backImagePath: back,
            source: supporting.containsKey('VEHICLE_PHOTO')
                ? 'vehicle_photo_${_application?['vehicle_photo_source'] ?? 'camera'}'
                : 'registration',
            brand: '',
            model: '',
            year: '',
            payloadKg: null,
            reserveKg: (_application?['reserve_kg'] as num?)?.toDouble(),
            ownerConfirmed: _application?['consent'] == true);
      }
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => DriverOnboardingPage(
                userName: account['name'] as String,
                userEmail: account['email'] as String,
                initialEvidence: evidence,
                initialVehicle:
                    _application?['vehicle_type'] as String? ?? 'Moto',
                initialCapacity:
                    (_application?['declared_kg'] as num?)?.toDouble() ?? 40,
                initialZones: ((_application?['zones'] as List?) ?? [])
                    .cast<String>()
                    .toSet(),
              )));
      if (mounted) _load();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (directory != null && await directory.exists()) {
        await directory.delete(recursive: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _application?['status'] as String? ?? 'NOT_STARTED';
    return Scaffold(
      appBar: AppBar(
          title: Text(context.tr(
              en: 'My driver application',
              fr: 'Ma candidature livreur',
              ar: 'طلب الانضمام كسائق')),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => confirmSignOut(context)),
          actions: const [SignOutButton()]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(24), children: [
              if (_failed)
                Text(context.tr(
                    en: 'Could not load your application. Retry.',
                    fr: 'Impossible de charger votre dossier. Réessayez.',
                    ar: 'تعذر تحميل طلبك. حاول مجددًا.')),
              Text(applicationStatusLabel(context, status),
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Text(status == 'APPROVED'
                  ? context.tr(
                      en:
                          'Your application is approved. You will be notified when a delivery is available.',
                      fr:
                          'Votre candidature est approuvée. Vous serez informé lorsqu’une livraison sera disponible.',
                      ar:
                          'تمت الموافقة على طلبك. سيتم إعلامك عند توفر مهمة توصيل.')
                  : context.tr(
                      en: 'Delivery work remains unavailable until your application is approved. Required documents must pass verification before a new submission.',
                      fr: 'Les livraisons restent indisponibles jusqu’à l’approbation de votre dossier. Les documents obligatoires doivent réussir la vérification avant tout nouvel envoi.',
                      ar: 'تبقى مهام التوصيل غير متاحة حتى الموافقة. يجب أن تنجح الوثائق المطلوبة في التحقق قبل إرسال طلب جديد.')),
              if (_application?['review_reason'] != null) ...[
                const SizedBox(height: 16),
                Text(_application!['review_reason'] as String),
              ],
              const SizedBox(height: 20),
              Text(context.tr(
                  en: 'Saving changes requires a fresh review before further delivery work.',
                  fr: 'L’enregistrement de modifications exige un nouvel examen avant de reprendre les livraisons.',
                  ar: 'حفظ التغييرات يتطلب مراجعة جديدة قبل استئناف التوصيل.')),
              FilledButton.icon(
                  onPressed: _edit,
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(context.tr(
                      en: 'Complete or update my application',
                      fr: 'Compléter ou modifier mon dossier',
                      ar: 'إكمال أو تعديل طلبي'))),
              TextButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: Text(context.tr(
                      en: 'Refresh status',
                      fr: 'Actualiser le statut',
                      ar: 'تحديث الحالة'))),
            ]),
    );
  }
}
