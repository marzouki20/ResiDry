import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/delivery_driver.dart';
import 'order_data.dart';

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = orderStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class OrderSectionTitle extends StatelessWidget {
  const OrderSectionTitle(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    ),
  );
}

class OrderInfoTile extends StatelessWidget {
  const OrderInfoTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 17, color: AppColors.muted),
          const SizedBox(width: 9),
        ],
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class OrderPanel extends StatelessWidget {
  const OrderPanel({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: AppColors.line),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    ),
  );
}

class DashboardCommandes extends StatelessWidget {
  const DashboardCommandes({
    super.key,
    required this.orders,
    required this.userName,
    required this.onOpenOrders,
    required this.onOpenDeliveries,
    required this.onOpenAlerts,
    required this.onOpenStats,
    required this.onOpenOrder,
  });

  final List<ManagedOrder> orders;
  final String userName;
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenDeliveries;
  final VoidCallback onOpenAlerts;
  final VoidCallback onOpenStats;
  final ValueChanged<ManagedOrder> onOpenOrder;

  @override
  Widget build(BuildContext context) {
    final waiting = orders
        .where(
          (o) =>
              ['Nouvelle', 'En attente', 'Collecte prévue'].contains(o.status),
        )
        .length;
    final inProgress = orders
        .where(
          (o) => [
            'Collectée',
            'Lavage terminé',
            'En livraison',
          ].contains(o.status),
        )
        .length;
    final washing = orders.where((o) => o.status == 'En lavage').length;
    final ready = orders.where((o) => o.status == 'Prête').length;
    final delivered = orders.where((o) => o.status == 'Livrée').length;
    final delivery = orders.where((o) => o.status == 'En livraison').length;
    final late = orders
        .where(
          (o) =>
              o.status == 'En livraison' &&
              o.deliveryAt.isBefore(DateTime.now()),
        )
        .length;
    final today = orders.where((o) {
      final now = DateTime.now();
      return o.createdAt.year == now.year &&
          o.createdAt.month == now.month &&
          o.createdAt.day == now.day;
    }).length;
    final recent = [...orders]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      children: [
        Text(
          'Bonjour, $userName',
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Vue d’ensemble des commandes et livraisons.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: [
            _DashboardMetric(
              'Commandes aujourd’hui',
              '$today',
              Icons.today_rounded,
              AppColors.navy,
            ),
            _DashboardMetric(
              'En attente',
              '$waiting',
              Icons.hourglass_top_rounded,
              const Color(0xFFE77B32),
            ),
            _DashboardMetric(
              'En cours',
              '$inProgress',
              Icons.sync_rounded,
              const Color(0xFF2674C8),
            ),
            _DashboardMetric(
              'En lavage',
              '$washing',
              Icons.local_laundry_service_rounded,
              const Color(0xFF7457E8),
            ),
            _DashboardMetric(
              'Prêtes',
              '$ready',
              Icons.inventory_2_outlined,
              AppColors.cyan,
            ),
            _DashboardMetric(
              'Livrées',
              '$delivered',
              Icons.task_alt_rounded,
              const Color(0xFF159A86),
            ),
            _DashboardMetric(
              'Livraisons en cours',
              '$delivery',
              Icons.local_shipping_outlined,
              const Color(0xFF2674C8),
            ),
            _DashboardMetric(
              'Livraisons en retard',
              '$late',
              Icons.warning_amber_rounded,
              const Color(0xFFE45858),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: const Color(0xFFEAF3FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: AppColors.navy),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Analyse intelligente',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Risque de retard : ${late > 0 ? 87 : 24} %',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  late > 0
                      ? 'CMD-1024 · Charge de livraison élevée. Réaffectez si nécessaire.'
                      : 'Aucun retard critique détecté pour le moment.',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: onOpenStats,
                  child: const Text('Voir les statistiques'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        OrderSectionTitle(
          'Activités récentes',
          action: 'Toutes les commandes',
          onAction: onOpenOrders,
        ),
        for (final order in recent.take(4))
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: CircleAvatar(
              backgroundColor: orderStatusColor(order.status)
                  .withValues(alpha: .12),
              child: Icon(
                Icons.receipt_long_rounded,
                color: orderStatusColor(order.status),
                size: 19,
              ),
            ),
            title: Text(
              '${order.id} · ${_activityFor(order.status)}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '${order.resident} · ${formatOrderDate(order.createdAt)}',
              style: const TextStyle(fontSize: 11),
            ),
            onTap: () => onOpenOrder(order),
          ),
        const SizedBox(height: 10),
        OrderSectionTitle(
          'Alertes',
          action: 'Voir tout',
          onAction: onOpenAlerts,
        ),
        if (late > 0)
          _AlertPreview(
            title: 'Livraison en retard',
            subtitle: 'CMD-1024 · Vérifier le suivi',
            color: const Color(0xFFE45858),
          ),
        _AlertPreview(
          title: 'Commande sans livreur',
          subtitle: 'CMD-1015 · Affectation requise',
          color: const Color(0xFFE77B32),
        ),
        _AlertPreview(
          title: 'Délai de lavage à surveiller',
          subtitle: 'CMD-1023 · En cours de traitement',
          color: const Color(0xFF7457E8),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onOpenDeliveries,
          icon: const Icon(Icons.map_outlined),
          label: const Text('Suivre les livraisons en cours'),
        ),
      ],
    );
  }

  String _activityFor(String status) => switch (status) {
    'En livraison' => 'livraison démarrée',
    'Collectée' => 'récupérée',
    'En lavage' => 'envoyée au lavage',
    'Livrée' => 'livrée',
    'Annulée' => 'annulée',
    _ => 'créée',
  };
}

class _DashboardMetric extends StatelessWidget {
  const _DashboardMetric(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(icon, color: color, size: 20),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    ),
  );
}

class _AlertPreview extends StatelessWidget {
  const _AlertPreview({
    required this.title,
    required this.subtitle,
    required this.color,
  });
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: AppColors.line),
    ),
    child: ListTile(
      leading: Icon(Icons.warning_amber_rounded, color: color),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
    ),
  );
}

