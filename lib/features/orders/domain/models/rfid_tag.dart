library residry.orders.domain.models.rfid_tag;

class RfidTag {
  const RfidTag({
    required this.tagId,
    this.garmentId,
    this.commandeId,
    this.residentId,
    this.actif = true,
    required this.dateEnregistrement,
  });

  final String tagId;
  final String? garmentId;
  final String? commandeId;
  final String? residentId;
  final bool actif;
  final DateTime dateEnregistrement;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'tag_id': tagId,
    'garment_id': garmentId,
    'commande_id': commandeId,
    'resident_id': residentId,
    'actif': actif ? 1 : 0,
    'date_enregistrement': dateEnregistrement.toIso8601String(),
  };

  factory RfidTag.fromMap(Map<String, dynamic> map) => RfidTag(
        tagId: map['tag_id'] as String,
        garmentId: map['garment_id'] as String?,
        commandeId: map['commande_id'] as String?,
        residentId: map['resident_id'] as String?,
        actif: (map['actif'] as int) == 1,
        dateEnregistrement: DateTime.parse(map['date_enregistrement'] as String),
      );
}
