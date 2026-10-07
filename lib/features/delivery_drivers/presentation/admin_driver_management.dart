import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../models/delivery_driver.dart';
import '../../../../models/delivery_order.dart';
import '../../casiers/presentation/widgets/casier_components.dart';

class AdminDriverManagementView extends StatefulWidget {
  const AdminDriverManagementView({super.key});

  @override
  State<AdminDriverManagementView> createState() =>
      _AdminDriverManagementViewState();
}

class _AdminDriverManagementViewState
    extends State<AdminDriverManagementView> {
  final List<DeliveryDriver> _drivers = List<DeliveryDriver>.of(demoDeliveryDrivers);
  final List<DeliveryOrder> _orders = List<DeliveryOrder>.of(demoDeliveryOrders);
  String _filter = 'Tous';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final activeDrivers =
        _drivers.where((d) => d.status == 'En service' || d.status == 'En livraison').length;

    final filteredDrivers = _drivers.where((d) {
      final matchesQuery =
          d.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.assignedZone.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter = switch (_filter) {
        'En service' => d.status == 'En service',
        'En livraison' => d.status == 'En livraison',
        'Hors service' => d.status == 'Hors service',
        _ => true,
      };

      return matchesQuery && matchesFilter;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const PageHeading(
          title: 'Gestion des livreurs',
          subtitle: 'Suivez la flotte de livreurs et attribuez les missions.',
        ),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.35,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            MetricCard(
              label: 'Livreurs inscrits',
              value: '${_drivers.length}',
              icon: Icons.badge_outlined,
            ),
            MetricCard(
              label: 'Actifs en service',
              value: '$activeDrivers',
              icon: Icons.local_shipping_outlined,
              color: AppColors.cyan,
            ),
            MetricCard(
              label: 'Courses en cours',
              value: '${_orders.where((o) => o.status != 'Livré').length}',
              icon: Icons.directions_bike_rounded,
            ),
            MetricCard(
              label: 'Missions livrées',
              value: '${_orders.where((o) => o.status == 'Livré' || o.status == 'Déposé au casier').length}',
              icon: Icons.task_alt_rounded,
              color: AppColors.cyan,
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            hintText: 'Rechercher un livreur, zone...',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppColors.line),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final f in ['Tous', 'En service', 'En livraison', 'Hors service'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: AppColors.cyan.withValues(alpha: 0.18),
                    side: BorderSide(
                      color: _filter == f ? AppColors.cyan : AppColors.line,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final driver in filteredDrivers) _driverCard(driver),
      ],
    );
  }

  Widget _driverCard(DeliveryDriver driver) {
    final statusColor = switch (driver.status) {
      'En service' => AppColors.cyan,
      'En livraison' => AppColors.navy,
      _ => AppColors.muted,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.navy,
                  child: Text(
                    driver.name[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.name,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${driver.id} · ${driver.assignedZone}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusPill(driver.status, color: statusColor),
              ],
            ),
            const Divider(height: 20, color: AppColors.line),
            Row(
              children: [
                Expanded(
                  child: _miniInfo('Véhicule', driver.vehicleType),
                ),
                Expanded(
                  child: _miniInfo('Téléphone', driver.phone),
                ),
                Expanded(
                  child: _miniInfo('Note', '${driver.rating} ⭐'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _assignOrderDialog(driver),
                    icon: const Icon(Icons.assignment_add, size: 18),
                    label: const Text('Assigner course'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navy,
                      side: const BorderSide(color: AppColors.line),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniInfo(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );

  void _assignOrderDialog(DeliveryDriver driver) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Assigner course à ${driver.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final order in _orders)
              ListTile(
                title: Text('${order.id} · Casier ${order.lockerId}'),
                subtitle: Text('${order.residentName} (${order.type})'),
                trailing: TextButton(
                  onPressed: () {
                    setState(() => order.driverName = driver.name);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Commande ${order.id} assignée à ${driver.name}'),
                      ),
                    );
                  },
                  child: const Text('Assigner'),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