class ListeCommandes extends StatefulWidget {
  const ListeCommandes({
    super.key,
    required this.orders,
    required this.drivers,
    required this.onOpenOrder,
    required this.onCreate,
  });
  final List<ManagedOrder> orders;
  final List<DeliveryDriver> drivers;
  final ValueChanged<ManagedOrder> onOpenOrder;
  final VoidCallback onCreate;

  @override
  State<ListeCommandes> createState() => _ListeCommandesState();
}

class _ListeCommandesState extends State<ListeCommandes> {
  String _query = '';
  String _status = 'Tous les statuts';
  String _driver = 'Tous les livreurs';
  String _date = 'Toutes les dates';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.orders.where((order) {
      final query = _query.toLowerCase();
      final matchesQuery =
          order.id.toLowerCase().contains(query) ||
          order.resident.toLowerCase().contains(query);
      final matchesStatus =
          _status == 'Tous les statuts' || order.status == _status;
      final matchesDriver =
          _driver == 'Tous les livreurs' || order.driverName == _driver;
      final now = DateTime.now();
      final matchesDate = switch (_date) {
        'Aujourd’hui' =>
          order.createdAt.year == now.year &&
              order.createdAt.month == now.month &&
              order.createdAt.day == now.day,
        'Cette semaine' => now.difference(order.createdAt).inDays < 7,
        _ => true,
      };
      return matchesQuery && matchesStatus && matchesDriver && matchesDate;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Commandes',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: widget.onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Créer'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            hintText: 'Rechercher une commande ou un résident',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.line),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _OrderDropdown(
          value: _status,
          options: ['Tous les statuts', ...orderStatuses],
          onChanged: (value) => setState(() => _status = value),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _OrderDropdown(
                value: _date,
                options: const [
                  'Toutes les dates',
                  'Aujourd’hui',
                  'Cette semaine',
                ],
                onChanged: (value) => setState(() => _date = value),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _OrderDropdown(
                value: _driver,
                options: [
                  'Tous les livreurs',
                  ...widget.drivers.map((d) => d.name),
                ],
                onChanged: (value) => setState(() => _driver = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          '${filtered.length} commande${filtered.length == 1 ? '' : 's'}',
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text('Aucune commande ne correspond à ces critères.'),
            ),
          )
        else
          for (final order in filtered)
            _OrderListCard(
              order: order,
              onTap: () => widget.onOpenOrder(order),
            ),
      ],
    );
  }
}

class _OrderDropdown extends StatelessWidget {
  const _OrderDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line),
      ),
    ),
    items: options
        .map(
          (item) => DropdownMenuItem(
            value: item,
            child: Text(
              item,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        )
        .toList(),
    onChanged: (item) {
      if (item != null) onChanged(item);
    },
  );
}

