enum LaundryStatus {
  deposited,
  processing,
  ready,
  delivered,
}

class LaundryItem {
  final String id;
  final int? residentId;
  final String residentName;
  final String serviceType;
  final LaundryStatus status;
  final double price;

  LaundryItem({
    required this.id,
    this.residentId,
    required this.residentName,
    required this.serviceType,
    required this.status,
    required this.price,
  });

  LaundryItem copyWith({
    String? id,
    int? residentId,
    String? residentName,
    String? serviceType,
    LaundryStatus? status,
    double? price,
  }) {
    return LaundryItem(
      id: id ?? this.id,
      residentId: residentId ?? this.residentId,
      residentName: residentName ?? this.residentName,
      serviceType: serviceType ?? this.serviceType,
      status: status ?? this.status,
      price: price ?? this.price,
    );
  }
}