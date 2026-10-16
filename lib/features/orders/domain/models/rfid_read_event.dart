library residry.orders.domain.models.rfid_read_event;

class RfidReadEvent {
  const RfidReadEvent({
    required this.id,
    required this.tagId,
    required this.lecteurId,
    required this.typeLecteur,
    required this.localisation,
    this.latitude,
    this.longitude,
    required this.typeEvenement,
    required this.luLe,
  });

  final int id;
  final String tagId;
  final String lecteurId;
  final String typeLecteur;
  final String localisation;
  final double? latitude;
  final double? longitude;
  final String typeEvenement;
  final DateTime luLe;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'tag_id': tagId,
    'lecteur_id': lecteurId,
    'type_lecteur': typeLecteur,
    'localisation': localisation,
    'latitude': latitude,
    'longitude': longitude,
    'type_evenement': typeEvenement,
    'lu_le': luLe.toIso8601String(),
  };

  factory RfidReadEvent.fromMap(Map<String, dynamic> map) => RfidReadEvent(
        id: map['id'] as int,
        tagId: map['tag_id'] as String,
        lecteurId: map['lecteur_id'] as String,
        typeLecteur: map['type_lecteur'] as String,
        localisation: map['localisation'] as String,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        typeEvenement: map['type_evenement'] as String,
        luLe: DateTime.parse(map['lu_le'] as String),
      );
}
