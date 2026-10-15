class Machine {
  final String id;
  final String societeId;
  final String nom;
  final String type; // 'Lave-linge', 'Sèche-linge', 'Nettoyage Écologique'
  String statut; // 'Disponible', 'En cycle', 'Maintenance', 'Hors service'
  final double capaciteKg; // Capacité tambour en kg (ex: 15.0 kg)
  double progressionCycle; // 0.0 à 1.0
  int tempsRestantMinutes;
  double temperatureC;
  double vibrationLevel;
  double consommationKwh;
  int santeIot; // 0 à 100

  String? programmeActuel; // Ex: 'Éco 30°C'

  Machine({
    required this.id,
    required this.societeId,
    required this.nom,
    required this.type,
    required this.statut,
    this.capaciteKg = 15.0,
    this.progressionCycle = 0.0,
    this.tempsRestantMinutes = 0,
    this.temperatureC = 30.0,
    this.vibrationLevel = 1.2,
    this.consommationKwh = 1.5,
    this.santeIot = 95,
    this.programmeActuel,
  });

  Machine copyWith({
    String? id,
    String? societeId,
    String? nom,
    String? type,
    String? statut,
    double? capaciteKg,
    double? progressionCycle,
    int? tempsRestantMinutes,
    double? temperatureC,
    double? vibrationLevel,
    double? consommationKwh,
    int? santeIot,
    String? programmeActuel,
  }) {
    return Machine(
      id: id ?? this.id,
      societeId: societeId ?? this.societeId,
      nom: nom ?? this.nom,
      type: type ?? this.type,
      statut: statut ?? this.statut,
      capaciteKg: capaciteKg ?? this.capaciteKg,
      progressionCycle: progressionCycle ?? this.progressionCycle,
      tempsRestantMinutes: tempsRestantMinutes ?? this.tempsRestantMinutes,
      temperatureC: temperatureC ?? this.temperatureC,
      vibrationLevel: vibrationLevel ?? this.vibrationLevel,
      consommationKwh: consommationKwh ?? this.consommationKwh,
      santeIot: santeIot ?? this.santeIot,
      programmeActuel: programmeActuel ?? this.programmeActuel,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'societeId': societeId,
      'nom': nom,
      'type': type,
      'statut': statut,
      'capaciteKg': capaciteKg,
      'progressionCycle': progressionCycle,
      'tempsRestantMinutes': tempsRestantMinutes,
      'temperatureC': temperatureC,
      'vibrationLevel': vibrationLevel,
      'consommationKwh': consommationKwh,
      'santeIot': santeIot,
      'programmeActuel': programmeActuel,
    };
  }

  factory Machine.fromMap(Map<String, Object?> map) {
    return Machine(
      id: map['id'] as String,
      societeId: map['societeId'] as String,
      nom: map['nom'] as String,
      type: map['type'] as String,
      statut: map['statut'] as String,
      capaciteKg: (map['capaciteKg'] as num?)?.toDouble() ?? 15.0,
      progressionCycle: (map['progressionCycle'] as num?)?.toDouble() ?? 0.0,
      tempsRestantMinutes: (map['tempsRestantMinutes'] as num?)?.toInt() ?? 0,
      temperatureC: (map['temperatureC'] as num?)?.toDouble() ?? 30.0,
      vibrationLevel: (map['vibrationLevel'] as num?)?.toDouble() ?? 1.2,
      consommationKwh: (map['consommationKwh'] as num?)?.toDouble() ?? 1.5,
      santeIot: (map['santeIot'] as num?)?.toInt() ?? 95,
      programmeActuel: map['programmeActuel'] as String?,
    );
  }
}
