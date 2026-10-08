import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/machine.dart';

class MachineDetailPage extends StatefulWidget {
  const MachineDetailPage({
    super.key,
    required this.machine,
    required this.onMachineUpdated,
  });

  final Machine machine;
  final ValueChanged<Machine> onMachineUpdated;

  @override
  State<MachineDetailPage> createState() => _MachineDetailPageState();
}

class _MachineDetailPageState extends State<MachineDetailPage> {
  late Machine _machine;

  @override
  void initState() {
    super.initState();
    _machine = widget.machine;
  }

  void _toggleCycle() {
    final isRunning = _machine.statut == 'En cycle';
    final updatedStatut = isRunning ? 'Disponible' : 'En cycle';
    final updatedProgress = isRunning ? 0.0 : 0.35;
    final updatedTime = isRunning ? 0 : 40;

    final updated = _machine.copyWith(
      statut: updatedStatut,
      progressionCycle: updatedProgress,
      tempsRestantMinutes: updatedTime,
    );

    setState(() => _machine = updated);
    widget.onMachineUpdated(updated);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isRunning
              ? 'Cycle arrêté avec succès.'
              : 'Nouveau cycle lancé (40 min).',
        ),
        backgroundColor: AppColors.navy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = _machine.statut == 'En cycle';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _machine.nom,
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Machine Status Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _machine.type == 'Sèche-linge'
                              ? Icons.air_rounded
                              : Icons.local_laundry_service_rounded,
                          color: AppColors.navy,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _machine.nom,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.navy,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Type: ${_machine.type} • ID: ${_machine.id}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isRunning
                              ? AppColors.cyan.withValues(alpha: 0.15)
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _machine.statut,
                          style: TextStyle(
                            color: isRunning ? AppColors.navy : Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isRunning) ...[
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Progression du cycle actuel',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy,
                          ),
                        ),
                        Text(
                          '${(_machine.progressionCycle * 100).toInt()}% (${_machine.tempsRestantMinutes} min restantes)',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cyan,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _machine.progressionCycle,
                        minHeight: 10,
                        backgroundColor: AppColors.line,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // IoT Live Sensors Dashboard
            const Text(
              'Télémétrie IoT & Capteurs',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: [
                _sensorCard(
                  'Température',
                  '${_machine.temperatureC.toStringAsFixed(1)} °C',
                  Icons.device_thermostat_rounded,
                  Colors.orange.shade700,
                ),
                _sensorCard(
                  'Vibration',
                  '${_machine.vibrationLevel.toStringAsFixed(1)} m/s²',
                  Icons.vibration_rounded,
                  Colors.indigo.shade600,
                ),
                _sensorCard(
                  'Énergie (kWh)',
                  '${_machine.consommationKwh.toStringAsFixed(1)} kWh',
                  Icons.bolt_rounded,
                  Colors.amber.shade800,
                ),
                _sensorCard(
                  'Santé IoT',
                  '${_machine.santeIot}%',
                  Icons.monitor_heart_rounded,
                  Colors.green.shade700,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Controls section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Commandes à distance (IoT)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Envoyez des instructions directement à l’équipement connecté.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRunning ? Colors.amber.shade900 : AppColors.navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _toggleCycle,
                      icon: Icon(
                        isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      ),
                      label: Text(
                        isRunning ? 'Interrompre le cycle' : 'Démarrer le cycle de lavage',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sensorCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
