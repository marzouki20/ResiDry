/// Représente une résidence enregistrée dans la table SQLite `residences`.
class Residence {
  const Residence({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.radius,
  });

  final String id;
  final String name;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final double radius;

  Map<String, Object> toMap() => {
    'id': id,
    'name': name,
    'address': address,
    'city': city,
    'latitude': latitude,
    'longitude': longitude,
    'radius': radius,
  };

  factory Residence.fromMap(Map<String, Object?> map) => Residence(
    id: map['id']! as String,
    name: map['name']! as String,
    address: map['address']! as String,
    city: map['city']! as String,
    latitude: (map['latitude']! as num).toDouble(),
    longitude: (map['longitude']! as num).toDouble(),
    radius: (map['radius']! as num).toDouble(),
  );
}

/// Données initiales insérées une seule fois au premier démarrage.
const defaultResidences = <Residence>[
  Residence(
    id: 'esprit_school_of_engineering',
    name: 'ESPRIT School of Engineering (ESE)',
    address:
        '1, 2 rue André Ampère, Pôle Technologique El Ghazala, 2083 Ariana',
    city: 'Ariana',
    latitude: 36.899256,
    longitude: 10.189198,
    radius: 300,
  ),
  Residence(
    id: 'residence_emna',
    name: 'Résidence Emna',
    address: '',
    city: '',
    latitude: 36.896306,
    longitude: 10.178056,
    radius: 300,
  ),
  Residence(
    id: 'residence_tej_el_molk',
    name: 'Résidence Tej El Molk',
    address: 'Ennasr 2, Ariana',
    city: 'Ariana',
    latitude: 36.862401,
    longitude: 10.151072,
    radius: 300,
  ),
  Residence(
    id: 'residence_turquoise',
    name: 'Résidence Turquoise',
    address: 'Rue du Docteur Khaled Gorgob, Ennasr 2',
    city: 'Ariana',
    latitude: 36.857280,
    longitude: 10.155890,
    radius: 300,
  ),
  Residence(
    id: 'residence_le_sultan',
    name: 'Résidence Le Sultan',
    address: 'Ennasr 2, Ariana',
    city: 'Ariana',
    latitude: 36.857920,
    longitude: 10.161640,
    radius: 300,
  ),
  Residence(
    id: 'terrasses_soukra',
    name: 'Terrasses de la Soukra',
    address: 'La Soukra, Ariana',
    city: 'Ariana',
    latitude: 36.871940,
    longitude: 10.280620,
    radius: 300,
  ),
  Residence(
    id: 'residence_marwa',
    name: 'Résidence Marwa',
    address: 'La Soukra',
    city: 'La Soukra',
    latitude: 36.873320,
    longitude: 10.238480,
    radius: 300,
  ),
  Residence(
    id: 'casa_marwa',
    name: 'Casa Marwa',
    address: 'Rue du Parc, Dar Fadhal, La Soukra',
    city: 'La Soukra',
    latitude: 36.875390,
    longitude: 10.245480,
    radius: 300,
  ),
  Residence(
    id: 'residence_aziza',
    name: 'Résidence Aziza',
    address: 'La Soukra',
    city: 'La Soukra',
    latitude: 36.875170,
    longitude: 10.274730,
    radius: 300,
  ),
  Residence(
    id: 'residence_khadija',
    name: 'Résidence Khadija',
    address: 'Chotrana 1, La Soukra',
    city: 'La Soukra',
    latitude: 36.880905727291,
    longitude: 10.228507317791,
    radius: 300,
  ),
];
