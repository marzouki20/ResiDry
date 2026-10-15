import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class DriverNavigationBar extends StatelessWidget {
  const DriverNavigationBar({
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
                        Icons.local_shipping_rounded,
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
                            'ESPACE LIVREUR',
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
                  'GESTION DES COURSES',
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
                      Icons.local_shipping_outlined,
                      Icons.local_shipping_rounded,
                      'Mes livraisons',
                    ),
                    _destination(
                      2,
                      Icons.door_front_door_outlined,
                      Icons.door_front_door_rounded,
                      'Casiers IoT',
                    ),
                    _destination(
                      3,
                      Icons.notifications_none_rounded,
                      Icons.notifications_rounded,
                      'Notifications',
                    ),
                    _destination(
                      4,
                      Icons.person_outline_rounded,
                      Icons.person_rounded,
                      'Mon profil',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.line),
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 15, 24, 18),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        color: AppColors.cyan, size: 18),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Livreur en service',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
