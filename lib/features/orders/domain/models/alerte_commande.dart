library residry.orders.domain.models.alerte_commande;

class AlerteCommande {
  const AlerteCommande({
    required this.id,
    required this.commandeId,
    required this.titre,
    required this.description,
    required this.gravite,
    this.estLue = false,
    required this.dateCreation,
  });

  final int id;
  final String commandeId;
  final String titre;
  final String description;
  final String gravite;
  final bool estLue;
  final DateTime dateCreation;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'commande_id': commandeId,
    'titre': titre,
    'description': description,
    'gravite': gravite,
    'est_lue': estLue ? 1 : 0,
    'date_creation': dateCreation.toIso8601String(),
  };

  factory AlerteCommande.fromMap(Map<String, dynamic> map) => AlerteCommande(
        id: map['id'] as int,
        commandeId: map['commande_id'] as String,
        titre: map['titre'] as String,
        description: map['description'] as String,
        gravite: map['gravite'] as String,
        estLue: (map['est_lue'] as int) == 1,
        dateCreation: DateTime.parse(map['date_creation'] as String),
      );
}
