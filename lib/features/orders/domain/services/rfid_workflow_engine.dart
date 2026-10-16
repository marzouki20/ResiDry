library residry.orders.domain.services.rfid_workflow_engine;

import '../../data/sqlite_order_repository.dart';
import '../models/rfid_read_event.dart';

enum RfidReaderRole {
  admin,
  delivery,
  laundry,
  casier,
  resident,
}

enum RfidEventType {
  scanIn,
  scanOut,
  tagAssigned,
  tagUnassigned,
  anomaly,
}

class RfidWorkflowResult {
  const RfidWorkflowResult({
    required this.success,
    required this.newStatus,
    required this.message,
    this.alerts = const [],
  });

  final bool success;
  final String newStatus;
  final String message;
  final List<String> alerts;
}

class RfidWorkflowEngine {
  const RfidWorkflowEngine();

  static const List<String> _stages = [
    'Nouvelle',
    'En attente',
    'Collecte prévue',
    'Collectée',
    'En transit vers blanchisserie',
    'En lavage',
    'Lavage terminé',
    'Prête',
    'En transit vers résidence',
    'En livraison',
    'Livrée',
    'Annulée',
  ];

  static const Map<String, List<String>> _validTransitions = {
    'Nouvelle': ['En attente', 'Annulée'],
    'En attente': ['Collecte prévue', 'Annulée'],
    'Collecte prévue': ['Collectée', 'Annulée'],
    'Collectée': ['En transit vers blanchisserie', 'Annulée'],
    'En transit vers blanchisserie': ['En lavage', 'Annulée'],
    'En lavage': ['Lavage terminé', 'Annulée'],
    'Lavage terminé': ['Prête', 'Annulée'],
    'Prête': ['En transit vers résidence', 'Annulée'],
    'En transit vers résidence': ['En livraison', 'Annulée'],
    'En livraison': ['Livrée', 'Annulée'],
    'Livrée': [],
    'Annulée': [],
  };

  static const Map<RfidReaderRole, List<String>> _rolePermissions = {
    RfidReaderRole.admin: _stages,
    RfidReaderRole.delivery: [
      'Collecte prévue',
      'Collectée',
      'En transit vers blanchisserie',
      'En transit vers résidence',
      'En livraison',
      'Livrée',
    ],
    RfidReaderRole.laundry: [
      'En transit vers blanchisserie',
      'En lavage',
      'Lavage terminé',
      'Prête',
    ],
    RfidReaderRole.casier: ['En livraison', 'Livrée'],
    RfidReaderRole.resident: ['Nouvelle', 'En attente', 'Livrée'],
  };

  RfidWorkflowResult validateTransition({
    required String currentStatus,
    required String targetStatus,
    required RfidReaderRole role,
  }) {
    final allowed = _validTransitions[currentStatus];
    if (allowed == null || !allowed.contains(targetStatus)) {
      return RfidWorkflowResult(
        success: false,
        newStatus: currentStatus,
        message:
            'Transition invalide : $currentStatus → $targetStatus non autorisée.',
        alerts: [
          'Alerte : tentative de transition invalide ($currentStatus → $targetStatus) par $role.',
        ],
      );
    }

    final roleAllowed = _rolePermissions[role];
    if (roleAllowed == null || !roleAllowed.contains(targetStatus)) {
      return RfidWorkflowResult(
        success: false,
        newStatus: currentStatus,
        message:
            'Rôle $role non autorisé à effectuer la transition vers $targetStatus.',
        alerts: [
          'Alerte : rôle $role non autorisé pour $targetStatus.',
        ],
      );
    }

    return RfidWorkflowResult(
      success: true,
      newStatus: targetStatus,
      message: 'Transition validée : $currentStatus → $targetStatus.',
    );
  }

