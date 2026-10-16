import 'package:flutter/material.dart';

import '../../../models/delivery_driver.dart';

const orderStatuses = [
  'Nouvelle',
  'En attente',
  'Collecte prévue',
  'Collectée',
  'En lavage',
  'Lavage terminé',
  'Prête',
  'En livraison',
  'Livrée',
  'Annulée',
];

class ManagedOrder {
  ManagedOrder({
    required this.id,
    required this.resident,
    required this.apartment,
    required this.locker,
    required this.laundryCompany,
    required this.status,
    required this.laundryType,
    required this.quantity,
    required this.weight,
    required this.createdAt,
    required this.collectionAt,
    required this.deliveryAt,
    required this.price,
    this.driverName,
    this.notes = '',
    this.collectionCompletedAt,
    this.departureAt,
    this.doorClosed = true,
    this.iotConnected = true,
    this.lastSync = '18:42',
  });

  final String id;
  String resident;
  String apartment;
  String locker;
  String laundryCompany;
  String status;
  String laundryType;
  int quantity;
  double weight;
  DateTime createdAt;
  DateTime collectionAt;
  DateTime deliveryAt;
  double price;
  String? driverName;
  String notes;
  DateTime? collectionCompletedAt;
  DateTime? departureAt;
  bool doorClosed;
  bool iotConnected;
  String lastSync;

  bool get isActive => status != 'Livrée' && status != 'Annulée';
}

class OrderHistoryEntry {
  const OrderHistoryEntry({
    required this.orderId,
    required this.action,
    required this.description,
    required this.at,
    required this.user,
  });

  final String orderId;
  final String action;
  final String description;
  final DateTime at;
  final String user;
}

final demoManagedOrders = <ManagedOrder>[
  ManagedOrder(
    id: 'CMD-1024',
    resident: 'Mohamed Ali',
    apartment: 'A-204',
    locker: 'C-024',
    laundryCompany: 'Pressing Express',
    status: 'En livraison',
    laundryType: 'Linge quotidien',
    quantity: 8,
    weight: 4.2,
    createdAt: DateTime(2026, 10, 7, 9, 12),
    collectionAt: DateTime(2026, 10, 7, 10),
    deliveryAt: DateTime(2026, 10, 7, 18),
    price: 24.5,
    driverName: 'Aymen Abdellatif',
    notes: 'Déposer dans le casier après confirmation.',
    collectionCompletedAt: DateTime(2026, 10, 7, 10, 18),
    departureAt: DateTime(2026, 10, 7, 17, 35),
  ),
  ManagedOrder(
    id: 'CMD-1023',
    resident: 'Sara Benali',
    apartment: 'B-105',
    locker: 'C-017',
    laundryCompany: 'EcoClean Laundry',
    status: 'En lavage',
    laundryType: 'Linge délicat',
    quantity: 5,
    weight: 3.8,
    createdAt: DateTime(2026, 10, 7, 8, 25),
    collectionAt: DateTime(2026, 10, 7, 9, 30),
    deliveryAt: DateTime(2026, 10, 8, 16),
    price: 31.0,
    driverName: 'Aymen Abdellatif',
    notes: 'Lavage à froid.',
    collectionCompletedAt: DateTime(2026, 10, 7, 9, 42),
  ),
  ManagedOrder(
    id: 'CMD-1022',
    resident: 'Yassine Amrani',
    apartment: 'A-310',
    locker: 'C-031',
    laundryCompany: 'Pressing Plus',
    status: 'Prête',
    laundryType: 'Draps et serviettes',
    quantity: 6,
    weight: 4.5,
    createdAt: DateTime(2026, 10, 6, 15, 20),
    collectionAt: DateTime(2026, 10, 6, 16),
    deliveryAt: DateTime(2026, 10, 7, 20),
    price: 28.0,
    driverName: 'Sami Karray',
    notes: '',
    collectionCompletedAt: DateTime(2026, 10, 6, 16, 11),
  ),
  ManagedOrder(
    id: 'CMD-1021',
    resident: 'Lina Haddad',
    apartment: 'C-206',
    locker: 'C-012',
    laundryCompany: 'Pressing Express',
    status: 'Collectée',
    laundryType: 'Linge quotidien',
    quantity: 7,
    weight: 3.1,
    createdAt: DateTime(2026, 10, 7, 7, 40),
    collectionAt: DateTime(2026, 10, 7, 8, 30),
    deliveryAt: DateTime(2026, 10, 8, 14),
    price: 19.5,
    driverName: 'Sami Karray',
    collectionCompletedAt: DateTime(2026, 10, 7, 8, 48),
  ),
  ManagedOrder(
    id: 'CMD-1018',
    resident: 'Nour Trabelsi',
    apartment: 'D-102',
    locker: 'C-008',
    laundryCompany: 'EcoClean Laundry',
    status: 'Livrée',
    laundryType: 'Linge de maison',
    quantity: 4,
    weight: 5.0,
    createdAt: DateTime(2026, 10, 5, 11, 10),
    collectionAt: DateTime(2026, 10, 5, 12),
    deliveryAt: DateTime(2026, 10, 6, 18),
    price: 35.0,
    driverName: 'Aymen Abdellatif',
    collectionCompletedAt: DateTime(2026, 10, 5, 12, 12),
    departureAt: DateTime(2026, 10, 6, 17, 20),
  ),
  ManagedOrder(
    id: 'CMD-1015',
    resident: 'Amine Gharbi',
    apartment: 'B-202',
    locker: 'C-019',
    laundryCompany: 'Pressing Plus',
    status: 'En attente',
    laundryType: 'Linge quotidien',
    quantity: 3,
    weight: 2.4,
    createdAt: DateTime(2026, 10, 7, 13, 5),
    collectionAt: DateTime(2026, 10, 7, 19),
    deliveryAt: DateTime(2026, 10, 9, 17),
    price: 16.0,
    notes: 'Commande déposée, livreur à affecter.',
  ),
  ManagedOrder(
    id: 'CMD-1012',
    resident: 'Meriem Saidi',
    apartment: 'A-108',
    locker: 'C-006',
    laundryCompany: 'Pressing Express',
    status: 'Annulée',
    laundryType: 'Linge délicat',
    quantity: 2,
    weight: 1.8,
    createdAt: DateTime(2026, 10, 4, 9, 0),
    collectionAt: DateTime(2026, 10, 4, 12),
    deliveryAt: DateTime(2026, 10, 5, 17),
    price: 14.0,
    notes: 'Annulée à la demande du résident.',
  ),
];

