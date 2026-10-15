class ResidentProfile {
  const ResidentProfile({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.residenceName,
    required this.residenceAddress,
    required this.city,
    required this.postalCode,
    required this.apartmentNumber,
    required this.floor,
    required this.status,
  });

  final int? id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String residenceName;
  final String residenceAddress;
  final String city;
  final String postalCode;
  final String apartmentNumber;
  final String floor;
  final String status;

  String get fullName => '$firstName $lastName';
  String get initials => '${firstName[0]}${lastName[0]}';

  ResidentProfile copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? residenceName,
    String? residenceAddress,
    String? city,
    String? postalCode,
    String? apartmentNumber,
    String? floor,
    String? status,
  }) {
    return ResidentProfile(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      residenceName: residenceName ?? this.residenceName,
      residenceAddress: residenceAddress ?? this.residenceAddress,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      apartmentNumber: apartmentNumber ?? this.apartmentNumber,
      floor: floor ?? this.floor,
      status: status ?? this.status,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'residence_name': residenceName,
      'residence_address': residenceAddress,
      'city': city,
      'postal_code': postalCode,
      'apartment_number': apartmentNumber,
      'floor': floor,
      'status': status,
    };
  }

  factory ResidentProfile.fromMap(Map<String, Object?> map) {
    return ResidentProfile(
      id: map['id'] as int?,
      firstName: map['first_name'] as String? ?? '',
      lastName: map['last_name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      residenceName: map['residence_name'] as String? ?? '',
      residenceAddress: map['residence_address'] as String? ?? '',
      city: map['city'] as String? ?? '',
      postalCode: map['postal_code'] as String? ?? '',
      apartmentNumber: map['apartment_number'] as String? ?? '',
      floor: map['floor'] as String? ?? '',
      status: map['status'] as String? ?? 'Active',
    );
  }
}

const demoResidentProfile = ResidentProfile(
  id: 1,
  firstName: 'Mohamed Raed',
  lastName: 'Boukari',
  email: 'raed@example.com',
  phone: '+216 20 123 456',
  residenceName: 'ResiDry Residence',
  residenceAddress: '72 Rue de la Maison',
  city: 'Tunis',
  postalCode: '1000',
  apartmentNumber: 'A-204',
  floor: '2',
  status: 'Active',
);

const secondDemoResidentProfile = ResidentProfile(
  id: 2,
  firstName: 'Sarra',
  lastName: 'Ben Ali',
  email: 'sarra@example.com',
  phone: '+216 21 654 321',
  residenceName: 'ResiDry Residence',
  residenceAddress: '72 Rue de la Maison',
  city: 'Tunis',
  postalCode: '1000',
  apartmentNumber: 'B-101',
  floor: '1',
  status: 'Active',
);

class LaundryRequest {
  const LaundryRequest({
    required this.requestNumber,
    required this.creationDate,
    required this.pickupDate,
    required this.quantity,
    required this.status,
    required this.amount,
    required this.locker,
    required this.progressIndex,
  });

  final String requestNumber;
  final String creationDate;
  final String pickupDate;
  final String quantity;
  final String status;
  final String amount;
  final String locker;
  final int progressIndex;
}

const List<String> laundryStatusTimeline = <String>[
  'New',
  'Collection',
  'Processing',
  'Ready',
  'Delivered',
];

final List<LaundryRequest> demoLaundryRequests = <LaundryRequest>[
  const LaundryRequest(
    requestNumber: '#LD-2048',
    creationDate: '12 Jun 2026',
    pickupDate: '14 Jun 2026',
    quantity: '4 kg',
    status: 'Processing',
    amount: '16.00 TND',
    locker: 'L-18',
    progressIndex: 2,
  ),
  const LaundryRequest(
    requestNumber: '#LD-2037',
    creationDate: '9 Jun 2026',
    pickupDate: '11 Jun 2026',
    quantity: '3.5 kg',
    status: 'Ready',
    amount: '13.50 TND',
    locker: 'L-07',
    progressIndex: 3,
  ),
  const LaundryRequest(
    requestNumber: '#LD-2024',
    creationDate: '5 Jun 2026',
    pickupDate: '7 Jun 2026',
    quantity: '5 kg',
    status: 'Delivered',
    amount: '18.00 TND',
    locker: 'L-14',
    progressIndex: 4,
  ),
  const LaundryRequest(
    requestNumber: '#LD-2012',
    creationDate: '3 Jun 2026',
    pickupDate: '5 Jun 2026',
    quantity: '2.5 kg',
    status: 'Collection',
    amount: '10.50 TND',
    locker: 'L-09',
    progressIndex: 1,
  ),
];

class NotificationItem {
  const NotificationItem({
    required this.icon,
    required this.title,
    required this.message,
    required this.dateTime,
    required this.isRead,
  });

  final String icon;
  final String title;
  final String message;
  final String dateTime;
  final bool isRead;
}

final List<NotificationItem> demoNotifications = <NotificationItem>[
  const NotificationItem(
    icon: 'local_laundry_service',
    title: 'Laundry cycle updated',
    message: 'Your request #LD-2037 is ready for collection at locker L-07.',
    dateTime: 'Today, 09:30',
    isRead: false,
  ),
  const NotificationItem(
    icon: 'person',
    title: 'Profile reminder',
    message:
        'Please confirm your residence and contact details are up to date.',
    dateTime: 'Yesterday, 18:15',
    isRead: false,
  ),
  const NotificationItem(
    icon: 'door_front_door',
    title: 'Locker assigned',
    message: 'Your locker access code is now active. Keep it private.',
    dateTime: 'Mon, 14:05',
    isRead: true,
  ),
];

class LockerAssignment {
  const LockerAssignment({
    required this.number,
    required this.location,
    required this.status,
    required this.assignmentDate,
    required this.accessCode,
  });

  final String number;
  final String location;
  final String status;
  final String assignmentDate;
  final String accessCode;
}

const demoLockerAssignment = LockerAssignment(
  number: 'L-07',
  location: 'Basement 1 • Laundry area',
  status: 'Assigned',
  assignmentDate: '12 Jun 2026',
  accessCode: '4729',
);
