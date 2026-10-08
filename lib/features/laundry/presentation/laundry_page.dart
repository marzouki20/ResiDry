import 'package:flutter/material.dart';

import '../data/models/laundry_item.dart';
import '../data/repositories/laundry_repository.dart';

class LaundryPage extends StatefulWidget {
  const LaundryPage({super.key});

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion du linge'),
      ),
      body: Column(
        children: [
          _buildFilters(),

          Expanded(
            child: filteredItems.isEmpty
                ? const Center(
              child: Text(
                'Aucun élément trouvé',
                style: TextStyle(fontSize: 16),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];

                return _buildLaundryCard(item);
              },
            ),
          ),
        ],
      ),

      // Bouton pour ajouter un élément.
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ------------------------------------------------------------
  // FILTRES
  // ------------------------------------------------------------

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
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
      ),
    );
  }

  // ------------------------------------------------------------
  // LAUNDRY CARD
  // ------------------------------------------------------------

  Widget _buildLaundryCard(LaundryItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${item.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                _buildStatusBadge(item.status),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              item.residentName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              item.serviceType,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '${item.price.toStringAsFixed(2)} DT',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
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
                  icon: const Icon(Icons.edit),
                  label: const Text('Modifier'),
                ),

                TextButton.icon(
                  onPressed: () {
                    _deleteItem(item);
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Supprimer'),
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
    String label;

    switch (status) {
      case LaundryStatus.deposited:
        label = 'Déposé';
        break;

      case LaundryStatus.processing:
        label = 'En traitement';
        break;

      case LaundryStatus.ready:
        label = 'Prêt';
        break;

      case LaundryStatus.delivered:
        label = 'Livré';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey.shade200,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
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
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Ajouter une commande'),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du résident',
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: serviceController,
                      decoration: const InputDecoration(
                        labelText: 'Type de service',
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Prix',
                        suffixText: 'DT',
                      ),
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<LaundryStatus>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Statut',
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

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Annuler'),
                ),

                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final service = serviceController.text.trim();
                    final price =
                    double.tryParse(priceController.text.trim());

                    if (name.isEmpty ||
                        service.isEmpty ||
                        price == null) {
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

                    Navigator.pop(context);
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
    final nameController =
    TextEditingController(text: item.residentName);

    final serviceController =
    TextEditingController(text: item.serviceType);

    final priceController =
    TextEditingController(text: item.price.toString());

    LaundryStatus selectedStatus = item.status;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Modifier la commande'),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du résident',
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: serviceController,
                      decoration: const InputDecoration(
                        labelText: 'Type de service',
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Prix',
                        suffixText: 'DT',
                      ),
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<LaundryStatus>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Statut',
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

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Annuler'),
                ),

                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final service = serviceController.text.trim();
                    final price =
                    double.tryParse(priceController.text.trim());

                    if (name.isEmpty ||
                        service.isEmpty ||
                        price == null) {
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

                    Navigator.pop(context);
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
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer la commande'),

          content: Text(
            'Voulez-vous vraiment supprimer la commande '
                '#${item.id} ?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Annuler'),
            ),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  _repository.delete(item.id);
                });

                Navigator.pop(context);
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
}