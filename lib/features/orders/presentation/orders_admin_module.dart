import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/delivery_driver.dart';
import '../../../database/database.dart';
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
  late final Future<List<ManagedOrder>> _ordersFuture = _loadOrders();
  List<ManagedOrder> _orders = [];
  late final List<DeliveryDriver> _drivers = demoDeliveryDrivers
      .map((driver) => DeliveryDriver.fromMap(driver.toMap()))
      .toList();
  final List<OrderHistoryEntry> _history = List.of(orderHistorySeed);

  static List<ManagedOrder> _rowsToOrders(List<Map<String, Object?>> rows) {
    return rows.map((row) {
      return ManagedOrder(
        id: row['id'] as String,
        resident: row['nom_resident'] as String,
        apartment: row['appartement'] as String,
        locker: row['casier'] as String,
        laundryCompany: row['societe_lavage'] as String,
        status: row['statut'] as String,
        laundryType: row['type_linge'] as String,
        quantity: (row['quantite'] as num).toInt(),
        weight: (row['poids'] as num).toDouble(),
        createdAt: DateTime.parse(row['date_creation'] as String),
        collectionAt: DateTime.parse(row['date_collecte'] as String),
        deliveryAt: DateTime.parse(row['date_livraison'] as String),
        price: (row['prix'] as num).toDouble(),
        driverName: row['nom_livreur'] as String?,
        notes: row['notes'] as String? ?? '',
        collectionCompletedAt:
            row['date_collecte_terminee'] != null
                ? DateTime.parse(row['date_collecte_terminee'] as String)
                : null,
        departureAt: row['date_depart'] != null
            ? DateTime.parse(row['date_depart'] as String)
            : null,
        doorClosed: (row['porte_fermee'] as int) == 1,
        iotConnected: (row['iot_connecte'] as int) == 1,
        lastSync: row['derniere_synchronisation'] as String? ?? '',
      );
    }).toList(growable: false);
  }

  static Map<String, Object?> _orderToRow(ManagedOrder order) => <String, Object?>{
        'id': order.id,
        'nom_resident': order.resident,
        'appartement': order.apartment,
        'casier': order.locker,
        'societe_lavage': order.laundryCompany,
        'statut': order.status,
        'type_linge': order.laundryType,
        'quantite': order.quantity,
        'poids': order.weight,
        'date_creation': order.createdAt.toIso8601String(),
        'date_collecte': order.collectionAt.toIso8601String(),
        'date_livraison': order.deliveryAt.toIso8601String(),
        'prix': order.price,
        'nom_livreur': order.driverName,
        'notes': order.notes,
        'date_collecte_terminee':
            order.collectionCompletedAt?.toIso8601String(),
        'date_depart': order.departureAt?.toIso8601String(),
        'porte_fermee': order.doorClosed ? 1 : 0,
        'iot_connecte': order.iotConnected ? 1 : 0,
        'derniere_synchronisation': order.lastSync,
      };

  Future<List<ManagedOrder>> _loadOrders() async {
    final rows = await AppDatabase.instance.getAllCommandes();
    if (rows.isEmpty) {
      await _seedDemoOrders();
    }
    final freshRows = await AppDatabase.instance.getAllCommandes();
    return _rowsToOrders(freshRows);
  }

  Future<void> _seedDemoOrders() async {
    for (final order in demoManagedOrders) {
      await AppDatabase.instance.insertCommande(_orderToRow(order));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadOrders().then((loaded) {
      if (mounted) setState(() => _orders = loaded);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ManagedOrder>>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        _orders = snapshot.data ?? [];
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
      },
    );
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
    await AppDatabase.instance.insertCommande(_orderToRow(order));
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
    await AppDatabase.instance.updateCommande(_orderToRow(updated), updated.id);
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
    await AppDatabase.instance.updateCommande(_orderToRow(order), order.id);
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
    await AppDatabase.instance.updateCommande(_orderToRow(order), order.id);
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
