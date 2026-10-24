import 'package:flutter/material.dart';

import '../../../../core/localization/app_locale.dart';

import '../../../../models/laundry_item.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/user.dart';
import 'laundry_design.dart';

/// Dialog owns its controllers until its widget is disposed.
class LaundryAdminDialog extends StatefulWidget {
  const LaundryAdminDialog({super.key, this.item, this.residents = const []});
  final LaundryItem? item;
  final List<User> residents;
  @override
  State<LaundryAdminDialog> createState() => _LaundryAdminDialogState();
}

class _LaundryAdminDialogState extends State<LaundryAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  User? _resident;
  late final TextEditingController _service;
  late final TextEditingController _price;
  late LaundryStatus _status;

  @override
  void initState() {
    super.initState();
    for (final user in widget.residents) {
      if (user.id == widget.item?.residentId) _resident = user;
    }
    _service = TextEditingController(text: widget.item?.serviceType ?? '');
    _price = TextEditingController(
      text: widget.item?.priceConfirmed == true
          ? widget.item!.price.toString()
          : '',
    );
    _status = widget.item?.status ?? LaundryStatus.deposited;
  }

  @override
  void dispose() {
    _service.dispose();
    _price.dispose();
    super.dispose();
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? context.localize('Champ obligatoire')
      : null;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final item = LaundryItem(
      id: widget.item?.id ?? 'LD${DateTime.now().microsecondsSinceEpoch}',
      residentId: _resident?.id ?? widget.item?.residentId,
      residentName: _resident?.name ?? widget.item?.residentNameSnapshot ?? '',
      residentNameSnapshot: widget.item?.residentNameSnapshot,
      serviceType: _service.text.trim(),
      status: _status,
      price: _price.text.trim().isEmpty
          ? (widget.item?.price ?? 0)
          : double.parse(_price.text.trim().replaceAll(',', '.')),
      priceConfirmed: _price.text.trim().isNotEmpty,
      createdAt: widget.item?.createdAt,
    );
    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    icon: const Icon(
      Icons.local_laundry_service_outlined,
      color: AppColors.navy,
    ),
    title: Text(
      context.localize(
        widget.item == null ? 'Ajouter une commande' : 'Modifier la commande',
      ),
    ),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<User>(
                initialValue: _resident,
                isExpanded: true,
                decoration: laundryFieldDecoration(
                  label: context.tr(
                    fr: 'Compte résident',
                    en: 'Resident account',
                    ar: 'حساب المقيم',
                  ),
                  icon: Icons.person_outline_rounded,
                ),
                items: [
                  for (final user in widget.residents)
                    DropdownMenuItem(
                      value: user,
                      child: Text(
                        '${user.name} · #${user.id}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (user) => setState(() => _resident = user),
                validator: (user) =>
                    user == null &&
                        (widget.item == null || widget.item!.residentId != null)
                    ? context.localize('Sélectionnez un compte résident.')
                    : null,
              ),
              if (_resident != null)
                Text(context.localize('Résident : ${_resident!.name}')),
              if (widget.item != null && widget.item!.residentId == null)
                Text(
                  'Demande ancienne non associée. Ancien nom : ${widget.item!.residentNameSnapshot}. Sélectionner un compte établit une nouvelle association.',
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _service,
                validator: _required,
                decoration: laundryFieldDecoration(
                  label: context.tr(
                    fr: 'Type de service',
                    en: 'Service type',
                    ar: 'نوع الخدمة',
                  ),
                  icon: Icons.local_laundry_service_outlined,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: laundryFieldDecoration(
                  label: context.tr(
                    fr: 'Tarif administrateur (facultatif)',
                    en: 'Admin price (optional)',
                    ar: 'سعر المدير (اختياري)',
                  ),
                  suffix: 'DT',
                  icon: Icons.receipt_long_outlined,
                  helper: context.tr(
                    fr: 'Laisser vide pour une validation ultérieure.',
                    en: 'Leave blank to confirm later.',
                    ar: 'اتركه فارغًا للتأكيد لاحقًا.',
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final price = double.tryParse(
                    value.trim().replaceAll(',', '.'),
                  );
                  return price == null || !price.isFinite || price < 0
                      ? context.localize('Prix positif ou nul attendu')
                      : null;
                },
              ),
              if (widget.item != null &&
                  !widget.item!.priceConfirmed &&
                  widget.item!.price > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Montant précédent à revalider : ${widget.item!.price.toStringAsFixed(2)} DT',
                  ),
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<LaundryStatus>(
                initialValue: _status,
                isExpanded: true,
                decoration: laundryFieldDecoration(
                  label: context.tr(fr: 'Statut', en: 'Status', ar: 'الحالة'),
                  icon: Icons.track_changes_rounded,
                ),
                items: [
                  for (final status in LaundryStatus.values)
                    DropdownMenuItem(
                      value: status,
                      child: Text(context.localize(status.label)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) _status = value;
                },
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.localize('Annuler')),
      ),
      FilledButton(
        onPressed: _save,
        child: Text(context.localize('Enregistrer')),
      ),
    ],
  );
}
