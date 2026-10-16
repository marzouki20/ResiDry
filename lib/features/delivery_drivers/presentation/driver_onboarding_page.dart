import 'package:flutter/material.dart';
import '../../../models/user.dart';

import '../../../core/localization/localized_text.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/app_locale.dart';
import '../../../core/theme/app_theme.dart';
import 'driver_interface.dart';
import '../domain/tunisia_governorates.dart';
import '../data/driver_profile_repository.dart';
import '../../auth/presentation/widgets/sign_out_button.dart';
import '../domain/vehicle_capacity_evidence.dart';
import 'widgets/registration_certificate_panel.dart';
import 'widgets/driver_documents_panel.dart';
import 'widgets/vehicle_photo_panel.dart';
import '../../../core/backend/backend_client.dart';
import 'dart:convert';
import 'dart:io';

class DriverOnboardingPage extends StatefulWidget {
  const DriverOnboardingPage(
      {super.key,
      required this.userName,
      this.userEmail,
      this.currentUser,
      this.profileRepository,
      this.initialVehicle = 'Moto',
      this.initialCapacity = 40,
      this.initialEvidence,
      this.initialZones = const {}});

  final String userName;
  final String? userEmail;
  final User? currentUser;
  final DriverProfileRepository? profileRepository;
  final String initialVehicle;
  final double initialCapacity;
  final VehicleCapacityEvidence? initialEvidence;
  final Set<String> initialZones;

  @override
  State<DriverOnboardingPage> createState() => _DriverOnboardingPageState();
}

class _DriverOnboardingPageState extends State<DriverOnboardingPage> {
  int _currentStep = 0;
  late String _selectedVehicle = widget.initialVehicle;
  late double _capacityKg = widget.initialCapacity;
  late final TextEditingController _capacityController =
      TextEditingController(text: _formatCapacity(_capacityKg));
  String? _capacityError;
  late final Set<String> _selectedZones = Set.of(widget.initialZones);
  bool _zoneError = false;
  bool _gpsPermissionGranted = false;
  bool _isSubmitting = false;
  bool _readingEvidence = false;
  late VehicleCapacityEvidence? _evidence = widget.initialEvidence;

