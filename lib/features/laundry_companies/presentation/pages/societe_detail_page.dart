import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/machine.dart';
import '../../domain/models/societe_lavage.dart';
import '../widgets/machine_card.dart';
import '../widgets/machine_form_dialog.dart';
import 'machine_detail_page.dart';

class SocieteDetailPage extends StatefulWidget {
  const SocieteDetailPage({
    super.key,
    required this.societe,
    required this.onSocieteUpdated,
  });

  final SocieteLavage societe;
  final ValueChanged<SocieteLavage> onSocieteUpdated;

  @override
  State<SocieteDetailPage> createState() => _SocieteDetailPageState();
}

class _SocieteDetailPageState extends State<SocieteDetailPage> {
  late SocieteLavage _currentSociete;
  String _machineFilter = 'Toutes';

  @override
  void initState() {
    super.initState();
    _currentSociete = widget.societe;
  }

  void _addOrEditMachine([Machine? machine]) {
    showDialog<void>(
      context: context,
      builder: (context) => MachineFormDialog(
        societeId: _currentSociete.id,
        machine: machine,
        onSave: (savedMachine) {
          final updatedMachines = List<Machine>.of(_currentSociete.machines);
          final index = updatedMachines.indexWhere((m) => m.id == savedMachine.id);

          if (index != -1) {
            updatedMachines[index] = savedMachine;
          } else {
            updatedMachines.add(savedMachine);
          }

          final updatedSociete = _currentSociete.copyWith(machines: updatedMachines);
          setState(() => _currentSociete = updatedSociete);
          widget.onSocieteUpdated(updatedSociete);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                machine == null
                    ? 'Machine ajoutée avec succès !'
                    : 'Machine modifiée avec succès !',
              ),
              backgroundColor: AppColors.navy,
            ),
          );
        },
      ),
    );
  }

  void _deleteMachine(Machine machine) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Supprimer la machine'),
          ],
        ),
        content: Text('Voulez-vous vraiment supprimer "${machine.nom}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              final updatedMachines =
                  _currentSociete.machines.where((m) => m.id != machine.id).toList();
              final updatedSociete = _currentSociete.copyWith(machines: updatedMachines);
              setState(() => _currentSociete = updatedSociete);
              widget.onSocieteUpdated(updatedSociete);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Machine supprimée.')),
              );
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _toggleMachineCycle(Machine machine) {
    final isRunning = machine.statut == 'En cycle';
    final updatedStatut = isRunning ? 'Disponible' : 'En cycle';
    final updatedProgress = isRunning ? 0.0 : 0.25;
    final updatedTime = isRunning ? 0 : 35;

    final updatedMachine = machine.copyWith(
      statut: updatedStatut,
      progressionCycle: updatedProgress,
      tempsRestantMinutes: updatedTime,
    );

    final updatedMachines = _currentSociete.machines.map((m) {
      return m.id == machine.id ? updatedMachine : m;
    }).toList();

    final updatedSociete = _currentSociete.copyWith(machines: updatedMachines);
    setState(() => _currentSociete = updatedSociete);
    widget.onSocieteUpdated(updatedSociete);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isRunning
              ? 'Cycle interrompu pour ${machine.nom}.'
              : 'Cycle démarré pour ${machine.nom} (35 min).',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<Machine> get _filteredMachines {
    if (_machineFilter == 'Toutes') return _currentSociete.machines;
    return _currentSociete.machines
        .where((m) => m.statut == _machineFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentSociete.nom,
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
            // Company Header Banner Card
            _buildCompanyHeader(),
            const SizedBox(height: 20),

            // Key Metrics Dashboard
            _buildMetricsGrid(),
            const SizedBox(height: 24),

            // Machines Section Heading & Add Machine Button
            Row(
              children: [
                const Icon(Icons.precision_manufacturing_rounded, color: AppColors.navy),
                const SizedBox(width: 8),
                const Text(
                  'Parc de Machines',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onPressed: () => _addOrEditMachine(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Ajouter Machine'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Filter Chips for Machines
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Toutes', 'En cycle', 'Disponible', 'Maintenance'].map((filter) {
                  final isSelected = _machineFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(filter),
                      selectedColor: AppColors.navy,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.navy,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _machineFilter = filter);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // List of Machines
            if (_filteredMachines.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.cleaning_services_outlined, size: 48, color: AppColors.muted),
                    const SizedBox(height: 12),
                    Text(
                      'Aucune machine pour le filtre "$_machineFilter"',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._filteredMachines.map((machine) {
                return MachineCard(
                  machine: machine,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MachineDetailPage(
                          machine: machine,
                          onMachineUpdated: (updatedM) {
                            final updatedMs = _currentSociete.machines
                                .map((m) => m.id == updatedM.id ? updatedM : m)
                                .toList();
                            final updatedS =
                                _currentSociete.copyWith(machines: updatedMs);
                            setState(() => _currentSociete = updatedS);
                            widget.onSocieteUpdated(updatedS);
                          },
                        ),
                      ),
                    );
                  },
                  onEdit: () => _addOrEditMachine(machine),
                  onDelete: () => _deleteMachine(machine),
                  onToggleCycle: () => _toggleMachineCycle(machine),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.business_rounded, color: AppColors.navy, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentSociete.nom,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentSociete.adresse,
                      style: const TextStyle(fontSize: 13, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_currentSociete.description.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              _currentSociete.description,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.line),
          const SizedBox(height: 12),

          Row(
            children: [
              _infoTile(Icons.phone_rounded, _currentSociete.telephone),
              const SizedBox(width: 16),
              _infoTile(Icons.email_rounded, _currentSociete.email),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String text) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.navy),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: AppColors.navy),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Row(
      children: [
        Expanded(
          child: _metricCard(
            'Machines',
            _currentSociete.machines.length.toString(),
            Icons.precision_manufacturing_rounded,
            AppColors.navy,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metricCard(
            'En Cycle',
            _currentSociete.runningCyclesCount.toString(),
            Icons.sync_rounded,
            AppColors.cyan,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metricCard(
            'Capacité',
            '${_currentSociete.capaciteMaxKg} Kg',
            Icons.fitness_center_rounded,
            Colors.purple.shade700,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _metricCard(
            'Santé IoT',
            '${_currentSociete.iotHealthScore}%',
            Icons.sensors_rounded,
            Colors.green.shade700,
          ),
        ),
      ],
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
