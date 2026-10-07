import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'driver_interface.dart';

class DriverOnboardingPage extends StatefulWidget {
  const DriverOnboardingPage({super.key, required this.userName});

  final String userName;

  @override
  State<DriverOnboardingPage> createState() => _DriverOnboardingPageState();
}

class _DriverOnboardingPageState extends State<DriverOnboardingPage> {
  int _currentStep = 0;
  String _selectedVehicle = 'Moto';
  double _capacityKg = 25.0;
  String _selectedZone = 'Centre-Ville';
  bool _gpsPermissionGranted = false;
  bool _isSubmitting = false;

  final List<String> _vehicles = ['Moto', 'Voiture', 'Vélo', 'Camionnette'];
  final List<String> _zones = [
    'Centre-Ville',
    'Zone Nord',
    'Zone Sud',
    'Zone Est',
    'Zone Ouest',
    'Métropole Complète'
  ];

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      if (!_gpsPermissionGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'L’activation de la géolocalisation est obligatoire pour exercer en tant que livreur.',
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

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
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
      const SnackBar(
        content: Text('GPS activé avec succès · Position initiale enregistrée.'),
        backgroundColor: AppColors.cyan,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _finishOnboarding() async {
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    setState(() => _isSubmitting = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => DriverInterface(userName: widget.userName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    IconButton(
                      onPressed: _previousStep,
                      icon: const Icon(Icons.arrow_back_rounded),
                    )
                  else
                    const SizedBox(width: 40),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Configuration Livreur (${_currentStep + 1}/3)',
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: (_currentStep + 1) / 3,
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentStep == 2 && !_gpsPermissionGranted
                      ? Colors.grey.shade400
                      : AppColors.navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isSubmitting ? null : _nextStep,
                child: Text(
                  _isSubmitting
                      ? 'Enregistrement...'
                      : _currentStep == 2
                          ? 'Terminer & Commencer'
                          : 'Continuer',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          key: const ValueKey('step-0'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.directions_car_rounded, color: AppColors.cyan, size: 28),
                SizedBox(width: 12),
                Text(
                  'Type de véhicule',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Sélectionnez votre moyen de transport principal pour optimiser vos tournées de livraison et de collecte.',
              style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            ..._vehicles.map((vehicle) {
              final selected = _selectedVehicle == vehicle;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => setState(() => _selectedVehicle = vehicle),
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
                          child: Text(
                            vehicle,
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
            Text(
              'Capacité maximale (kg): ${_capacityKg.toStringAsFixed(0)} kg',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
                fontSize: 14,
              ),
            ),
            Slider(
              value: _capacityKg,
              min: 5,
              max: 200,
              divisions: 39,
              activeColor: AppColors.cyan,
              label: '${_capacityKg.toStringAsFixed(0)} kg',
              onChanged: (val) => setState(() => _capacityKg = val),
            ),
          ],
        );

      case 1:
        return Column(
          key: const ValueKey('step-1'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.map_rounded, color: AppColors.cyan, size: 28),
                SizedBox(width: 12),
                Text(
                  'Zone géographique',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Choisissez votre secteur d’intervention privilégié pour recevoir les missions les plus proches.',
              style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            ..._zones.map((zone) {
              final selected = _selectedZone == zone;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => setState(() => _selectedZone = zone),
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
                        const Icon(Icons.location_on_outlined,
                            color: AppColors.muted),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            zone,
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
          ],
        );

      case 2:
      default:
        return Column(
          key: const ValueKey('step-2'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_searching_rounded, color: AppColors.cyan, size: 28),
                SizedBox(width: 12),
                Text(
                  'Validation & GPS Obligatoire',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Le suivi GPS en temps réel est obligatoire pour recevoir vos missions de collecte et de livraison et interagir avec les casiers IoT.',
              style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
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
                  const Text(
                    'Récapitulatif de votre profil',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('• Nom : ${widget.userName}'),
                  Text('• Véhicule : $_selectedVehicle (${_capacityKg.toStringAsFixed(0)} kg)'),
                  Text('• Zone : $_selectedZone'),
                  const Text('• Statut : Actif (En attente GPS)'),
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
                  label: const Text(
                    'Activer la géolocalisation requise',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.green),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Géolocalisation activée & Position enregistrée (Table position_livreur).',
                        style: TextStyle(
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
}
