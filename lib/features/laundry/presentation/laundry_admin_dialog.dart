import 'package:flutter/material.dart';

import '../data/models/laundry_item.dart';

/// Dialog owns its controllers until its widget is disposed.
class LaundryAdminDialog extends StatefulWidget {
  const LaundryAdminDialog({super.key, this.item});
  final LaundryItem? item;
  @override
  State<LaundryAdminDialog> createState() => _LaundryAdminDialogState();
}

class _LaundryAdminDialogState extends State<LaundryAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _residentId;
  late final TextEditingController _service;
  late final TextEditingController _price;
  late LaundryStatus _status;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.item?.residentName ?? '');
    _residentId = TextEditingController(
      text: widget.item?.residentId?.toString() ?? '',
    );
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
    _name.dispose();
    _residentId.dispose();
    _service.dispose();
    _price.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Champ obligatoire' : null;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final item = LaundryItem(
      id: widget.item?.id ?? 'LD${DateTime.now().microsecondsSinceEpoch}',
      residentId: int.tryParse(_residentId.text.trim()),
      residentName: _name.text.trim(),
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
    title: Text(
      widget.item == null ? 'Ajouter une commande' : 'Modifier la commande',
    ),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                validator: _required,
                decoration: const InputDecoration(labelText: 'Nom du résident'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _residentId,
                keyboardType: TextInputType.number,
                readOnly: widget.item?.residentId != null,
                decoration: const InputDecoration(
                  labelText: 'Identifiant du résident (facultatif)',
                  helperText: 'Nécessaire pour apparaître dans son espace.',
                ),
                validator: (value) =>
                    value!.trim().isEmpty ||
                        (int.tryParse(value.trim()) ?? 0) > 0
                    ? null
                    : 'Identifiant entier positif attendu',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _service,
                validator: _required,
                decoration: const InputDecoration(labelText: 'Type de service'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Tarif administrateur (facultatif)',
                  suffixText: 'DT',
                  helperText: 'Laisser vide pour une validation ultérieure.',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final price = double.tryParse(
                    value.trim().replaceAll(',', '.'),
                  );
                  return price == null || !price.isFinite || price < 0
                      ? 'Prix positif ou nul attendu'
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
                decoration: const InputDecoration(labelText: 'Statut'),
                items: [
                  for (final status in LaundryStatus.values)
                    DropdownMenuItem(value: status, child: Text(status.label)),
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
        child: const Text('Annuler'),
      ),
      FilledButton(onPressed: _save, child: const Text('Enregistrer')),
    ],
  );
}
