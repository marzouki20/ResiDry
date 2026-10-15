import 'package:flutter/material.dart';

import '../data/models/laundry_item.dart';
import '../data/models/laundry_status_change.dart';
import '../data/repositories/laundry_repository.dart';
import 'laundry_insights.dart';

Future<void> showLaundryHistory(
  BuildContext context,
  LaundryRepository repository,
  LaundryItem item, {
  int? residentId,
}) {
  // Create the future once, before the dialog builder runs.
  final history = repository.getStatusHistory(item.id, residentId: residentId);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Historique des statuts'),
      content: SizedBox(
        width: 420,
        child: FutureBuilder<List<LaundryStatusChange>>(
          future: history,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Impossible de charger l’historique.');
            }
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 60,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final changes = snapshot.data!;
            if (changes.isEmpty) {
              return const Text('Aucun changement enregistré.');
            }
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Commande #${item.id}'),
                  for (final change in changes)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '${change.oldStatus?.label ?? 'Création'} → ${change.newStatus.label}\n'
                        '${laundryDate(change.changedAt)}'
                        '${change.changedByUserId == null ? '' : '\nUtilisateur : ${change.changedByUserId}'}',
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    ),
  );
}
