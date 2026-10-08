import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/machine.dart';

class MachineFormDialog extends StatefulWidget {
  const MachineFormDialog({
    super.key,
    required this.societeId,
    this.machine,
    required this.onSave,
  });

  final String societeId;
  final Machine? machine;
  final ValueChanged<Machine> onSave;

  @override
  State<MachineFormDialog> createState() => _MachineFormDialogState();
}

class _MachineFormDialogState extends State<MachineFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomController;
  late final TextEditingController _temperatureController;
  late final TextEditingController _santeController;
  late String _type;
  late String _statut;

  @override
  void initState() {
    super.initState();
    final m = widget.machine;
    _nomController = TextEditingController(text: m?.nom ?? '');
    _temperatureController =
        TextEditingController(text: (m?.temperatureC ?? 30.0).toString());
    _santeController =
        TextEditingController(text: (m?.santeIot ?? 95).toString());
    _type = m?.type ?? 'Lave-linge';
    _statut = m?.statut ?? 'Disponible';
  }

  @override
  void dispose() {
    _nomController.dispose();
    _temperatureController.dispose();
    _santeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final isEdit = widget.machine != null;
      final temp = double.tryParse(_temperatureController.text.trim()) ?? 30.0;
      final sante = int.tryParse(_santeController.text.trim()) ?? 95;

      final updated = Machine(
        id: isEdit
            ? widget.machine!.id
            : 'MCH-${DateTime.now().millisecondsSinceEpoch % 10000}',
        societeId: widget.societeId,
        nom: _nomController.text.trim(),
        type: _type,
        statut: _statut,
        progressionCycle: isEdit ? widget.machine!.progressionCycle : 0.0,
        tempsRestantMinutes: isEdit ? widget.machine!.tempsRestantMinutes : 0,
        temperatureC: temp,
        vibrationLevel: isEdit ? widget.machine!.vibrationLevel : 1.2,
        consommationKwh: isEdit ? widget.machine!.consommationKwh : 1.5,
        santeIot: sante.clamp(0, 100),
      );

      widget.onSave(updated);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.machine != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEdit ? Icons.edit_rounded : Icons.local_laundry_service_rounded,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEdit ? 'Modifier la Machine' : 'Ajouter une Machine IoT',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1, color: AppColors.line),
              const SizedBox(height: 18),

              TextFormField(
                controller: _nomController,
                decoration: _buildInputDecoration(
                  label: 'Nom / Identifiant Machine *',
                  icon: Icons.precision_manufacturing_rounded,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom de la machine est obligatoire.';
                  }
                  if (value.trim().length < 3) {
                    return 'Le nom doit contenir au moins 3 caractères.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _type,
                decoration: _buildInputDecoration(
                  label: 'Type de Machine',
                  icon: Icons.category_rounded,
                ),
                items: const [
                  DropdownMenuItem(value: 'Lave-linge', child: Text('Lave-linge')),
                  DropdownMenuItem(value: 'Sèche-linge', child: Text('Sèche-linge')),
                  DropdownMenuItem(
                    value: 'Nettoyage Écologique',
                    child: Text('Nettoyage Écologique'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _type = val);
                },
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _statut,
                      decoration: _buildInputDecoration(
                        label: 'Statut',
                        icon: Icons.circle_notifications_rounded,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Disponible', child: Text('Disponible')),
                        DropdownMenuItem(value: 'En cycle', child: Text('En cycle')),
                        DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance')),
                        DropdownMenuItem(value: 'Hors service', child: Text('Hors service')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _statut = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _temperatureController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _buildInputDecoration(
                        label: 'Température (°C) *',
                        icon: Icons.device_thermostat_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Température requise.';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Nombre valide.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _santeController,
                      keyboardType: TextInputType.number,
                      decoration: _buildInputDecoration(
                        label: 'Santé IoT (%) *',
                        icon: Icons.monitor_heart_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Santé requise.';
                        }
                        final v = int.tryParse(value.trim());
                        if (v == null || v < 0 || v > 100) {
                          return 'Entre 0 et 100.';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annuler', style: TextStyle(color: AppColors.muted)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _submit,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(isEdit ? 'Enregistrer' : 'Ajouter Machine'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
      prefixIcon: Icon(icon, size: 20, color: AppColors.navy),
      filled: true,
      fillColor: AppColors.cream.withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.navy, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
