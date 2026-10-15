enum LaundryStatus { deposited, processing, ready, delivered }

extension LaundryStatusLabel on LaundryStatus {
  String get label => switch (this) {
    LaundryStatus.deposited => 'Déposé',
    LaundryStatus.processing => 'En traitement',
    LaundryStatus.ready => 'Prêt',
    LaundryStatus.delivered => 'Livré',
  };
}

class LaundryItem {
  final String id;
  final int? residentId;
  final String residentName;
  final String serviceType;
  final LaundryStatus status;
  final double price;
  final bool priceConfirmed;
  final DateTime createdAt;

  LaundryItem({
    required this.id,
    this.residentId,
    required this.residentName,
    required this.serviceType,
    required this.status,
    required this.price,
    this.priceConfirmed = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toUtc();

  Map<String, Object?> toMap() => {
    'id': id,
    'resident_id': residentId,
    'resident_name': residentName,
    'service_type': serviceType,
    'status': status.name,
    'price': price,
    'price_confirmed': priceConfirmed ? 1 : 0,
    'created_at': createdAt.toUtc().toIso8601String(),
  };

  factory LaundryItem.fromMap(Map<String, Object?> map) => LaundryItem(
    id: map['id'] as String,
    residentId: map['resident_id'] as int?,
    residentName: map['resident_name'] as String,
    serviceType: map['service_type'] as String,
    status: LaundryStatus.values.byName(map['status'] as String),
    price: (map['price'] as num).toDouble(),
    priceConfirmed: map['price_confirmed'] == 1,
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  LaundryItem copyWith({
    String? id,
    int? residentId,
    String? residentName,
    String? serviceType,
    LaundryStatus? status,
    double? price,
    bool? priceConfirmed,
  }) => LaundryItem(
    id: id ?? this.id,
    residentId: residentId ?? this.residentId,
    residentName: residentName ?? this.residentName,
    serviceType: serviceType ?? this.serviceType,
    status: status ?? this.status,
    price: price ?? this.price,
    priceConfirmed: priceConfirmed ?? this.priceConfirmed,
    createdAt: createdAt,
  );
}
