import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/delivery_driver.dart';
import 'order_data.dart';
import 'order_pages.dart';

class OrdersAdminModule extends StatefulWidget {
  const OrdersAdminModule({
    super.key,
    this.userName,
    required this.selectedIndex,
    required this.onNavigate,
  });

  final String? userName;
  final int selectedIndex;
  final ValueChanged<int> onNavigate;

  @override
  State<OrdersAdminModule> createState() => _OrdersAdminModuleState();
}

class _OrdersAdminModuleState extends State<OrdersAdminModule> {
  late final List<ManagedOrder> _orders = demoManagedOrders
      .map(_copyOrder)
      .toList();
  late final List<DeliveryDriver> _drivers = demoDeliveryDrivers
      .map((driver) => DeliveryDriver.fromMap(driver.toMap()))
      .toList();
  final List<OrderHistoryEntry> _history = List.of(orderHistorySeed);

  static ManagedOrder _copyOrder(ManagedOrder order) => ManagedOrder(
    id: order.id,
    resident: order.resident,
    apartment: order.apartment,
    locker: order.locker,
    laundryCompany: order.laundryCompany,
    status: order.status,
    laundryType: order.laundryType,
    quantity: order.quantity,
    weight: order.weight,
    createdAt: order.createdAt,
    collectionAt: order.collectionAt,
    deliveryAt: order.deliveryAt,
    price: order.price,
    driverName: order.driverName,
    notes: order.notes,
    collectionCompletedAt: order.collectionCompletedAt,
    departureAt: order.departureAt,
    doorClosed: order.doorClosed,
    iotConnected: order.iotConnected,
    lastSync: order.lastSync,
  );

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardCommandes(
        orders: _orders,
        userName: widget.userName ?? 'Administrateur',
        onOpenOrders: () => widget.onNavigate(1),
        onOpenDeliveries: () => widget.onNavigate(2),
        onOpenAlerts: () => widget.onNavigate(3),
        onOpenStats: _openStatistics,
        onOpenOrder: _openOrder,
      ),
      ListeCommandes(
        orders: _orders,
        drivers: _drivers,
        onOpenOrder: _openOrder,
        onCreate: _createOrder,
      ),
      ListeLivraisons(orders: _orders, onOpenDelivery: _openDelivery),
      AlertesCommandes(orders: _orders, drivers: _drivers),
    ];

    return IndexedStack(index: widget.selectedIndex, children: pages);
  }

  String _newOrderId() {
    var highest = 0;
    for (final order in _orders) {
      final number = int.tryParse(order.id.replaceFirst('CMD-', ''));
      if (number != null && number > highest) highest = number;
    }
    return 'CMD-${highest + 1}';
  }

  Future<void> _createOrder() async {
    final order = await Navigator.of(context).push<ManagedOrder>(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: _subpageAppBar('Ajouter une commande'),
          body: AjouterCommande(
            orderNumber: _newOrderId(),
            onSave: (order) => Navigator.pop(context, order),
          ),
        ),
      ),
    );
    if (!mounted || order == null) return;
    setState(() {
      _orders.add(order);
      _history.insert(
        0,
        OrderHistoryEntry(
          orderId: order.id,
          action: 'Création de commande',
          description: 'Commande créée pour ${order.resident}.',
          at: DateTime.now(),
          user: widget.userName ?? 'Administrateur',
        ),
      );
    });
    _showMessage('Commande ${order.id} créée avec succès.');
  }

  Future<void> _editOrder(ManagedOrder order) async {
    final updated = await Navigator.of(context).push<ManagedOrder>(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: _subpageAppBar('Modifier la commande'),
          body: ModifierCommande(
            order: order,
            onSave: (value) => Navigator.pop(context, value),
          ),
        ),
      ),
    );
    if (!mounted || updated == null) return;
    setState(() {
      final index = _orders.indexWhere((item) => item.id == updated.id);
      if (index != -1) _orders[index] = updated;
      _history.insert(
        0,
        OrderHistoryEntry(
          orderId: updated.id,
          action: 'Modification',
          description: 'Informations de la commande mises à jour.',
          at: DateTime.now(),
          user: widget.userName ?? 'Administrateur',
        ),
      );
    });
    _showMessage('Modifications enregistrées.');
  }

  Future<void> _assignDriver(ManagedOrder order) async {
    final driverName = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: _subpageAppBar('Affecter un livreur'),
          body: AffecterLivreur(
            order: order,
            drivers: _drivers,
            orders: _orders,
            onAssign: (name) => Navigator.pop(context, name),
          ),
        ),
      ),
    );
    if (!mounted || driverName == null) return;
    setState(() {
      order.driverName = driverName;
      if (order.status == 'Nouvelle' || order.status == 'En attente') {
        order.status = 'Collecte prévue';
      }
      _history.insert(
        0,
        OrderHistoryEntry(
          orderId: order.id,
          action: 'Affectation livreur',
          description: 'Commande affectée à $driverName.',
          at: DateTime.now(),
          user: widget.userName ?? 'Administrateur',
        ),
      );
    });
    _showMessage('$driverName affecté à la commande ${order.id}.');
  }

  Future<void> _cancelOrder(ManagedOrder order) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => ConfirmationAnnulation(order: order),
    );
    if (!mounted || reason == null) return;
    setState(() {
      order.status = 'Annulée';
      order.notes = order.notes.isEmpty
          ? 'Motif : $reason'
          : '${order.notes}\nMotif d’annulation : $reason';
      _history.insert(
        0,
        OrderHistoryEntry(
          orderId: order.id,
          action: 'Annulation',
          description: 'Commande annulée. Motif : $reason.',
          at: DateTime.now(),
          user: widget.userName ?? 'Administrateur',
        ),
      );
    });
    _showMessage('Commande ${order.id} annulée.');
  }

  Future<void> _openOrder(ManagedOrder order) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: _subpageAppBar('Détails de la commande'),
          body: DetailsCommande(
            order: order,
            history: _history,
            onEdit: () => _editOrder(order),
            onAssign: () => _assignDriver(order),
            onDelivery: () => _openDelivery(order),
            onHistory: () => _openHistory(order),
            onCancel: () => _cancelOrder(order),
          ),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openDelivery(ManagedOrder order) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: _subpageAppBar('Détails de la livraison'),
            body: DetailsLivraison(order: order),
          ),
        ),
      );

  Future<void> _openHistory(ManagedOrder order) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: _subpageAppBar('Historique des commandes'),
            body: HistoriqueCommandes(entries: _history, orderId: order.id),
          ),
        ),
      );

  Future<void> _openStatistics() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: _subpageAppBar('Statistiques des commandes'),
        body: StatistiquesCommandes(orders: _orders, drivers: _drivers),
      ),
    ),
  );

  AppBar _subpageAppBar(String title) => AppBar(
    title: Text(
      title,
      style: const TextStyle(
        color: AppColors.navy,
        fontWeight: FontWeight.w800,
      ),
    ),
    backgroundColor: AppColors.cream,
    surfaceTintColor: Colors.transparent,
  );

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
