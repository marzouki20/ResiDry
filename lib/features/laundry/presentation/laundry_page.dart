import 'package:flutter/material.dart';
import '../data/models/laundry_role.dart';
import '../../../core/theme/app_theme.dart';
import '../../casiers/presentation/widgets/casier_components.dart';
import '../data/models/laundry_item.dart';
import '../data/repositories/laundry_repository.dart';

class LaundryPage extends StatefulWidget {
  final LaundryRole role;
  final String userName;

  const LaundryPage({
    super.key,
    this.role = LaundryRole.admin,
    this.userName = '',
  });

  @override
  State<LaundryPage> createState() => _LaundryPageState();
}

class _LaundryPageState extends State<LaundryPage> {
  final LaundryRepository _repository = LaundryRepository();

  LaundryStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final items = _repository.getAll();

    final filteredItems = _selectedStatus == null
        ? items
        : items
        .where((item) => item.status == _selectedStatus)
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: PageHeading(
            title: 'Gestion du linge',
            subtitle:
            'Suivez les commandes de linge et leur état de traitement.',
            trailing: FilledButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ajouter'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ),

        _buildFilters(),

        Expanded(
          child: filteredItems.isEmpty
              ? const Center(
            child: Text(
              'Aucun élément trouvé',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 16,
              ),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];

              return _buildLaundryCard(item);
            },
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // FILTRES
  // ------------------------------------------------------------

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'Toutes',
            status: null,
          ),
          _buildFilterChip(
            label: 'Déposé',
            status: LaundryStatus.deposited,
          ),
          _buildFilterChip(
            label: 'En traitement',
            status: LaundryStatus.processing,
          ),
          _buildFilterChip(
            label: 'Prêt',
            status: LaundryStatus.ready,
          ),
          _buildFilterChip(
            label: 'Livré',
            status: LaundryStatus.delivered,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required LaundryStatus? status,
  }) {
    final isSelected = _selectedStatus == status;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedStatus = status;
          });
        },
        selectedColor: AppColors.cyan.withValues(alpha: 0.18),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.navy : AppColors.muted,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.cyan : AppColors.line,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // LAUNDRY CARD
  // ------------------------------------------------------------

  Widget _buildLaundryCard(LaundryItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 13),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.local_laundry_service_outlined,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${item.id}',
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.residentName,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                _buildStatusBadge(item.status),
              ],
            ),

            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_laundry_service_outlined,
                    color: AppColors.muted,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.serviceType,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${item.price.toStringAsFixed(2)} DT',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    _showEditDialog(item);
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Modifier'),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () {
                    _deleteItem(item);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Supprimer'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFE45858),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // STATUS BADGE
  // ------------------------------------------------------------

  Widget _buildStatusBadge(LaundryStatus status) {
    final label = _statusLabel(status);

    Color color;

    switch (status) {
      case LaundryStatus.deposited:
        color = const Color(0xFFE77B32);
        break;

      case LaundryStatus.processing:
        color = const Color(0xFF7457E8);
        break;

      case LaundryStatus.ready:
        color = AppColors.cyan;
        break;

      case LaundryStatus.delivered:
        color = const Color(0xFF4CAF50);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // ADD
  // ------------------------------------------------------------

  void _showAddDialog() {
    final nameController = TextEditingController();
    final serviceController = TextEditingController();
    final priceController = TextEditingController();

    LaundryStatus selectedStatus = LaundryStatus.deposited;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Ajouter une commande'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom du résident',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: serviceController,
                        decoration: const InputDecoration(
                          labelText: 'Type de service',
                          prefixIcon:
                          Icon(Icons.local_laundry_service_outlined),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Prix',
                          suffixText: 'DT',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                      ),

                      const SizedBox(height: 12),

                      DropdownButtonFormField<LaundryStatus>(
                        initialValue: selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Statut',
                          prefixIcon: Icon(Icons.flag_outlined),
                        ),
                        items: LaundryStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(_statusLabel(status)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedStatus = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Annuler'),
                ),

                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final service = serviceController.text.trim();
                    final price = double.tryParse(
                      priceController.text.trim(),
                    );

                    if (name.isEmpty ||
                        service.isEmpty ||
                        price == null ||
                        price < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Veuillez remplir correctement tous les champs.',
                          ),
                        ),
                      );
                      return;
                    }

                    final newItem = LaundryItem(
                      id: 'LD${DateTime.now().millisecondsSinceEpoch}',
                      residentName: name,
                      serviceType: service,
                      status: selectedStatus,
                      price: price,
                    );

                    setState(() {
                      _repository.add(newItem);
                    });

                    Navigator.pop(dialogContext);

                    _showMessage('Commande ajoutée avec succès.');
                  },
                  child: const Text('Ajouter'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ------------------------------------------------------------
  // UPDATE
  // ------------------------------------------------------------

  void _showEditDialog(LaundryItem item) {
    final nameController = TextEditingController(
      text: item.residentName,
    );

    final serviceController = TextEditingController(
      text: item.serviceType,
    );

    final priceController = TextEditingController(
      text: item.price.toString(),
    );

    LaundryStatus selectedStatus = item.status;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Modifier la commande'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom du résident',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: serviceController,
                        decoration: const InputDecoration(
                          labelText: 'Type de service',
                          prefixIcon:
                          Icon(Icons.local_laundry_service_outlined),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Prix',
                          suffixText: 'DT',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                      ),

                      const SizedBox(height: 12),

                      DropdownButtonFormField<LaundryStatus>(
                        initialValue: selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Statut',
                          prefixIcon: Icon(Icons.flag_outlined),
                        ),
                        items: LaundryStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(_statusLabel(status)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              selectedStatus = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Annuler'),
                ),

                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final service = serviceController.text.trim();
                    final price = double.tryParse(
                      priceController.text.trim(),
                    );

                    if (name.isEmpty ||
                        service.isEmpty ||
                        price == null ||
                        price < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Veuillez remplir correctement tous les champs.',
                          ),
                        ),
                      );
                      return;
                    }

                    final updatedItem = item.copyWith(
                      residentName: name,
                      serviceType: service,
                      price: price,
                      status: selectedStatus,
                    );

                    setState(() {
                      _repository.update(updatedItem);
                    });

                    Navigator.pop(dialogContext);

                    _showMessage('Commande modifiée avec succès.');
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ------------------------------------------------------------
  // DELETE
  // ------------------------------------------------------------

  void _deleteItem(LaundryItem item) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer la commande'),
          content: Text(
            'Voulez-vous vraiment supprimer la commande #${item.id} ?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Annuler'),
            ),

            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE45858),
              ),
              onPressed: () {
                setState(() {
                  _repository.delete(item.id);
                });

                Navigator.pop(dialogContext);

                _showMessage('Commande supprimée.');
              },
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // STATUS LABEL
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // MESSAGE
  // ------------------------------------------------------------

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}