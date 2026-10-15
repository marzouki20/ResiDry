enum LaundryStatus {
  deposited,
  processing,
  ready,
  delivered,
}

class LaundryItem {
  final String id;
  final String residentName;
  final String serviceType;
  final LaundryStatus status;
  final double price;

  LaundryItem({
    required this.id,
    required this.residentName,
    required this.serviceType,
    required this.status,
    required this.price,
  });

  LaundryItem copyWith({
    String? id,
    String? residentName,
    String? serviceType,
    LaundryStatus? status,
    double? price,
  }) {
    return LaundryItem(
      id: id ?? this.id,
      residentName: residentName ?? this.residentName,
      serviceType: serviceType ?? this.serviceType,
      status: status ?? this.status,
      price: price ?? this.price,
    );
  }
}