library residry.orders.domain.models.garment;

class Garment {
  const Garment({
    required this.id,
    required this.commandeId,
    this.residentId,
    required this.typeVetement,
    this.taille,
    this.couleur,
    this.rfidTagId,
    this.statut = 'En attente',
    required this.dateEnregistrement,
  });

  final String id;
  final String commandeId;
  final String? residentId;
  final String typeVetement;
  final String? taille;
  final String? couleur;
  final String? rfidTagId;
  final String statut;
  final DateTime dateEnregistrement;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'commande_id': commandeId,
    'resident_id': residentId,
    'type_vetement': typeVetement,
    'taille': taille,
    'couleur': couleur,
    'rfid_tag_id': rfidTagId,
    'statut': statut,
    'date_enregistrement': dateEnregistrement.toIso8601String(),
  };

  factory Garment.fromMap(Map<String, dynamic> map) => Garment(
        id: map['id'] as String,
        commandeId: map['commande_id'] as String,
        residentId: map['resident_id'] as String?,
        typeVetement: map['type_vetement'] as String,
        taille: map['taille'] as String?,
        couleur: map['couleur'] as String?,
        rfidTagId: map['rfid_tag_id'] as String?,
        statut: map['statut'] as String? ?? 'En attente',
        dateEnregistrement: DateTime.parse(map['date_enregistrement'] as String),
      );
}