  Future<RfidWorkflowResult> processRfidScan({
    required String tagId,
    required String lecteurId,
    required RfidReaderRole role,
    required String localisation,
    required double? latitude,
    required double? longitude,
    required RfidEventType eventType,
    required SqliteOrderRepository repository,
    required DateTime timestamp,
  }) async {
    final tag = await repository.getRfidTagById(tagId);
    if (tag == null) {
      await repository.insertRfidReadEvent(
        RfidReadEvent(
          id: 0,
          tagId: tagId,
          lecteurId: lecteurId,
          typeLecteur: role.name,
          localisation: localisation,
          latitude: latitude,
          longitude: longitude,
          typeEvenement: 'anomalie',
          luLe: timestamp,
        ),
      );
      return RfidWorkflowResult(
        success: false,
        newStatus: '',
        message: 'Tag RFID non reconnu : $tagId',
        alerts: ['Alerte : tag RFID inconnu scanné ($tagId).'],
      );
    }

    final commandeId = tag.commandeId;
    if (commandeId == null) {
      return const RfidWorkflowResult(
        success: false,
        newStatus: '',
        message: 'Tag non associé à une commande.',
        alerts: ['Alerte : tag RFID sans commande associée.'],
      );
    }

    final events = await repository.getRfidReadEventsByCommande(commandeId);
    final lastEvent = events.isNotEmpty ? events.first : null;

    String newStatus;
    switch (role) {
      case RfidReaderRole.delivery:
        if (eventType == RfidEventType.scanIn &&
            localisation.toLowerCase().contains('casier')) {
          newStatus = lastEvent != null ? 'Livrée' : 'Collectée';
        } else if (eventType == RfidEventType.scanOut &&
            localisation.toLowerCase().contains('blanchisserie')) {
          newStatus = 'En transit vers blanchisserie';
        } else if (eventType == RfidEventType.scanIn &&
            localisation.toLowerCase().contains('résidence')) {
          newStatus = 'En transit vers résidence';
        } else {
          newStatus = 'En livraison';
        }
        break;
      case RfidReaderRole.laundry:
        if (eventType == RfidEventType.scanIn &&
            localisation.toLowerCase().contains('blanchisserie')) {
          newStatus = 'En lavage';
        } else if (eventType == RfidEventType.scanOut) {
          newStatus = 'Prête';
        } else {
          newStatus = 'En transit vers blanchisserie';
        }
        break;
      case RfidReaderRole.casier:
        newStatus = 'Livrée';
        break;
      case RfidReaderRole.resident:
        newStatus = 'Nouvelle';
        break;
      case RfidReaderRole.admin:
        newStatus = _statusFromEvent(eventType);
        break;
    }

    await repository.insertRfidReadEvent(
      RfidReadEvent(
        id: 0,
        tagId: tagId,
        lecteurId: lecteurId,
        typeLecteur: role.name,
        localisation: localisation,
        latitude: latitude,
        longitude: longitude,
        typeEvenement: eventType.name,
        luLe: timestamp,
      ),
    );

    return RfidWorkflowResult(
      success: true,
      newStatus: newStatus,
      message: 'Scan RFID traité : $tagId → $newStatus',
    );
  }

  String _statusFromEvent(RfidEventType eventType) {
    switch (eventType) {
      case RfidEventType.scanIn:
        return 'En attente';
      case RfidEventType.scanOut:
        return 'En livraison';
      case RfidEventType.tagAssigned:
        return 'Nouvelle';
      case RfidEventType.tagUnassigned:
        return 'Annulée';
      case RfidEventType.anomaly:
        return 'En attente';
    }
  }

  bool isValidTransition(String from, String to) {
    final allowed = _validTransitions[from];
    return allowed != null && allowed.contains(to);
  }

  List<String> getAllowedNext(String status) {
    return _validTransitions[status] ?? [];
  }

  List<RfidReaderRole> getRolesForStatus(String status) {
    return _rolePermissions.entries
        .where((entry) => entry.value.contains(status))
        .map((entry) => entry.key)
        .toList(growable: false);
  }
}