class _OrderListCard extends StatelessWidget {
  const _OrderListCard({required this.order, required this.onTap});
  final ManagedOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(17),
      side: const BorderSide(color: AppColors.line),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(17),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.id,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                OrderStatusBadge(order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              order.resident,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _compactInfo(Icons.door_front_door_outlined, order.locker),
                _compactInfo(
                  Icons.scale_outlined,
                  '${order.weight.toStringAsFixed(1)} kg',
                ),
                _compactInfo(
                  Icons.local_laundry_service_outlined,
                  order.laundryType,
                ),
              ],
            ),
            const Divider(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Livreur : ${order.driverName ?? 'Non affecté'}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                Text(
                  'Prévue ${formatOrderDate(order.deliveryAt)}',
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ],
            ),
            Text(
              'Créée le ${formatOrderDate(order.createdAt)}',
              style: const TextStyle(fontSize: 10, color: AppColors.muted),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _compactInfo(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: AppColors.muted),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
    ],
  );
}

class DetailsCommande extends StatelessWidget {
  const DetailsCommande({
    super.key,
    required this.order,
    required this.history,
    required this.onEdit,
    required this.onAssign,
    required this.onDelivery,
    required this.onHistory,
    required this.onCancel,
  });
  final ManagedOrder order;
  final List<OrderHistoryEntry> history;
  final VoidCallback onEdit;
  final VoidCallback onAssign;
  final VoidCallback onDelivery;
  final VoidCallback onHistory;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final progress = switch (order.status) {
      'Nouvelle' || 'En attente' => 0,
      'Collecte prévue' => 1,
      'Collectée' => 2,
      'En lavage' => 3,
      'Lavage terminé' || 'Prête' => 5,
      'En livraison' => 6,
      'Livrée' => 7,
      _ => -1,
    };
    final timeline = [
      'Commande créée',
      'Linge déposé',
      'Linge collecté',
      'Envoyé à la société de lavage',
      'Lavage terminé',
      'Prêt pour livraison',
      'En livraison',
      'Livré',
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 26),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                order.id,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            OrderStatusBadge(order.status),
          ],
        ),
        const SizedBox(height: 14),
        OrderPanel(
          title: 'Informations commande',
          children: [
            OrderInfoTile(
              label: 'Date de création',
              value:
                  '${formatOrderDate(order.createdAt)} · ${formatOrderTime(order.createdAt)}',
            ),
            OrderInfoTile(label: 'Résident', value: order.resident),
            OrderInfoTile(label: 'Appartement', value: order.apartment),
            OrderInfoTile(label: 'Casier', value: order.locker),
            OrderInfoTile(label: 'Type de linge', value: order.laundryType),
            OrderInfoTile(
              label: 'Quantité · poids',
              value:
                  '${order.quantity} pièces · ${order.weight.toStringAsFixed(1)} kg',
            ),
            OrderInfoTile(
              label: 'Prix',
              value: '${order.price.toStringAsFixed(2)} TND',
            ),
            OrderInfoTile(label: 'Blanchisserie', value: order.laundryCompany),
          ],
        ),
        OrderPanel(
          title: 'Informations livraison',
          children: [
            OrderInfoTile(
              label: 'Livreur',
              value: order.driverName ?? 'Non affecté',
            ),
            OrderInfoTile(
              label: 'Date de collecte',
              value:
                  '${formatOrderDate(order.collectionAt)} · ${formatOrderTime(order.collectionAt)}',
            ),
            OrderInfoTile(
              label: 'Collecte effectuée',
              value: order.collectionCompletedAt == null
                  ? 'En attente'
                  : formatOrderTime(order.collectionCompletedAt!),
            ),
            OrderInfoTile(
              label: 'Livraison prévue',
              value:
                  '${formatOrderDate(order.deliveryAt)} · ${formatOrderTime(order.deliveryAt)}',
            ),
            OrderInfoTile(label: 'Statut livraison', value: order.status),
          ],
        ),
        OrderPanel(
          title: 'Suivi de la commande',
          children: [
            for (var i = 0; i < timeline.length; i++)
              _TimelineRow(
                label: timeline[i],
                complete: progress >= i && progress >= 0,
                current: progress == i,
                last: i == timeline.length - 1,
              ),
          ],
        ),
        OrderPanel(
          title: 'Casier connecté · ${order.locker}',
          children: [
            OrderInfoTile(
              label: 'Poids détecté',
              value: '${order.weight.toStringAsFixed(1)} kg',
              icon: Icons.scale_outlined,
            ),
            OrderInfoTile(
              label: 'Porte',
              value: order.doorClosed ? 'Fermée' : 'Ouverte',
              icon: Icons.door_front_door_outlined,
            ),
            OrderInfoTile(
              label: 'Connexion IoT',
              value: order.iotConnected ? 'Connectée' : 'Hors ligne',
              icon: Icons.sensors_rounded,
            ),
            OrderInfoTile(
              label: 'Dernière synchronisation',
              value: order.lastSync,
              icon: Icons.sync_rounded,
            ),
            OrderInfoTile(
              label: 'Dépôt / récupération',
              value:
                  '09:12 / ${order.collectionCompletedAt == null ? 'En attente' : formatOrderTime(order.collectionCompletedAt!)}',
            ),
          ],
        ),
        if (order.status == 'En livraison')
          Card(
            elevation: 0,
            color: const Color(0xFFEAF3FF),
            child: ListTile(
              leading: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.navy,
              ),
              title: const Text(
                'Risque de retard : 87 %',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text(
                'Cause probable : forte charge de livraison.\nRecommandation : affecter un autre livreur.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        if (order.notes.isNotEmpty)
          OrderPanel(
            title: 'Remarques',
            children: [
              Text(order.notes, style: const TextStyle(color: AppColors.muted)),
            ],
          ),
        const SizedBox(height: 4),
        FilledButton.icon(
          onPressed: onAssign,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('Affecter un livreur'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Modifier la commande'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onDelivery,
          icon: const Icon(Icons.local_shipping_outlined),
          label: const Text('Voir la livraison'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onHistory,
          icon: const Icon(Icons.history_rounded),
          label: const Text('Voir l’historique'),
        ),
        if (order.status != 'Annulée' && order.status != 'Livrée') ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.cancel_outlined, color: Color(0xFFE45858)),
            label: const Text(
              'Annuler la commande',
              style: TextStyle(color: Color(0xFFE45858)),
            ),
          ),
        ],
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.label,
    required this.complete,
    required this.current,
    required this.last,
  });
  final String label;
  final bool complete;
  final bool current;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final color = complete ? AppColors.cyan : AppColors.line;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Icon(
                  current
                      ? Icons.radio_button_checked_rounded
                      : complete
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: current ? AppColors.navy : color,
                  size: 18,
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: complete ? AppColors.cyan : AppColors.line,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18, top: 2),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: current
                      ? AppColors.navy
                      : complete
                      ? AppColors.muted
                      : AppColors.muted,
                  fontWeight: current ? FontWeight.w800 : FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AjouterCommande extends StatelessWidget {
  const AjouterCommande({
    super.key,
    required this.orderNumber,
    required this.onSave,
  });
  final String orderNumber;
  final ValueChanged<ManagedOrder> onSave;

  @override
  Widget build(BuildContext context) =>
      _OrderFormPage(orderNumber: orderNumber, onSave: onSave);
}

