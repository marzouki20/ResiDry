class Machine {
  final String id;
  final String societeId;
  final String nom;
  final String type; // 'Lave-linge', 'Sèche-linge', 'Nettoyage Écologique'
  String statut; // 'Disponible', 'En cycle', 'Maintenance', 'Hors service'
  double progressionCycle; // 0.0 à 1.0
  int tempsRestantMinutes;
  double temperatureC;
  double vibrationLevel;
  double consommationKwh;
  int santeIot; // 0 à 100

  Machine({
    required this.id,
    required this.societeId,
    required this.nom,
    required this.type,
    required this.statut,
    this.progressionCycle = 0.0,
    this.tempsRestantMinutes = 0,
    this.temperatureC = 30.0,
    this.vibrationLevel = 1.2,
    this.consommationKwh = 1.5,
    this.santeIot = 95,
  });

  Machine copyWith({
    String? id,
    String? societeId,
    String? nom,
    String? type,
    String? statut,
    double? progressionCycle,
    int? tempsRestantMinutes,
    double? temperatureC,
    double? vibrationLevel,
    double? consommationKwh,
    int? santeIot,
  }) {
    return Machine(
      id: id ?? this.id,
      societeId: societeId ?? this.societeId,
      nom: nom ?? this.nom,
      type: type ?? this.type,
      statut: statut ?? this.statut,
      progressionCycle: progressionCycle ?? this.progressionCycle,
      tempsRestantMinutes: tempsRestantMinutes ?? this.tempsRestantMinutes,
      temperatureC: temperatureC ?? this.temperatureC,
      vibrationLevel: vibrationLevel ?? this.vibrationLevel,
      consommationKwh: consommationKwh ?? this.consommationKwh,
      santeIot: santeIot ?? this.santeIot,
    );
  }
}
