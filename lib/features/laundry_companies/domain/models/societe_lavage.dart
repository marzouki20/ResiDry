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
}