class ModifierCommande extends StatelessWidget {
  const ModifierCommande({
    super.key,
    required this.order,
    required this.onSave,
  });
  final ManagedOrder order;
  final ValueChanged<ManagedOrder> onSave;

  @override
  Widget build(BuildContext context) =>
      _OrderFormPage(orderNumber: order.id, existing: order, onSave: onSave);
}

class _OrderFormPage extends StatefulWidget {
  const _OrderFormPage({
    required this.orderNumber,
    required this.onSave,
    this.existing,
  });
  final String orderNumber;
  final ManagedOrder? existing;
  final ValueChanged<ManagedOrder> onSave;

  @override
  State<_OrderFormPage> createState() => _OrderFormPageState();
}

class _OrderFormPageState extends State<_OrderFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _resident;
  late final TextEditingController _apartment;
  late final TextEditingController _locker;
  late final TextEditingController _weight;
  late final TextEditingController _quantity;
  late final TextEditingController _price;
  late final TextEditingController _notes;
  late String _laundryType;
  late String _laundryCompany;
  late String _driver;
  late String _status;
  late DateTime _collection;
  late DateTime _delivery;

  @override
  void initState() {
    super.initState();
    final order = widget.existing;
    _resident = TextEditingController(text: order?.resident ?? '');
    _apartment = TextEditingController(text: order?.apartment ?? '');
    _locker = TextEditingController(text: order?.locker ?? '');
    _weight = TextEditingController(text: order?.weight.toString() ?? '');
    _quantity = TextEditingController(text: order?.quantity.toString() ?? '1');
    _price = TextEditingController(text: order?.price.toString() ?? '');
    _notes = TextEditingController(text: order?.notes ?? '');
    _laundryType = order?.laundryType ?? 'Linge quotidien';
    _laundryCompany = order?.laundryCompany ?? 'Pressing Express';
    _driver = order?.driverName ?? 'Non affecté';
    _status = order?.status ?? 'Nouvelle';
    _collection =
        order?.collectionAt ?? DateTime.now().add(const Duration(hours: 2));
    _delivery =
        order?.deliveryAt ?? DateTime.now().add(const Duration(days: 2));
  }

  @override
  void dispose() {
    _resident.dispose();
    _apartment.dispose();
    _locker.dispose();
    _weight.dispose();
    _quantity.dispose();
    _price.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text(
            editing
                ? 'Modifier ${widget.orderNumber}'
                : 'Nouvelle commande ${widget.orderNumber}',
            style: const TextStyle(
              fontSize: 21,
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          OrderPanel(
            title: 'Informations résidant',
            children: [
              _formField(_resident, 'Résident', required: true),
              _formField(_apartment, 'Appartement', required: true),
              _formField(_locker, 'Casier', required: true),
            ],
          ),
          OrderPanel(
            title: 'Détails du linge',
            children: [
              _dropdownField('Type de linge', _laundryType, const [
                'Linge quotidien',
                'Linge délicat',
                'Draps et serviettes',
                'Linge de maison',
              ], (v) => setState(() => _laundryType = v)),
              _formField(
                _quantity,
                'Quantité (pièces)',
                required: true,
                numeric: true,
              ),
              _formField(_weight, 'Poids (kg)', required: true, numeric: true),
              _dropdownField('Société de lavage', _laundryCompany, const [
                'Pressing Express',
                'EcoClean Laundry',
                'Pressing Plus',
              ], (v) => setState(() => _laundryCompany = v)),
            ],
          ),
          OrderPanel(
            title: 'Livraison et tarif',
            children: [
              _dropdownField('Livreur', _driver, [
                'Non affecté',
                ...demoDeliveryDrivers
                    .where((d) => d.status != 'Hors service')
                    .map((d) => d.name),
              ], (v) => setState(() => _driver = v)),
              if (editing)
                _dropdownField(
                  'Statut',
                  _status,
                  orderStatuses,
                  (v) => setState(() => _status = v),
                ),
              _dateField(
                'Date de collecte',
                _collection,
                (v) => setState(() => _collection = v),
              ),
              _dateField(
                'Date prévue de livraison',
                _delivery,
                (v) => setState(() => _delivery = v),
              ),
              _formField(_price, 'Prix (TND)', required: true, numeric: true),
              _formField(_notes, 'Remarque', maxLines: 3),
            ],
          ),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check_rounded),
            label: Text(
              editing ? 'Enregistrer les modifications' : 'Créer la commande',
            ),
          ),
        ],
      ),
    );
  }

  Widget _formField(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool numeric = false,
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: numeric
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : null,
      validator: required
          ? (value) => value == null || value.trim().isEmpty
                ? 'Champ obligatoire'
                : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.cream,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  Widget _dropdownField(
    String label,
    String value,
    List<String> items,
    ValueChanged<String> onChanged,
  ) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.cream,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: items
          .map(
            (v) => DropdownMenuItem(
              value: v,
              child: Text(v, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    ),
  );

  Widget _dateField(
    String label,
    DateTime date,
    ValueChanged<DateTime> onChanged,
  ) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      tileColor: AppColors.cream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.muted),
      ),
      subtitle: Text(
        '${formatOrderDate(date)} · ${formatOrderTime(date)}',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      trailing: const Icon(Icons.calendar_month_outlined),
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (pickedDate == null || !mounted) return;
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(date),
        );
        if (pickedTime != null) {
          onChanged(
            DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            ),
          );
        }
      },
    ),
  );

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final old = widget.existing;
    final weight = double.tryParse(_weight.text.trim());
    final price = double.tryParse(_price.text.trim());
    final quantity = int.tryParse(_quantity.text.trim());
    if (weight == null || price == null || quantity == null || quantity < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vérifiez le poids, le prix et la quantité.'),
        ),
      );
      return;
    }
    if (_delivery.isBefore(_collection)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La livraison doit être prévue après la collecte.'),
        ),
      );
      return;
    }
    widget.onSave(
      ManagedOrder(
        id: widget.orderNumber,
        resident: _resident.text.trim(),
        apartment: _apartment.text.trim(),
        locker: _locker.text.trim(),
        laundryCompany: _laundryCompany,
        status: _status,
        laundryType: _laundryType,
        quantity: quantity,
        weight: weight,
        createdAt: old?.createdAt ?? DateTime.now(),
        collectionAt: _collection,
        deliveryAt: _delivery,
        price: price,
        driverName: _driver == 'Non affecté' ? null : _driver,
        notes: _notes.text.trim(),
        collectionCompletedAt: old?.collectionCompletedAt,
        departureAt: old?.departureAt,
        doorClosed: old?.doorClosed ?? true,
        iotConnected: old?.iotConnected ?? true,
        lastSync: old?.lastSync ?? formatOrderTime(DateTime.now()),
      ),
    );
  }
}

