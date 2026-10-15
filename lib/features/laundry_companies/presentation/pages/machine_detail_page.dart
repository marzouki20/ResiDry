import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/machine.dart';
import '../widgets/programme_selector_sheet.dart';

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
    if (isRunning) {
      final updated = _machine.copyWith(
        statut: 'Disponible',
        progressionCycle: 0.0,
        tempsRestantMinutes: 0,
        programmeActuel: null,
      );

      setState(() => _machine = updated);
      widget.onMachineUpdated(updated);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cycle arrêté avec succès. Machine disponible.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ProgrammeSelectorSheet(
          machine: _machine,
          onProgrammeSelected: (programme) {
            final nouvelleConso = _machine.consommationKwh + programme.consommationKwh;
            final updated = _machine.copyWith(
              statut: 'En cycle',
              progressionCycle: 0.1,
              tempsRestantMinutes: programme.dureeMinutes,
              temperatureC: programme.temperatureC,
              consommationKwh: double.parse(nouvelleConso.toStringAsFixed(2)),
              programmeActuel: programme.nom,
            );

            setState(() => _machine = updated);
            widget.onMachineUpdated(updated);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Programme "${programme.nom}" lancé ! (+${programme.consommationKwh} kWh)'),
                backgroundColor: programme.couleur,
              ),
            );
          },
        ),
      );
    }
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
                              '${_machine.type} • Capacité: ${_machine.capaciteKg.toStringAsFixed(0)} kg • ID: ${_machine.id}',
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
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.tune_rounded, size: 16, color: AppColors.cyan),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Programme actif : ${_machine.programmeActuel ?? "Standard"}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
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
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRunning ? Colors.amber.shade900 : AppColors.navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _toggleCycle,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              isRunning ? 'Interrompre le cycle' : 'Démarrer le cycle de lavage',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
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
