import '../../../database/database.dart';
import '../domain/models/machine.dart';
import '../domain/models/societe_lavage.dart';

final List<SocieteLavage> initialSocietesLavage = [
  SocieteLavage(
    id: 'SOC-001',
    nom: 'EcoWash Express Premium',
    adresse: 'Résidence Les Jasmins, Bloc B - Tunis',
    telephone: '+216 71 234 567',
    email: 'contact@ecowash.tn',
    statut: 'Actif',
    datePartenariat: DateTime(2023, 5, 15),
    noteEvaluation: 4.9,
    capaciteMaxKg: 45,
    iotHealthScore: 98,
    description: 'Partenaire certifié écologique spécialisé dans les textiles délicats et lavage rapide.',
    machines: [
      Machine(
        id: 'MCH-101',
        societeId: 'SOC-001',
        nom: 'EcoDrum Pro 01',
        type: 'Lave-linge',
        statut: 'Disponible',
        capaciteKg: 15.0,
        progressionCycle: 0.0,
        tempsRestantMinutes: 0,
        temperatureC: 24.0,
        vibrationLevel: 0.3,
        consommationKwh: 0.2,
        santeIot: 98,
      ),
      Machine(
        id: 'MCH-102',
        societeId: 'SOC-001',
        nom: 'TurboDry Ultra 02',
        type: 'Sèche-linge',
        statut: 'Disponible',
        capaciteKg: 10.0,
        progressionCycle: 0.0,
        tempsRestantMinutes: 0,
        temperatureC: 22.0,
        vibrationLevel: 0.2,
        consommationKwh: 0.1,
        santeIot: 96,
      ),
      Machine(
        id: 'MCH-103',
        societeId: 'SOC-001',
        nom: 'GreenClean Steam 03',
        type: 'Nettoyage Écologique',
        statut: 'Disponible',
        capaciteKg: 20.0,
        progressionCycle: 0.0,
        tempsRestantMinutes: 0,
        temperatureC: 25.0,
        vibrationLevel: 0.4,
        consommationKwh: 0.3,
        santeIot: 100,
      ),
    ],
  ),
  SocieteLavage(
    id: 'SOC-002',
    nom: 'Clean&Dry Residence Service',
    adresse: 'Avenue Habib Bourguiba, Ariana',
    telephone: '+216 70 987 654',
    email: 'info@cleandry.tn',
    statut: 'Actif',
    datePartenariat: DateTime(2023, 9, 1),
    noteEvaluation: 4.7,
    capaciteMaxKg: 40,
    iotHealthScore: 92,
    description: 'Service de blanchisserie industrielle à grande capacité avec supervision IoT en temps réel.',
    machines: [
      Machine(
        id: 'MCH-201',
        societeId: 'SOC-002',
        nom: 'IndusWash 500',
        type: 'Lave-linge',
        statut: 'En cycle',
        capaciteKg: 25.0,
        progressionCycle: 0.40,
        tempsRestantMinutes: 25,
        temperatureC: 60.0,
        vibrationLevel: 2.1,
        consommationKwh: 2.4,
        santeIot: 91,
      ),
      Machine(
        id: 'MCH-202',
        societeId: 'SOC-002',
        nom: 'SmartDryer 300',
        type: 'Sèche-linge',
        statut: 'Maintenance',
        capaciteKg: 15.0,
        progressionCycle: 0.0,
        tempsRestantMinutes: 0,
        temperatureC: 19.0,
        vibrationLevel: 0.0,
        consommationKwh: 0.0,
        santeIot: 68,
      ),
    ],
  ),
  SocieteLavage(
    id: 'SOC-003',
    nom: 'Azur Lavage & Pressing',
    adresse: 'Les Berges du Lac 2, Tunis',
    telephone: '+216 71 888 999',
    email: 'support@azurlavage.tn',
    statut: 'Sous Maintenance',
    datePartenariat: DateTime(2024, 1, 10),
    noteEvaluation: 4.4,
    capaciteMaxKg: 18,
    iotHealthScore: 78,
    description: 'Spécialiste du soin haute couture, pressing éco-responsable et repassage de précision.',
    machines: [
      Machine(
        id: 'MCH-301',
        societeId: 'SOC-003',
        nom: 'Azur Pressing V2',
        type: 'Nettoyage Écologique',
        statut: 'Maintenance',
        capaciteKg: 18.0,
        progressionCycle: 0.0,
        tempsRestantMinutes: 0,
        temperatureC: 18.0,
        vibrationLevel: 0.0,
        consommationKwh: 0.0,
        santeIot: 78,
      ),
    ],
  ),
];