  final List<String> _vehicles = ['Moto', 'Voiture', 'Vélo', 'Camionnette'];
  bool get _lightVehicle => _selectedVehicle == 'Vélo';
  bool get _evidenceReady => BackendClient.enabled
      ? (_lightVehicle
          ? _evidence?.ownerConfirmed == true &&
              _evidence?.supportingPaths['VEHICLE_PHOTO']?.isNotEmpty == true &&
              (_selectedVehicle != 'Moto' ||
                  _evidence?.source == 'vehicle_photo_camera')
          : _evidence?.ownerConfirmed == true &&
              _evidence?.hasValidReserve == true &&
              _evidence?.verificationId != null &&
              _evidence?.verifiedCapacity == _capacityKg &&
              _evidence?.verifiedVehicle == _selectedVehicle &&
              (_selectedVehicle != 'Moto' ||
                  (_evidence?.vehiclePhotoSource == 'camera' &&
                      _evidence?.supportingPaths['VEHICLE_PHOTO']?.isNotEmpty ==
                          true)))
      : _evidence?.source == 'registration' &&
          _evidence?.backImagePath.isNotEmpty == true &&
          _evidence?.assess(_capacityKg) == CapacityAssessment.consistent;
  static const Map<String, double> _recommendedCapacities = {
    'Vélo': 15,
    'Moto': 40,
    'Voiture': 100,
    'Camionnette': 500,
  };
  void _nextStep() {
    FocusScope.of(context).unfocus();
    if (_currentStep == 0 && !_validateCapacity()) return;
    if (_currentStep == 1 && !_evidenceReady) {
      return;
    }
    if (_currentStep == 2 && _selectedZones.isEmpty) {
      setState(() => _zoneError = true);
      return;
    }
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      if (!_gpsPermissionGranted && !BackendClient.enabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: LocalizedText(
              context.tr(
                en: 'Location access is required to work as a driver.',
                fr: 'L’activation de la géolocalisation est obligatoire pour exercer en tant que livreur.',
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      _finishOnboarding();
    }
  }

  @override
  void dispose() {
    _capacityController.dispose();
    super.dispose();
  }

  void _selectVehicle(String vehicle) {
    final recommendedCapacity = _recommendedCapacities[vehicle]!;
    setState(() {
      _selectedVehicle = vehicle;
      _capacityKg = recommendedCapacity;
      _capacityController.text = _formatCapacity(recommendedCapacity);
      _capacityError = null;
      _evidence = null;
    });
  }

  void _updateCapacity(String value) {
    final capacity = double.tryParse(value.replaceAll(',', '.'));
    setState(() {
      if (capacity != null) _capacityKg = capacity;
      _capacityError = null;
      _evidence = null;
    });
  }

  bool _validateCapacity() {
    final capacity =
        double.tryParse(_capacityController.text.trim().replaceAll(',', '.'));
    final error = capacity == null || !capacity.isFinite || capacity <= 0
        ? context.tr(
            en: 'Enter a capacity greater than 0 kg.',
            fr: 'Saisissez une capacité supérieure à 0 kg.',
            ar: 'أدخل سعة أكبر من 0 كغ.',
          )
        : (_selectedVehicle == 'Moto' && capacity > 60) ||
                (_selectedVehicle == 'Vélo' && capacity > 20)
            ? context.tr(
                en: 'Maximum laundry capacity: ${_selectedVehicle == "Moto" ? 60 : 20} kg.',
                fr: 'Capacité maximale de linge : ${_selectedVehicle == "Moto" ? 60 : 20} kg.',
                ar: 'الحد الأقصى للغسيل: ${_selectedVehicle == "Moto" ? 60 : 20} كغ.')
            : capacity > 10000
                ? context.tr(
                    en: 'The maximum supported capacity is 10,000 kg.',
                    fr: 'La capacité maximale prise en charge est de 10 000 kg.',
                    ar: 'الحد الأقصى المدعوم للسعة هو 10000 كغ.',
                  )
                : null;
    setState(() {
      _capacityError = error;
      if (capacity != null && error == null) _capacityKg = capacity;
    });
    return error == null;
  }

  static String _formatCapacity(double capacity) =>
      capacity == capacity.roundToDouble()
          ? capacity.toStringAsFixed(0)
          : capacity.toStringAsFixed(1);

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        confirmSignOut(context);
      }
    }
  }

  Future<void> _requestGpsPermission() async {
    // Simulate professional native GPS permission request and initial position logging (Table: position_livreur)
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _gpsPermissionGranted = true;
      _isSubmitting = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: LocalizedText(context.tr(
          en: 'GPS enabled successfully · Initial position saved.',
          fr: 'GPS activé avec succès · Position initiale enregistrée.',
        )),
        backgroundColor: AppColors.cyan,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _finishOnboarding() async {
    setState(() => _isSubmitting = true);
    try {
      if (BackendClient.enabled) {
        final evidence = _evidence!;
        await BackendClient
            .request('/api/driver/application/submit', method: 'POST', body: {
          'vehicleType': _selectedVehicle,
          'declaredKg': _capacityKg,
          'reserveKg': evidence.reserveKg,
          'zones': _selectedZones.toList(),
          'consent': evidence.ownerConfirmed,
          ...await _supportingDocuments(evidence),
          'front': evidence.imagePath.isEmpty
              ? null
              : base64Encode(await File(evidence.imagePath).readAsBytes()),
          'back': evidence.backImagePath.isEmpty
              ? null
              : base64Encode(await File(evidence.backImagePath).readAsBytes()),
        });
        if (mounted) Navigator.of(context).pop(true);
        return;
      }
      if (widget.userEmail == null) throw StateError('Missing account email');
      await (widget.profileRepository ?? DriverProfileRepository()).save(
          email: widget.userEmail!,
          name: widget.userName,
          vehicle: _selectedVehicle,
          capacityKg: _capacityKg,
          evidence: _evidence,
          governorateCodes: _selectedZones);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
              builder: (_) => DriverInterface(
                  currentUser: widget.currentUser,
                  userName: widget.userName, userEmail: widget.userEmail)),
          (_) => false);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.tr(
                en: 'Could not save your profile. Please try again.',
                fr: 'Impossible d’enregistrer votre profil. Réessayez.',
                ar: 'تعذر حفظ ملفك. أعد المحاولة.'))));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<Map<String, dynamic>> _supportingDocuments(
      VehicleCapacityEvidence evidence) async {
    final result = <String, dynamic>{
      'borrowed': evidence.borrowed,
      'vehiclePhotoSource': evidence.vehiclePhotoSource.isNotEmpty
          ? evidence.vehiclePhotoSource
          : evidence.source == 'vehicle_photo_camera'
              ? 'camera'
              : evidence.source == 'vehicle_photo_gallery'
                  ? 'gallery'
                  : null,
      'verificationId': evidence.verificationId
    };
    const fields = {
      'LICENSE_FRONT': 'licenseFront',
      'LICENSE_BACK': 'licenseBack',
      'INSURANCE': 'insurance',
      'TECHNICAL_INSPECTION': 'technicalInspection',
      'VEHICLE_PHOTO': 'vehiclePhoto',
      'AUTHORIZATION': 'authorization'
    };
    for (final entry in fields.entries) {
      final path = evidence.supportingPaths[entry.key];
      if (path != null && path.isNotEmpty) {
        result[entry.value] = base64Encode(await File(path).readAsBytes());
      }
    }
    return result;
  }

  Future<void> _saveDraft() async {
    if (!_validateCapacity()) return;
    setState(() => _isSubmitting = true);
    try {
      final evidence = _evidence;
      await BackendClient
          .request('/api/driver/application/draft', method: 'PUT', body: {
        'vehicleType': _selectedVehicle,
        'declaredKg': _capacityKg,
        'reserveKg': evidence?.reserveKg ?? 0,
        'zones': _selectedZones.toList(),
        'consent': evidence?.ownerConfirmed ?? false,
        if (evidence != null && evidence.ownerConfirmed)
          ...await _supportingDocuments(evidence),
        'front': evidence == null ||
                !evidence.ownerConfirmed ||
                evidence.imagePath.isEmpty
            ? null
            : base64Encode(await File(evidence.imagePath).readAsBytes()),
        'back': evidence == null ||
                !evidence.ownerConfirmed ||
                evidence.backImagePath.isEmpty
            ? null
            : base64Encode(await File(evidence.backImagePath).readAsBytes()),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.tr(
                en: 'Could not save your draft. Check the connection and retry.',
                fr: 'Impossible d’enregistrer le brouillon. Vérifiez la connexion et réessayez.',
                ar: 'تعذر حفظ المسودة. تحقق من الاتصال وحاول مجددًا.'))));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && !_isSubmitting && !_readingEvidence) _previousStep();
        },
        child: Scaffold(
          backgroundColor: AppColors.canvas,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip:
                            context.tr(en: 'Back', fr: 'Retour', ar: 'رجوع'),
                        onPressed: _isSubmitting || _readingEvidence
                            ? null
                            : _previousStep,
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            LocalizedText(
                              '${context.tr(en: 'Driver setup', fr: 'Configuration Livreur')} (${_currentStep + 1}/4)',
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: (_currentStep + 1) / 4,
                              backgroundColor: AppColors.line,
                              color: AppColors.cyan,
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: AppColors.line),
                        ),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _buildStepContent(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                  child: Column(children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _currentStep == 3 && !_gpsPermissionGranted
                                ? Colors.grey.shade400
                                : AppColors.navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isSubmitting ||
                              _readingEvidence ||
                              (_currentStep == 1 && !_evidenceReady)
                          ? null
                          : _nextStep,
                      child: LocalizedText(
                        _isSubmitting
                            ? context.tr(
                                en: 'Saving...', fr: 'Enregistrement...')
                            : _currentStep == 3 && BackendClient.enabled
                                ? context.tr(
                                    en: 'Submit my application',
                                    fr: 'Envoyer ma candidature',
                                    ar: 'إرسال طلبي')
                                : _currentStep == 3
                                    ? context.tr(
                                        en: 'Finish and start',
                                        fr: 'Terminer & Commencer',
                                      )
                                    : context.tr(
                                        en: 'Continue', fr: 'Continuer'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (BackendClient.enabled)
                      TextButton(
                          onPressed: _isSubmitting || _readingEvidence
                              ? null
                              : _saveDraft,
                          child: Text(context.tr(
                              en: 'Save draft and return',
                              fr: 'Enregistrer le brouillon et revenir',
                              ar: 'حفظ المسودة والعودة'))),
                  ]),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          key: const ValueKey('step-0'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_car_rounded,
                    color: AppColors.cyan, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: LocalizedText(
                    context.tr(en: 'Vehicle type', fr: 'Type de véhicule'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LocalizedText(
              context.tr(
                en: 'Select your main vehicle for collection and delivery rounds.',
                fr: 'Sélectionnez votre moyen de transport principal pour optimiser vos tournées de livraison et de collecte.',
              ),
              style: const TextStyle(
                  color: AppColors.muted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            ..._vehicles.map((vehicle) {
              final selected = _selectedVehicle == vehicle;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _selectVehicle(vehicle),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.cyan.withValues(alpha: 0.12)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? AppColors.cyan : AppColors.line,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          vehicle == 'Moto'
                              ? Icons.two_wheeler_rounded
                              : vehicle == 'Voiture'
                                  ? Icons.directions_car_rounded
                                  : vehicle == 'Vélo'
                                      ? Icons.pedal_bike_rounded
                                      : Icons.local_shipping_rounded,
                          color: selected ? AppColors.navy : AppColors.muted,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: LocalizedText(
                            _vehicleLabel(context, vehicle),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                        if (selected)
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.cyan),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            LocalizedText(
              context.tr(
                en: 'Maximum carrying capacity',
                fr: 'Capacité de charge maximale',
                ar: 'سعة الحمولة القصوى',
              ),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const ValueKey('capacity-field'),
              controller: _capacityController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d{0,5}([.,]\d{0,1})?')),
              ],
              onChanged: _updateCapacity,
              decoration: InputDecoration(
                hintText: context.tr(
                  en: 'Enter the real vehicle capacity',
                  fr: 'Saisissez la capacité réelle du véhicule',
                  ar: 'أدخل السعة الفعلية للمركبة',
                ),
                suffixText: 'kg',
                errorText: _capacityError,
                prefixIcon: const Icon(Icons.scale_outlined),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
              ),
            ),
            const SizedBox(height: 8),
            LocalizedText(
              context.tr(
                en: 'Suggested for ${_vehicleLabel(context, _selectedVehicle)}: ${_formatCapacity(_recommendedCapacities[_selectedVehicle]!)} kg. You can enter the certified capacity of your vehicle.',
                fr: 'Suggestion pour ${_vehicleLabel(context, _selectedVehicle)} : ${_formatCapacity(_recommendedCapacities[_selectedVehicle]!)} kg. Vous pouvez saisir la capacité certifiée de votre véhicule.',
                ar: 'السعة المقترحة لـ ${_vehicleLabel(context, _selectedVehicle)}: ${_formatCapacity(_recommendedCapacities[_selectedVehicle]!)} كغ. يمكنك إدخال السعة المعتمدة لمركبتك.',
              ),
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        );

      case 1:
        if (BackendClient.enabled && _lightVehicle) {
          return VehiclePhotoPanel(
              key: ValueKey('vehicle-photo-$_selectedVehicle'),
              vehicle: _selectedVehicle,
              initialEvidence: _evidence,
              onChanged: (value) => setState(() => _evidence = value),
              onBusyChanged: (value) =>
                  setState(() => _readingEvidence = value));
        }
        if (BackendClient.enabled && _selectedVehicle != 'Vélo') {
          return DriverDocumentsPanel(
              key: ValueKey('documents-$_selectedVehicle-$_capacityKg'),
              vehicleType: _selectedVehicle,
              declaredKg: _capacityKg,
              initialEvidence: _evidence,
              onChanged: (value) => setState(() => _evidence = value),
              onBusyChanged: (value) =>
                  setState(() => _readingEvidence = value));
        }
        return RegistrationCertificatePanel(
            key: ValueKey('registration-$_selectedVehicle-$_capacityKg'),
            vehicleType: _selectedVehicle,
            declaredKg: _capacityKg,
            initialEvidence: _evidence,
            onChanged: (value) => setState(() => _evidence = value),
            onBusyChanged: (value) => setState(() => _readingEvidence = value));
      case 2:
        return Column(
          key: const ValueKey('step-1'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.map_rounded, color: AppColors.cyan, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: LocalizedText(
                    context.tr(en: 'Service area', fr: 'Zone géographique'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LocalizedText(
              context.tr(
                en: 'Select one or more governorates where you can deliver.',
                fr: 'Sélectionnez une ou plusieurs régions où vous pouvez livrer.',
                ar: 'اختر ولاية أو أكثر يمكنك التوصيل فيها.',
              ),
              style: const TextStyle(
                  color: AppColors.muted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            Text(context.tr(
                en: '${_selectedZones.length} / 24 selected',
                fr: '${_selectedZones.length} / 24 sélectionnées',
                ar: '${_selectedZones.length} / 24 مختارة')),
            if (_zoneError)
              Text(
                  context.tr(
                      en: 'Select at least one governorate.',
                      fr: 'Sélectionnez au moins une région.',
                      ar: 'اختر ولاية واحدة على الأقل.'),
                  style: const TextStyle(color: Colors.red)),
            Wrap(spacing: 8, children: [
              TextButton(
                  onPressed: () => setState(() {
                        _selectedZones
                            .addAll(tunisiaGovernorates.map((g) => g.code));
                        _zoneError = false;
                      }),
                  child: Text(context.tr(
                      en: 'Select all',
                      fr: 'Tout sélectionner',
                      ar: 'اختيار الكل'))),
              TextButton(
                  onPressed: () => setState(() => _selectedZones.clear()),
                  child: Text(context.tr(
                      en: 'Clear selection',
                      fr: 'Effacer la sélection',
                      ar: 'مسح الاختيار'))),
            ]),
            ...tunisiaGovernorates.map((zone) => CheckboxListTile(
                  key: ValueKey('governorate-${zone.code}'),
                  title: Text(zone.label(context)),
                  value: _selectedZones.contains(zone.code),
                  onChanged: (selected) => setState(() {
                    if (selected == true) {
                      _selectedZones.add(zone.code);
                    } else {
                      _selectedZones.remove(zone.code);
                    }
                    _zoneError = false;
                  }),
                  activeColor: AppColors.cyan,
                  contentPadding: EdgeInsets.zero,
                )),
          ],
        );

      default:
        if (BackendClient.enabled) {
          return Column(
              key: const ValueKey('application-summary'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                    context.tr(
                        en: 'Application summary',
                        fr: 'Résumé de candidature',
                        ar: 'ملخص الطلب'),
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Text(
                    '${widget.userName}\n${_vehicleLabel(context, _selectedVehicle)} · $_capacityKg kg'),
                Text(tunisiaGovernorates
                    .where((zone) => _selectedZones.contains(zone.code))
                    .map((zone) => zone.label(context))
                    .join(', ')),
                const SizedBox(height: 16),
                Text(context.tr(
                    en: 'Submit your dossier for review. You will be able to follow its status and respond to requests for corrections. Deliveries remain unavailable until approval.',
                    fr: 'Envoyez votre dossier pour examen. Vous pourrez suivre son statut et répondre aux demandes de correction. Les livraisons restent indisponibles jusqu’à approbation.',
                    ar: 'أرسل ملفك للمراجعة. يمكنك متابعة حالته والرد على طلبات التصحيح. تبقى مهام التوصيل غير متاحة حتى الموافقة.')),
              ]);
        }
        return Column(
          key: const ValueKey('step-2'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_searching_rounded,
                    color: AppColors.cyan, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: LocalizedText(
                    context.tr(
                      en: 'Confirmation and required GPS',
                      fr: 'Validation & GPS Obligatoire',
                    ),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LocalizedText(
              context.tr(
                en: 'Real-time GPS is required to receive missions and interact with IoT lockers.',
                fr: 'Le suivi GPS en temps réel est obligatoire pour recevoir vos missions de collecte et de livraison et interagir avec les casiers IoT.',
              ),
              style: const TextStyle(
                  color: AppColors.muted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    context.tr(
                        en: 'Profile summary',
                        fr: 'Récapitulatif de votre profil'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LocalizedText(
                      '• ${context.tr(en: 'Name', fr: 'Nom')} : ${widget.userName}'),
                  LocalizedText(
                      '• ${context.tr(en: 'Vehicle', fr: 'Véhicule')} : ${_vehicleLabel(context, _selectedVehicle)} (${_capacityKg.toStringAsFixed(0)} kg)'),
                  LocalizedText(
                      '• ${context.tr(en: 'Area', fr: 'Zone')} : ${tunisiaGovernorates.where((g) => _selectedZones.contains(g.code)).map((g) => g.label(context)).join(', ')}'),
                  LocalizedText(
                      '• ${context.tr(en: 'Status: Active (waiting for GPS)', fr: 'Statut : Actif (En attente GPS)')}'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (!_gpsPermissionGranted)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _requestGpsPermission,
                  icon: const Icon(Icons.gps_fixed_rounded),
                  label: LocalizedText(
                    context.tr(
                      en: 'Enable required location access',
                      fr: 'Activer la géolocalisation requise',
                    ),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LocalizedText(
                        context.tr(
                          en: 'Location enabled and position saved.',
                          fr: 'Géolocalisation activée & Position enregistrée.',
                        ),
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
    }
  }

  String _vehicleLabel(BuildContext context, String vehicle) =>
      switch (vehicle) {
        'Moto' => context.tr(en: 'Motorcycle', fr: 'Moto', ar: 'دراجة نارية'),
        'Voiture' => context.tr(en: 'Car', fr: 'Voiture', ar: 'سيارة'),
        'Vélo' => context.tr(en: 'Bicycle', fr: 'Vélo', ar: 'دراجة هوائية'),
        'Camionnette' =>
          context.tr(en: 'Van', fr: 'Camionnette', ar: 'شاحنة صغيرة'),
        _ => vehicle,
      };
}
