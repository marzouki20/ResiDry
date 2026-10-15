class DeliveryOrder {
  DeliveryOrder({
    required this.id,
    required this.residentName,
    required this.apartment,
    required this.lockerId,
    required this.laundryCompany,
    required this.status,
    required this.type,
    this.weight = 5.2,
    required this.time,
    this.driverName,
    this.notes,
  });

  final String id;
  final String residentName;
  final String apartment;
  final String lockerId;
  final String laundryCompany;
  String
      status; // 'À récupérer', 'En transit', 'En lavage', 'En transit retour', 'Déposé au casier', 'Livré'
  final String
      type; // 'Collecte' (Casier -> Blanchisserie) or 'Livraison' (Blanchisserie -> Casier)
  double weight;
  String time;
  String? driverName;
  String? notes;

  factory DeliveryOrder.fromMap(Map<String, Object?> map) {
    return DeliveryOrder(
      id: map['id']! as String,
      residentName: map['resident_name']! as String,
      apartment: map['apartment']! as String,
      lockerId: map['locker_id']! as String,
      laundryCompany: map['laundry_company']! as String,
      status: map['status']! as String,
      type: map['mission_type']! as String,
      weight: (map['weight_kg']! as num).toDouble(),
      time: map['scheduled_label']! as String,
      driverName: map['driver_name'] as String?,
      notes: map['notes'] as String?,
    );
  }
}

final demoDeliveryOrders = <DeliveryOrder>[
  DeliveryOrder(
    id: 'CMD-101',
    residentName: 'Mohamed Khalil',
    apartment: 'A-204',
    lockerId: 'C-024',
    laundryCompany: 'Pressing Express',
    status: 'À récupérer',
    type: 'Collecte',
    weight: 5.2,
    time: 'Aujourd’hui · 14:00',
    driverName: 'Aymen Abdellatif',
    notes: 'Linge délicat - Récupération au casier C-024',
  ),
  DeliveryOrder(
    id: 'CMD-102',
    residentName: 'Sara Benali',
    apartment: 'B-105',
    lockerId: 'C-017',
    laundryCompany: 'EcoClean Laundry',
    status: 'En transit',
    type: 'Collecte',
    weight: 3.8,
    time: 'Aujourd’hui · 13:30',
    driverName: 'Aymen Abdellatif',
    notes: 'Acheminement vers EcoClean',
  ),
  DeliveryOrder(
    id: 'CMD-103',
    residentName: 'Yassine Amrani',
    apartment: 'A-310',
    lockerId: 'C-031',
    laundryCompany: 'Pressing Plus',
    status: 'En transit retour',
    type: 'Livraison',
    weight: 4.5,
    time: 'Aujourd’hui · 15:15',
    driverName: 'Aymen Abdellatif',
    notes: 'Dépot de linge propre prévu dans casier C-031',
  ),
  DeliveryOrder(
    id: 'CMD-098',
    residentName: 'Lina Haddad',
    apartment: 'C-206',
    lockerId: 'C-012',
    laundryCompany: 'Pressing Express',
    status: 'Déposé au casier',
    type: 'Livraison',
    weight: 3.1,
    time: 'Hier · 18:20',
    driverName: 'Sami Karray',
    notes: 'Livré et casier verrouillé',
  ),
];