class AffecterLivreur extends StatefulWidget {
  const AffecterLivreur({
    super.key,
    required this.order,
    required this.drivers,
    required this.orders,
    required this.onAssign,
  });
  final ManagedOrder order;
  final List<DeliveryDriver> drivers;
  final List<ManagedOrder> orders;
  final ValueChanged<String> onAssign;

  @override
  State<AffecterLivreur> createState() => _AffecterLivreurState();
}

class _AffecterLivreurState extends State<AffecterLivreur> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.order.driverName;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          'Affecter un livreur · ${widget.order.id}',
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${widget.order.resident} · ${widget.order.locker}',
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 14),
        for (var index = 0; index < widget.drivers.length; index++)
          _DriverOption(
            driver: widget.drivers[index],
            selected: _selected == widget.drivers[index].name,
            activeCount: widget.orders
                .where(
                  (o) =>
                      o.driverName == widget.drivers[index].name && o.isActive,
                )
                .length,
            distance: const ['1,2 km', '2,8 km', '4,1 km'][index % 3],
            onTap: () => setState(() => _selected = widget.drivers[index].name),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed:
              _selected == null ||
                  widget.drivers.every(
                    (d) => d.name != _selected || d.status == 'Hors service',
                  )
              ? null
              : () => widget.onAssign(_selected!),
          icon: const Icon(Icons.assignment_turned_in_outlined),
          label: const Text('Confirmer l’affectation'),
        ),
      ],
    );
  }
}