class LaundryRepository {
  LaundryRepository._();
  static final LaundryRepository instance = LaundryRepository._();

  final List<SocieteLavage> societes = List<SocieteLavage>.of(initialSocietesLavage);
  bool _isInitialized = false;

  /// Charge et synchronise les sociétés et machines depuis la base de données locale SQLite
  Future<void> initDatabase() async {
    if (_isInitialized) return;
    try {
      final dbSocietes = await AppDatabase.instance.getAllSocietes();
      if (dbSocietes.isNotEmpty) {
        societes
          ..clear()
          ..addAll(dbSocietes);
      }
      _isInitialized = true;
    } catch (_) {
      // Fallback sécurisé en mémoire en cas d'accès initial
    }
  }

  SocieteLavage findSocieteForUser(String? userName) {
    if (userName != null && userName.trim().isNotEmpty) {
      final query = userName.trim().toLowerCase();
      for (final s in societes) {
        if (s.nom.toLowerCase().contains(query) ||
            query.contains(s.nom.toLowerCase()) ||
            s.email.toLowerCase().contains(query)) {
          return s;
        }
      }
    }
    if (societes.isNotEmpty) {
      return societes.first;
    }
    final defaultSoc = SocieteLavage(
      id: 'SOC-001',
      nom: (userName != null && userName.trim().isNotEmpty)
          ? '$userName Pressing'
          : 'EcoWash Express Premium',
      adresse: 'Résidence Les Jasmins, Bloc B - Tunis',
      telephone: '+216 71 234 567',
      email: 'contact@ecowash.tn',
      statut: 'Actif',
      datePartenariat: DateTime(2023, 5, 15),
      noteEvaluation: 4.9,
      capaciteMaxKg: 45,
      iotHealthScore: 98,
      description: 'Partenaire certifié écologique spécialisé dans les textiles délicats.',
      machines: [
        Machine(
          id: 'MCH-101',
          societeId: 'SOC-001',
          nom: 'EcoDrum Pro 01',
          type: 'Lave-linge',
          statut: 'Disponible',
          capaciteKg: 15.0,
          progressionCycle: 0.0,
          tempsRestantMinutes: 0,
          temperatureC: 22.0,
          vibrationLevel: 0.2,
          consommationKwh: 0.1,
          santeIot: 98,
        ),
      ],
    );
    societes.add(defaultSoc);
    AppDatabase.instance.saveSociete(defaultSoc);
    return defaultSoc;
  }

  void updateSociete(SocieteLavage updated) {
    final index = societes.indexWhere((s) => s.id == updated.id);
    if (index != -1) {
      societes[index] = updated;
    } else {
      societes.add(updated);
    }
    // Persistance SQLite
    AppDatabase.instance.saveSociete(updated);
  }

  void deleteSociete(String id) {
    societes.removeWhere((s) => s.id == id);
    // Persistance SQLite
    AppDatabase.instance.deleteSociete(id);
  }

  void saveMachine(Machine machine) {
    final sIndex = societes.indexWhere((s) => s.id == machine.societeId);
    if (sIndex != -1) {
      final s = societes[sIndex];
      final mList = List<Machine>.of(s.machines);
      final mIndex = mList.indexWhere((m) => m.id == machine.id);
      if (mIndex != -1) {
        mList[mIndex] = machine;
      } else {
        mList.insert(0, machine);
      }
      societes[sIndex] = s.copyWith(machines: mList);
    }
    // Persistance SQLite
    AppDatabase.instance.saveMachine(machine);
  }

  void deleteMachine(String machineId, String societeId) {
    final sIndex = societes.indexWhere((s) => s.id == societeId);
    if (sIndex != -1) {
      final s = societes[sIndex];
      final mList = List<Machine>.of(s.machines)..removeWhere((m) => m.id == machineId);
      societes[sIndex] = s.copyWith(machines: mList);
    }
    // Persistance SQLite
    AppDatabase.instance.deleteMachine(machineId);
  }
}
