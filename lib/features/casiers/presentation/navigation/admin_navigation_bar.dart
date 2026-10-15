import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class AdminNavigationBar extends StatelessWidget {
  const AdminNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) => Drawer(
    width: 304,
    backgroundColor: Colors.white,
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 18, 18),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.water_drop_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ResiDry',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'ESPACE ADMINISTRATEUR',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 9,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Fermer le menu',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.line),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 22, 16, 10),
            child: Text(
              'GESTION DE LA RÉSIDENCE',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 10,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _destination(
                  0,
                  Icons.dashboard_outlined,
                  Icons.dashboard_rounded,
                  'Tableau de bord',
                ),
                _destination(
                  1,
                  Icons.door_front_door_outlined,
                  Icons.door_front_door_rounded,
                  'Gestion des casiers',
                ),

                _destination(
                  2,
                  Icons.warning_amber_outlined,
                  Icons.warning_rounded,
                  'Anomalies',
                ),
                _destination(
                  3,
                  Icons.handyman_outlined,
                  Icons.handyman_rounded,
                  'Maintenance',
                ),
                _destination(
                  4,
                  Icons.person_outline_rounded,
                  Icons.person_rounded,
                  'Profil',
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 18, 12, 8),
                  child: Text(
                    'COMMANDES ET LIVRAISONS',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _destination(
                  5,
                  Icons.dashboard_outlined,
                  Icons.dashboard_rounded,
                  'Dashboard commandes',
                ),
                _destination(
                  6,
                  Icons.receipt_long_outlined,
                  Icons.receipt_long_rounded,
                  'Commandes',
                ),
                _destination(
                  7,
                  Icons.local_shipping_outlined,
                  Icons.local_shipping_rounded,
                  'Livraisons',
                ),
                _destination(
                  8,
                  Icons.warning_amber_outlined,
                  Icons.warning_rounded,
                  'Alertes commandes',
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 18, 12, 8),
                  child: Text(
                    'PARTENAIRES',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _destination(
                  9,
                  Icons.local_laundry_service_outlined,
                  Icons.local_laundry_service_rounded,
                  'Sociétés de lavage',
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 18, 12, 8),
                  child: Text(
                    'SERVICES DE LAVAGE',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _destination(
                  10,
                  Icons.local_laundry_service_outlined,
                  Icons.local_laundry_service_rounded,
                  'Gestion du linge',
                ),

              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _destination(
    int index,
    IconData icon,
    IconData selectedIcon,
    String label,
  ) {
    final selected = selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        selected: selected,
        selectedTileColor: AppColors.cyan.withValues(alpha: 0.14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(selected ? selectedIcon : icon),
        title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        textColor: selected ? AppColors.navy : AppColors.muted,
        iconColor: selected ? AppColors.navy : AppColors.muted,
        onTap: () => onDestinationSelected(index),
      ),
    );
  }
}