class _DriverOption extends StatelessWidget {
  const _DriverOption({
    required this.driver,
    required this.selected,
    required this.activeCount,
    required this.distance,
    required this.onTap,
  });
  final DeliveryDriver driver;
  final bool selected;
  final int activeCount;
  final String distance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = getDriverStatus(driver);
    final available = status != 'Indisponible';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppColors.cyan : AppColors.line,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: available ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? AppColors.cyan : AppColors.muted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            driver.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        OrderStatusBadge(status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Livraisons en cours : $activeCount\nDistance : $distance · Commandes affectées : ${driver.deliveriesCompleted}',
                      style: const TextStyle(fontSize: 11, height: 1.6),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ListeLivraisons extends StatelessWidget {
  const ListeLivraisons({
    super.key,
    required this.orders,
    required this.onOpenDelivery,
  });
  final List<ManagedOrder> orders;
  final ValueChanged<ManagedOrder> onOpenDelivery;

  @override
  Widget build(BuildContext context) {
    final deliveryOrders = orders
        .where(
          (o) => [
            'En livraison',
            'Prête',
            'Livrée',
            'En attente',
          ].contains(o.status),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const Text(
          'Livraisons',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Suivi des départs vers les casiers de résidence.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        for (final order in deliveryOrders)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.line),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onOpenDelivery(order),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.id,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                        OrderStatusBadge(_deliveryStatus(order)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      order.resident,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Livreur : ${order.driverName ?? 'À affecter'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                    Text(
                      'Départ : ${order.laundryCompany}  →  Destination : ${order.locker}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                    Text(
                      'Départ ${order.departureAt == null ? 'à confirmer' : formatOrderTime(order.departureAt!)} · Arrivée prévue ${formatOrderTime(order.deliveryAt)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                    if (order.status == 'En livraison') ...[
                      const SizedBox(height: 9),
                      const LinearProgressIndicator(value: .66, minHeight: 5),
                      const SizedBox(height: 5),
                      const Text(
                        'Suivi en cours · environ 1,4 km restant',
                        style: TextStyle(fontSize: 10, color: AppColors.muted),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _deliveryStatus(ManagedOrder order) {
    if (order.status == 'Livrée') return 'Livrée';
    if (order.status == 'En livraison' &&
        order.deliveryAt.isBefore(DateTime.now())) {
      return 'En retard';
    }
    if (order.status == 'En livraison') return 'En cours';
    return 'En attente';
  }
}

class DetailsLivraison extends StatelessWidget {
  const DetailsLivraison({super.key, required this.order});
  final ManagedOrder order;

  @override
  Widget build(BuildContext context) {
    final steps = [
      'Commande récupérée',
      'Départ du livreur',
      'Livraison en cours',
      'Livraison terminée',
    ];
    final active = order.status == 'Livrée'
        ? 3
        : order.status == 'En livraison'
        ? 2
        : 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          order.id,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        OrderPanel(
          title: 'Livraison',
          children: [
            OrderInfoTile(label: 'Commande', value: order.id),
            OrderInfoTile(
              label: 'Livreur',
              value: order.driverName ?? 'Non affecté',
            ),
            OrderInfoTile(label: 'Résident', value: order.resident),
            OrderInfoTile(
              label: 'Destination',
              value: 'Résidence · Casier ${order.locker}',
            ),
            OrderInfoTile(label: 'Statut', value: order.status),
          ],
        ),
        OrderPanel(
          title: 'Étapes',
          children: [
            for (var i = 0; i < steps.length; i++)
              _TimelineRow(
                label: steps[i],
                complete: i < active,
                current: i == active,
                last: i == steps.length - 1,
              ),
          ],
        ),
        OrderPanel(
          title: 'Estimation de suivi',
          children: [
            OrderInfoTile(
              label: 'Heure de départ',
              value: order.departureAt == null
                  ? 'À confirmer'
                  : formatOrderTime(order.departureAt!),
            ),
            OrderInfoTile(
              label: 'Heure prévue',
              value: formatOrderTime(order.deliveryAt),
            ),
            OrderInfoTile(
              label: 'Heure actuelle',
              value: formatOrderTime(DateTime.now()),
            ),
            OrderInfoTile(
              label: 'Distance restante',
              value: order.status == 'Livrée' ? '0 km' : 'Environ 1,4 km',
            ),
          ],
        ),
        const SizedBox(height: 6),
        FilledButton.icon(
          onPressed: order.driverName == null
              ? null
              : () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Contacter le livreur'),
                    content: Text(
                      'Livreur : ${order.driverName}\nTéléphone de démonstration : +216 55 123 456',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Fermer'),
                      ),
                    ],
                  ),
                ),
          icon: const Icon(Icons.call_outlined),
          label: const Text('Contacter le livreur'),
        ),
      ],
    );
  }
}

class HistoriqueCommandes extends StatelessWidget {
  const HistoriqueCommandes({
    super.key,
    required this.entries,
    required this.orderId,
  });
  final List<OrderHistoryEntry> entries;
  final String orderId;

  @override
  Widget build(BuildContext context) {
    final selected = entries.where((entry) => entry.orderId == orderId).toList()
      ..sort((a, b) => b.at.compareTo(a.at));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          'Historique · $orderId',
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        if (selected.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text('Aucune action enregistrée pour cette commande.'),
            ),
          )
        else
          for (final entry in selected)
            Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 9),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: const BorderSide(color: AppColors.line),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.history_rounded,
                  color: AppColors.cyan,
                ),
                title: Text(
                  entry.action,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${formatOrderDate(entry.at)} · ${formatOrderTime(entry.at)}\n${entry.description}\nPar ${entry.user}',
                  style: const TextStyle(height: 1.5, fontSize: 11),
                ),
                isThreeLine: true,
              ),
            ),
      ],
    );
  }
}

