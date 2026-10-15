import 'machine.dart';

class SocieteLavage {
  final String id;
  final String nom;
  final String adresse;
  final String telephone;
  final String email;
  final String statut; // 'Actif', 'Sous Maintenance', 'Inactif'
  final DateTime datePartenariat;
  final double noteEvaluation; // e.g. 4.8 / 5.0
  final int capaciteMaxKg;
  final int iotHealthScore; // 0 to 100
  final String description;
  final List<Machine> machines;

  SocieteLavage({
    required this.id,
    required this.nom,
    required this.adresse,
    required this.telephone,
    required this.email,
    required this.statut,
    required this.datePartenariat,
    this.noteEvaluation = 4.5,
    this.capaciteMaxKg = 120,
    this.iotHealthScore = 95,
    this.description = '',
    required this.machines,
  });

  SocieteLavage copyWith({
    String? id,
    String? nom,
    String? adresse,
    String? telephone,
    String? email,
    String? statut,
    DateTime? datePartenariat,
    double? noteEvaluation,
    int? capaciteMaxKg,
    int? iotHealthScore,
    String? description,
    List<Machine>? machines,
  }) {
    return SocieteLavage(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      adresse: adresse ?? this.adresse,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      statut: statut ?? this.statut,
      datePartenariat: datePartenariat ?? this.datePartenariat,
      noteEvaluation: noteEvaluation ?? this.noteEvaluation,
      capaciteMaxKg: capaciteMaxKg ?? this.capaciteMaxKg,
      iotHealthScore: iotHealthScore ?? this.iotHealthScore,
      description: description ?? this.description,
      machines: machines ?? this.machines,
    );
  }

  int get activeMachinesCount =>
      machines.where((m) => m.statut == 'Disponible' || m.statut == 'En cycle').length;

  int get runningCyclesCount =>
      machines.where((m) => m.statut == 'En cycle').length;

  /// Somme des capacités de TOUTES les machines installées dans l'atelier (kg)
  double get capaciteTotaleInstallee =>
      machines.fold(0.0, (sum, m) => sum + m.capaciteKg);

  /// Capacité immédiatement opérationnelle (uniquement machines DISPONIBLES)
  double get capaciteDisponibleKg =>
      machines.where((m) => m.statut == 'Disponible').fold(0.0, (sum, m) => sum + m.capaciteKg);

  /// Capacité actuellement occupée par des cycles en cours
  double get capaciteEnCycleKg =>
      machines.where((m) => m.statut == 'En cycle').fold(0.0, (sum, m) => sum + m.capaciteKg);

  /// Capacité immobilisée en panne ou maintenance
  double get capaciteIndisponibleKg =>
      machines.where((m) => m.statut == 'Maintenance' || m.statut == 'Hors service').fold(0.0, (sum, m) => sum + m.capaciteKg);

  /// Taux de disponibilité opérationnelle (0.0 à 1.0)
  double get tauxDisponibilite =>
      capaciteTotaleInstallee <= 0 ? 0.0 : (capaciteDisponibleKg / capaciteTotaleInstallee);

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'nom': nom,
      'adresse': adresse,
      'telephone': telephone,
      'email': email,
      'statut': statut,
      'datePartenariat': datePartenariat.toIso8601String(),
      'noteEvaluation': noteEvaluation,
      'capaciteMaxKg': capaciteMaxKg,
      'iotHealthScore': iotHealthScore,
      'description': description,
    };
  }

  factory SocieteLavage.fromMap(
    Map<String, Object?> map, {
    List<Machine> machines = const [],
  }) {
    return SocieteLavage(
      id: map['id'] as String,
      nom: map['nom'] as String,
      adresse: map['adresse'] as String,
      telephone: map['telephone'] as String,
      email: map['email'] as String,
      statut: map['statut'] as String,
      datePartenariat: DateTime.tryParse(map['datePartenariat'] as String? ?? '') ??
          DateTime(2023, 1, 1),
      noteEvaluation: (map['noteEvaluation'] as num?)?.toDouble() ?? 4.5,
      capaciteMaxKg: (map['capaciteMaxKg'] as num?)?.toInt() ?? 120,
      iotHealthScore: (map['iotHealthScore'] as num?)?.toInt() ?? 95,
      description: map['description'] as String? ?? '',
      machines: machines,
    );
  }
}