/// Notifies the order-management screens when a resident creates a command.
final demoManagedOrdersRevision = ValueNotifier<int>(0);

void addManagedOrder(ManagedOrder order) {
  demoManagedOrders.insert(0, order);
  demoManagedOrdersRevision.value++;
}

final orderHistorySeed = <OrderHistoryEntry>[
  OrderHistoryEntry(
    orderId: 'CMD-1024',
    action: 'Début de livraison',
    description: 'Le livreur a quitté la blanchisserie.',
    at: DateTime(2026, 10, 7, 17, 35),
    user: 'Aymen Abdellatif',
  ),
  OrderHistoryEntry(
    orderId: 'CMD-1024',
    action: 'Lavage terminé',
    description: 'Commande prête pour le retour en résidence.',
    at: DateTime(2026, 10, 7, 16, 50),
    user: 'Pressing Express',
  ),
  OrderHistoryEntry(
    orderId: 'CMD-1021',
    action: 'Collecte',
    description: 'Linge récupéré au casier C-012.',
    at: DateTime(2026, 10, 7, 8, 48),
    user: 'Sami Karray',
  ),
];

Color orderStatusColor(String status) => switch (status) {
  'Nouvelle' || 'En attente' => const Color(0xFFE77B32),
  'Collecte prévue' || 'Collectée' || 'En livraison' => const Color(0xFF2674C8),
  'En lavage' => const Color(0xFF7457E8),
  'Lavage terminé' || 'Prête' || 'Livrée' => const Color(0xFF159A86),
  'Annulée' => const Color(0xFFE45858),
  _ => const Color(0xFF5F6F97),
};

String formatOrderDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

String formatOrderTime(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

String getDriverStatus(DeliveryDriver driver) => switch (driver.status) {
  'En service' => 'Disponible',
  'En livraison' => 'En livraison',
  _ => 'Indisponible',
};
