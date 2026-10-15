import 'package:flutter/material.dart';

import '../../../../core/localization/localized_text.dart';

import '../../../auth/presentation/widgets/sign_out_button.dart';

import '../../../../core/localization/app_locale.dart';
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LocalizedText(
                            'ResiDry',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          LocalizedText(
                            context.tr(
                              en: 'DRIVER AREA',
                              fr: 'ESPACE LIVREUR',
                            ),
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
                      tooltip: context.tr(
                        en: 'Close menu',
                        fr: 'Fermer le menu',
                      ),
                      onPressed: () => Scaffold.of(context).closeDrawer(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.line),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 22, 16, 10),
                child: LocalizedText(
                  context.tr(
                    en: 'DELIVERY MANAGEMENT',
                    fr: 'GESTION DES COURSES',
                  ),
                  style: const TextStyle(
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
                      context.tr(en: 'Dashboard', fr: 'Tableau de bord'),
                    ),
                    _destination(
                      1,
                      Icons.local_shipping_outlined,
                      Icons.local_shipping_rounded,
                      context.tr(en: 'My deliveries', fr: 'Mes livraisons'),
                    ),
                    _destination(
                      2,
                      Icons.door_front_door_outlined,
                      Icons.door_front_door_rounded,
                      context.tr(en: 'IoT lockers', fr: 'Casiers IoT'),
                    ),
                    _destination(
                      3,
                      Icons.notifications_none_rounded,
                      Icons.notifications_rounded,
                      context.tr(en: 'Notifications', fr: 'Notifications'),
                    ),
                    _destination(
                      4,
                      Icons.person_outline_rounded,
                      Icons.person_rounded,
                      context.tr(en: 'My profile', fr: 'Mon profil'),
                    ),
                  ],
                ),
              ),
              const SignOutButton(),
              const Divider(height: 1, color: AppColors.line),
              Padding(
                padding: EdgeInsets.fromLTRB(24, 15, 24, 18),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        color: AppColors.cyan, size: 18),
                    const SizedBox(width: 9),
                    Expanded(
                      child: LocalizedText(
                        context.tr(
                          en: 'Driver on duty',
                          fr: 'Livreur en service',
                        ),
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
        title:
            LocalizedText(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        textColor: selected ? AppColors.navy : AppColors.muted,
        iconColor: selected ? AppColors.navy : AppColors.muted,
        onTap: () => onDestinationSelected(index),
      ),
    );
  }
}
