class LavageOrder {
  final String id;
  final String residentName;
  final String casierId;
  final double poidsKg;
  final String typeService;
  String statut; // 'En attente', 'En cours de lavage', 'Prêt pour retour casier'
  final DateTime dateReception;
  String? machineAttribuee;

  LavageOrder({
    required this.id,
    required this.residentName,
    required this.casierId,
    required this.poidsKg,
    required this.typeService,
    required this.statut,
    required this.dateReception,
    this.machineAttribuee,
  });

  LavageOrder copyWith({
    String? id,
    String? residentName,
    String? casierId,
    double? poidsKg,
    String? typeService,
    String? statut,
    DateTime? dateReception,
    String? machineAttribuee,
  }) {
    return LavageOrder(
      id: id ?? this.id,
      residentName: residentName ?? this.residentName,
      casierId: casierId ?? this.casierId,
      poidsKg: poidsKg ?? this.poidsKg,
      typeService: typeService ?? this.typeService,
      statut: statut ?? this.statut,
      dateReception: dateReception ?? this.dateReception,
      machineAttribuee: machineAttribuee ?? this.machineAttribuee,
    );
  }
}

final List<LavageOrder> initialLavageOrders = [
  LavageOrder(
    id: 'CMD-108',
    residentName: 'Yassine Ben Ali',
    casierId: 'Casier C-04',
    poidsKg: 4.5,
    typeService: 'Lavage 40°C & Essorage',
    statut: 'En cours de lavage',
    dateReception: DateTime.now().subtract(const Duration(minutes: 35)),
    machineAttribuee: 'EcoDrum Pro 01',
  ),
  LavageOrder(
    id: 'CMD-109',
    residentName: 'Nour Trabelsi',
    casierId: 'Casier C-12',
    poidsKg: 3.2,
    typeService: 'Nettoyage Délicat',
    statut: 'En attente',
    dateReception: DateTime.now().subtract(const Duration(minutes: 15)),
  ),
  LavageOrder(
    id: 'CMD-110',
    residentName: 'Mohamed Khalil',
    casierId: 'Casier C-24',
    poidsKg: 6.0,
    typeService: 'Lavage & Séchage Express',
    statut: 'Prêt pour retour casier',
    dateReception: DateTime.now().subtract(const Duration(hours: 2)),
    machineAttribuee: 'TurboDry Ultra 02',
  ),
  LavageOrder(
    id: 'CMD-111',
    residentName: 'Sarra Mansouri',
    casierId: 'Casier C-08',
    poidsKg: 5.0,
    typeService: 'Nettoyage Écologique Vapeur',
    statut: 'En attente',
    dateReception: DateTime.now().subtract(const Duration(minutes: 5)),
  ),
];