class AlertesCommandes extends StatelessWidget {
  const AlertesCommandes({
    super.key,
    required this.orders,
    required this.drivers,
  });
  final List<ManagedOrder> orders;
  final List<DeliveryDriver> drivers;

  @override
  Widget build(BuildContext context) {
    final alerts = <_OrderAlert>[];
    for (final order in orders) {
      if (order.status == 'En livraison' &&
          order.deliveryAt.isBefore(DateTime.now())) {
        alerts.add(
          _OrderAlert(
            order,
            'Livraison en retard',
            'Retard estimé : 25 minutes',
            'Élevée',
          ),
        );
      }
      if (order.isActive && order.driverName == null) {
        alerts.add(
          _OrderAlert(
            order,
            'Commande sans livreur',
            'Une affectation est nécessaire.',
            'Moyenne',
          ),
        );
      }
      if (order.isActive &&
          order.status == 'En attente' &&
          DateTime.now().difference(order.createdAt).inHours > 24) {
        alerts.add(
          _OrderAlert(
            order,
            'Commande bloquée',
            'La commande attend une collecte depuis plus de 24 heures.',
            'Élevée',
          ),
        );
      }
      if (order.status == 'En lavage' &&
          DateTime.now()
                  .difference(order.collectionCompletedAt ?? order.createdAt)
                  .inHours >
              8) {
        alerts.add(
          _OrderAlert(
            order,
            'Délai de lavage dépassé',
            'La commande est au lavage depuis plus de 8 heures.',
            'Élevée',
          ),
        );
      }
      final assignedDriver = drivers.where(
        (driver) => driver.name == order.driverName,
      );
      if (order.isActive &&
          assignedDriver.isNotEmpty &&
          assignedDriver.first.status == 'Hors service') {
        alerts.add(
          _OrderAlert(
            order,
            'Livreur indisponible',
            'Le livreur affecté est actuellement hors service.',
            'Élevée',
          ),
        );
      }
    }
    alerts.add(
      _OrderAlert(
        orders.first,
        'Anomalie de suivi',
        'La dernière position reçue n’a pas été mise à jour.',
        'Faible',
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const Text(
          'Alertes et anomalies',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Événements nécessitant une vérification par l’administrateur.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 14),
        for (final alert in alerts)
          Card(
            elevation: 0,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.line),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFE45858),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          alert.title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      OrderStatusBadge(alert.severity),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Commande : ${alert.order.id}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Livreur : ${alert.order.driverName ?? 'Non affecté'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    alert.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${formatOrderDate(DateTime.now())} · ${formatOrderTime(DateTime.now())} · Nouvelle',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _OrderAlert {
  const _OrderAlert(this.order, this.title, this.description, this.severity);
  final ManagedOrder order;
  final String title;
  final String description;
  final String severity;
}

class StatistiquesCommandes extends StatelessWidget {
  const StatistiquesCommandes({
    super.key,
    required this.orders,
    required this.drivers,
  });
  final List<ManagedOrder> orders;
  final List<DeliveryDriver> drivers;

  @override
  Widget build(BuildContext context) {
    final delivered = orders.where((o) => o.status == 'Livrée').length;
    final cancelled = orders.where((o) => o.status == 'Annulée').length;
    final late = orders
        .where(
          (o) =>
              o.status == 'En livraison' &&
              o.deliveryAt.isBefore(DateTime.now()),
        )
        .length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const Text(
          'Statistiques',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        OrderPanel(
          title: 'Commandes par jour',
          children: [
            const Text(
              'Cette semaine',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: _SimpleBarChart(
                values: const [3, 5, 4, 7, 6, 9, 5],
                labels: const ['L', 'M', 'M', 'J', 'V', 'S', 'D'],
              ),
            ),
          ],
        ),
        OrderPanel(
          title: 'Commandes par semaine',
          children: [
            const SizedBox(
              height: 100,
              child: _SimpleBarChart(
                values: [12, 18, 15, 24],
                labels: ['S-3', 'S-2', 'S-1', 'Act.'],
              ),
            ),
          ],
        ),
        Card(
          elevation: 0,
          color: const Color(0xFFEAF3FF),
          child: const ListTile(
            leading: Icon(Icons.auto_awesome_rounded, color: AppColors.navy),
            title: Text(
              'Prévision de la demande',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              'Période de forte activité estimée entre 17 h et 19 h.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.65,
          children: [
            _DashboardMetric(
              'Commandes livrées',
              '$delivered',
              Icons.task_alt_rounded,
              AppColors.cyan,
            ),
            _DashboardMetric(
              'Commandes annulées',
              '$cancelled',
              Icons.cancel_outlined,
              const Color(0xFFE45858),
            ),
            _DashboardMetric(
              'Temps moyen livraison',
              '1 h 25',
              Icons.schedule_rounded,
              AppColors.navy,
            ),
            _DashboardMetric(
              'Temps de traitement',
              '5 h 40',
              Icons.timelapse_rounded,
              const Color(0xFF7457E8),
            ),
            _DashboardMetric(
              'Retards',
              '$late',
              Icons.warning_amber_rounded,
              const Color(0xFFE77B32),
            ),
          ],
        ),
        const SizedBox(height: 14),
        OrderPanel(
          title: 'Performance des livreurs',
          children: [
            for (final driver in drivers)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            driver.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          '${driver.deliveriesCompleted} livraisons · ${driver.rating}/5',
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: (driver.rating / 5).clamp(0, 1),
                      color: AppColors.cyan,
                      backgroundColor: AppColors.line,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SimpleBarChart extends StatelessWidget {
  const _SimpleBarChart({required this.values, required this.labels});
  final List<int> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.reduce((a, b) => a > b ? a : b).toDouble();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var index = 0; index < values.length; index++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${values[index]}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: FractionallySizedBox(
                      heightFactor: values[index] / maxValue,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withValues(alpha: .75),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    labels[index],
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class ConfirmationAnnulation extends StatefulWidget {
  const ConfirmationAnnulation({super.key, required this.order});
  final ManagedOrder order;

  @override
  State<ConfirmationAnnulation> createState() => _ConfirmationAnnulationState();
}

class _ConfirmationAnnulationState extends State<ConfirmationAnnulation> {
  String _reason = 'Demande du résident';

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Annuler la commande ?'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Voulez-vous vraiment annuler la commande ${widget.order.id} ?'),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _reason,
          decoration: const InputDecoration(
            labelText: 'Motif',
            border: OutlineInputBorder(),
          ),
          items:
              const [
                    'Demande du résident',
                    'Problème de livraison',
                    'Problème de linge',
                    'Autre',
                  ]
                  .map(
                    (reason) =>
                        DropdownMenuItem(value: reason, child: Text(reason)),
                  )
                  .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _reason = value);
          },
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE45858)),
        onPressed: () => Navigator.pop(context, _reason),
        child: const Text('Confirmer l’annulation'),
      ),
    ],
  );
}
