import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/societe_lavage.dart';

class SocieteFormDialog extends StatefulWidget {
  const SocieteFormDialog({
    super.key,
    this.societe,
    required this.onSave,
  });

  final SocieteLavage? societe;
  final ValueChanged<SocieteLavage> onSave;

  @override
  State<SocieteFormDialog> createState() => _SocieteFormDialogState();
}

class _SocieteFormDialogState extends State<SocieteFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomController;
  late final TextEditingController _adresseController;
  late final TextEditingController _telephoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _capaciteController;
  late final TextEditingController _descriptionController;
  late String _statut;

  @override
  void initState() {
    super.initState();
    final s = widget.societe;
    _nomController = TextEditingController(text: s?.nom ?? '');
    _adresseController = TextEditingController(text: s?.adresse ?? '');
    _telephoneController = TextEditingController(text: s?.telephone ?? '');
    _emailController = TextEditingController(text: s?.email ?? '');
    _capaciteController =
        TextEditingController(text: (s?.capaciteMaxKg ?? 120).toString());
    _descriptionController = TextEditingController(text: s?.description ?? '');
    _statut = s?.statut ?? 'Actif';
  }

  @override
  void dispose() {
    _nomController.dispose();
    _adresseController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _capaciteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final isEdit = widget.societe != null;
      final updated = SocieteLavage(
        id: isEdit ? widget.societe!.id : 'SOC-${DateTime.now().millisecondsSinceEpoch % 10000}',
        nom: _nomController.text.trim(),
        adresse: _adresseController.text.trim(),
        telephone: _telephoneController.text.trim(),
        email: _emailController.text.trim(),
        statut: _statut,
        datePartenariat: isEdit ? widget.societe!.datePartenariat : DateTime.now(),
        noteEvaluation: isEdit ? widget.societe!.noteEvaluation : 4.5,
        capaciteMaxKg: int.tryParse(_capaciteController.text.trim()) ?? 120,
        iotHealthScore: isEdit ? widget.societe!.iotHealthScore : 95,
        description: _descriptionController.text.trim(),
        machines: isEdit ? widget.societe!.machines : [],
      );

      widget.onSave(updated);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.societe != null;
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
                      color: AppColors.navy.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEdit ? Icons.edit_rounded : Icons.add_business_rounded,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEdit ? 'Modifier la Société' : 'Ajouter une Société',
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

              // Nom de la société
              TextFormField(
                controller: _nomController,
                decoration: _buildInputDecoration(
                  label: 'Nom de la Société *',
                  icon: Icons.business_rounded,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom de la société est obligatoire.';
                  }
                  if (value.trim().length < 3) {
                    return 'Le nom doit contenir au moins 3 caractères.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Adresse
              TextFormField(
                controller: _adresseController,
                decoration: _buildInputDecoration(
                  label: 'Adresse complète *',
                  icon: Icons.location_on_rounded,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'L’adresse est obligatoire.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Row Telephone & Email
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _telephoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _buildInputDecoration(
                        label: 'Téléphone *',
                        icon: Icons.phone_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Téléphone requis.';
                        }
                        if (value.trim().length < 8) {
                          return 'Au moins 8 chiffres.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _buildInputDecoration(
                        label: 'Email *',
                        icon: Icons.email_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email requis.';
                        }
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value.trim())) {
                          return 'Email non valide.';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Row Statut & Capacité
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _statut,
                      decoration: _buildInputDecoration(
                        label: 'Statut',
                        icon: Icons.verified_user_rounded,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Actif', child: Text('Actif')),
                        DropdownMenuItem(
                          value: 'Sous Maintenance',
                          child: Text('Sous Maintenance'),
                        ),
                        DropdownMenuItem(value: 'Inactif', child: Text('Inactif')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _statut = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _capaciteController,
                      keyboardType: TextInputType.number,
                      decoration: _buildInputDecoration(
                        label: 'Capacité (Kg) *',
                        icon: Icons.fitness_center_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Capacité requise.';
                        }
                        final cap = int.tryParse(value.trim());
                        if (cap == null || cap <= 0) {
                          return 'Valeur invalide (>0).';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: _buildInputDecoration(
                  label: 'Description / Notes',
                  icon: Icons.description_rounded,
                ),
              ),
              const SizedBox(height: 22),

              // Action buttons
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
                    label: Text(isEdit ? 'Enregistrer' : 'Ajouter'),
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
