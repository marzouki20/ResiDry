class DeliveryDriver {
  DeliveryDriver({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.status = 'En service',
    this.vehicleType = 'Scooter',
    this.rating = 4.9,
    this.assignedZone = 'Résidence Les Palmiers',
    this.deliveriesCompleted = 42,
  });

  final String id;
  String name;
  String email;
  String phone;
  String status; // 'En service', 'En livraison', 'Hors service'
  String vehicleType;
  double rating;
  String assignedZone;
  int deliveriesCompleted;

  factory DeliveryDriver.fromMap(Map<String, dynamic> map) {
    return DeliveryDriver(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      status: map['status'] as String? ?? 'En service',
      vehicleType: map['vehicleType'] as String? ?? 'Scooter',
      rating: (map['rating'] as num?)?.toDouble() ?? 4.9,
      assignedZone: map['assignedZone'] as String? ?? 'Résidence Les Palmiers',
      deliveriesCompleted: map['deliveriesCompleted'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'status': status,
      'vehicleType': vehicleType,
      'rating': rating,
      'assignedZone': assignedZone,
      'deliveriesCompleted': deliveriesCompleted,
    };
  }
}

final demoDeliveryDrivers = <DeliveryDriver>[
  DeliveryDriver(
    id: 'LIV-001',
    name: 'Aymen Abdellatif',
    email: 'aymen@residry.tn',
    phone: '+216 55 123 456',
    status: 'En service',
    vehicleType: 'Scooter électrique',
    rating: 4.9,
    assignedZone: 'Résidence Université',
    deliveriesCompleted: 68,
  ),
  DeliveryDriver(
    id: 'LIV-002',
    name: 'Sami Karray',
    email: 'sami.karray@residry.tn',
    phone: '+216 98 765 432',
    status: 'En livraison',
    vehicleType: 'Camionnette',
    rating: 4.8,
    assignedZone: 'Résidence Les Jardins',
    deliveriesCompleted: 112,
  ),
  DeliveryDriver(
    id: 'LIV-003',
    name: 'Youssef Mansouri',
    email: 'youssef@residry.tn',
    phone: '+216 22 334 455',
    status: 'Hors service',
    vehicleType: 'Scooter',
    rating: 4.7,
    assignedZone: 'Résidence Les Palmiers',
    deliveriesCompleted: 35,
  ),
];
