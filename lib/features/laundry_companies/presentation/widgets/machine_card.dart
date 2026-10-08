import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/machine.dart';

class MachineCard extends StatelessWidget {
  const MachineCard({
    super.key,
    required this.machine,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleCycle,
  });

  final Machine machine;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleCycle;

  Color get _statusColor {
    switch (machine.statut) {
      case 'Disponible':
        return Colors.green.shade600;
      case 'En cycle':
        return AppColors.cyan;
      case 'Maintenance':
        return Colors.orange.shade700;
      case 'Hors service':
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Machine Icon, Name, Type, Status Badge
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      machine.type == 'Sèche-linge'
                          ? Icons.air_rounded
                          : machine.type == 'Nettoyage Écologique'
                              ? Icons.eco_rounded
                              : Icons.local_laundry_service_rounded,
                      color: _statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          machine.nom,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${machine.type} • ID: ${machine.id}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      machine.statut,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              // Cycle Progress Bar if machine is running
              if (machine.statut == 'En cycle') ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: AppColors.cyan),
                    const SizedBox(width: 6),
                    Text(
                      'Temps restant: ${machine.tempsRestantMinutes} min',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(machine.progressionCycle * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.cyan,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: machine.progressionCycle,
                    minHeight: 6,
                    backgroundColor: AppColors.line,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
                  ),
                ),
              ],

              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.line),
              const SizedBox(height: 10),

              // Telemetry Data (Temp, Vibration, Health IoT)
              Row(
                children: [
                  _telemetryTile(
                    Icons.device_thermostat_rounded,
                    '${machine.temperatureC.toStringAsFixed(1)}°C',
                  ),
                  const SizedBox(width: 12),
                  _telemetryTile(
                    Icons.vibration_rounded,
                    '${machine.vibrationLevel.toStringAsFixed(1)} m/s²',
                  ),
                  const SizedBox(width: 12),
                  _telemetryTile(
                    Icons.monitor_heart_rounded,
                    'IoT ${machine.santeIot}%',
                    color: machine.santeIot >= 90
                        ? Colors.green.shade700
                        : Colors.amber.shade800,
                  ),
                  const Spacer(),

                  // Quick Cycle Start/Stop Button
                  IconButton(
                    tooltip: machine.statut == 'En cycle'
                        ? 'Interrompre cycle'
                        : 'Démarrer cycle',
                    onPressed: onToggleCycle,
                    icon: Icon(
                      machine.statut == 'En cycle'
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                      color: machine.statut == 'En cycle'
                          ? Colors.amber.shade800
                          : AppColors.navy,
                      size: 26,
                    ),
                  ),

                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: AppColors.muted),
                    onSelected: (val) {
                      if (val == 'edit') onEdit();
                      if (val == 'delete') onDelete();
                      if (val == 'details') onTap();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            Icon(Icons.remove_red_eye_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Détails IoT'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                            SizedBox(width: 8),
                            Text('Supprimer', style: TextStyle(color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _telemetryTile(IconData icon, String label, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? AppColors.muted),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color ?? AppColors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
