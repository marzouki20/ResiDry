
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/models/laundry_item.dart';
import '../data/repositories/laundry_repository.dart';

class ResidentLaundryPage extends StatefulWidget {
  const ResidentLaundryPage({
    super.key,
    required this.residentId,
    required this.residentName,
    required this.repository,
  });

  final int residentId;
  final String residentName;
  final LaundryRepository repository;

  @override
  State<ResidentLaundryPage> createState() =>
      _ResidentLaundryPageState();
}

class _ResidentLaundryPageState extends State<ResidentLaundryPage> {
  @override
  Widget build(BuildContext context) {
    final items = widget.repository.getByResidentId(widget.residentId);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Mes demandes de linge'),
        backgroundColor: AppColors.cream,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Bienvenue, ${widget.residentName}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle demande'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.navy,
            ),
          ),
          const SizedBox(height: 20),

          if (items.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Vous n’avez aucune demande de linge.'),
              ),
            ),

          for (final item in items) _buildItemCard(item),
        ],
      ),
    );
  }

  Widget _buildItemCard(LaundryItem item) {
    final canModify = item.status == LaundryStatus.deposited;

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '#${item.id}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text('Service : ${item.serviceType}'),
            Text('Prix : ${item.price.toStringAsFixed(2)} DT'),
            Text('Statut : ${_statusLabel(item.status)}'),
            const SizedBox(height: 8),

            if (canModify)
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () => _openForm(item: item),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Modifier'),
                  ),
                  TextButton.icon(
                    onPressed: () => _confirmDelete(item),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Supprimer'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(LaundryStatus status) {
    switch (status) {
      case LaundryStatus.deposited:
        return 'Déposé';
      case LaundryStatus.processing:
        return 'En traitement';
      case LaundryStatus.ready:
        return 'Prêt';
      case LaundryStatus.delivered:
        return 'Livré';
    }
  }

  Future<void> _openForm({LaundryItem? item}) async {
    final serviceController = TextEditingController(
      text: item?.serviceType ?? '',
    );
    final priceController = TextEditingController(
      text: item?.price.toString() ?? '',
    );

    final result = await showDialog<(String, double)>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            item == null ? 'Nouvelle demande' : 'Modifier la demande',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: serviceController,
                decoration: const InputDecoration(
                  labelText: 'Type de service',
                ),
              ),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Prix en DT',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                final service = serviceController.text.trim();
                final price = double.tryParse(
                  priceController.text.trim().replaceAll(',', '.'),
                );

                if (service.isEmpty ||
                    price == null ||
                    !price.isFinite ||
                    price < 0) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Vérifiez le service et le prix.'),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext, (service, price));
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    serviceController.dispose();
    priceController.dispose();

    if (result == null || !mounted) return;

    final (service, price) = result;

    setState(() {
      if (item == null) {
        widget.repository.add(
          LaundryItem(
            id: 'LD${DateTime.now().microsecondsSinceEpoch}',
            residentId: widget.residentId,
            residentName: widget.residentName,
            serviceType: service,
            status: LaundryStatus.deposited,
            price: price,
          ),
        );
      } else if (item.residentId == widget.residentId &&
          item.status == LaundryStatus.deposited) {
        widget.repository.update(
          item.copyWith(
            serviceType: service,
            price: price,
          ),
        );
      }
    });
  }

  Future<void> _confirmDelete(LaundryItem item) async {
    if (item.residentId != widget.residentId ||
        item.status != LaundryStatus.deposited) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer la demande ?'),
          content: Text(
            'Voulez-vous supprimer la demande ${item.id} ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      widget.repository.delete(item.id);
    });
  }
}
