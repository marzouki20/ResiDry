class Residence {
  const Residence({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.address = '',
    this.city = '',
  });

  final String id;
  final String name;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final double radius;
}

const availableResidences = <Residence>[
  Residence(
    id: 'residence_emna',
    name: 'Résidence Emna',
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
