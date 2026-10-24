import 'package:flutter/material.dart';

import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_theme.dart';

import '../../../../models/laundry_item.dart';
import '../../../../models/laundry_status_change.dart';
import '../../data/repositories/laundry_repository.dart';
import 'laundry_insights.dart';
import 'laundry_design.dart';

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: const Icon(Icons.history_rounded, color: AppColors.navy),
      title: Text(context.localize('Historique des statuts')),
      content: SizedBox(
        width: 420,
        child: FutureBuilder<List<LaundryStatusChange>>(
          future: history,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                context.localize('Impossible de charger l’historique.'),
              );
            }
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 60,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final changes = snapshot.data!;
            if (changes.isEmpty) {
              return Text(context.localize('Aucun changement enregistré.'));
            }
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.localize('Commande #${item.id}')),
                  for (final change in changes)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                laundryStatusIcon(change.newStatus),
                                size: 20,
                                color: laundryStatusColor(change.newStatus),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${change.oldStatus == null ? context.localize('Création') : laundryStatusText(context, change.oldStatus!)} → ${laundryStatusText(context, change.newStatus)}',
                                  style: const TextStyle(
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            laundryDate(change.changedAt),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.localize(
                              change.changedByUserId == null
                                  ? 'Auteur historique non associé'
                                  : 'Utilisateur : ${change.changedByUserId}',
                            ),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
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
          child: Text(context.localize('Fermer')),
        ),
      ],
    ),
  );
}
