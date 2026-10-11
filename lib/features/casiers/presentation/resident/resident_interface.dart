import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../navigation/resident_navigation_bar.dart';
import '../widgets/casier_components.dart';

class ResidentInterface extends StatefulWidget {
  const ResidentInterface({super.key, this.userName});

  final String? userName;

  @override
  State<ResidentInterface> createState() => _ResidentInterfaceState();
}

class _ResidentInterfaceState extends State<ResidentInterface> {
  int _selectedIndex = 0;
  String _historyFilter = 'Aujourd’hui';
  late final LockerRecord _myLocker = LockerRecord(
    id: 'C-024',
    resident: widget.userName ?? 'Mohamed Khalil',
    apartment: 'A-204',
  );

  @override
  Widget build(BuildContext context) {
    const titles = [
      'Mon casier',
      'Mon casier',
      'Historique',
      'Notifications',
      'Mon profil',
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[_selectedIndex],
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: 'Ouvrir le menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu_rounded),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => setState(() => _selectedIndex = 3),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: ResidentNavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          Navigator.of(context).pop();
        },
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _homePage(),
          _myLockerPage(),
          _historyPage(),
          _notificationsPage(),
          _profilePage(),
        ],
      ),
    );
  }

  Widget _homePage() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
    children: [
      PageHeading(
        title:
            'Bonjour${widget.userName == null ? '' : ', ${widget.userName}'}',
        subtitle: 'Votre linge, en toute sérénité.',
        trailing: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.line),
          ),
          child: const Icon(
            Icons.local_laundry_service_outlined,
            color: AppColors.cyan,
          ),
        ),
      ),
      const SizedBox(height: 20),
      _lockerHero(),
      const SizedBox(height: 20),
      const SectionTitle('État de votre casier'),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.55,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          DetailTile(
            label: 'Poids du linge',
            value: '${_myLocker.weight} kg',
            icon: Icons.scale_outlined,
            color: AppColors.cyan,
          ),
          DetailTile(
            label: 'Porte',
            value: _myLocker.doorOpen ? 'Ouverte' : 'Fermée',
            icon: Icons.door_front_door_outlined,
          ),
          DetailTile(
            label: 'Verrou',
            value: _myLocker.locked ? 'Verrouillé' : 'Déverrouillé',
            icon: Icons.lock_outline_rounded,
          ),
          DetailTile(
            label: 'Température',
            value: '${_myLocker.temperature}°C',
            icon: Icons.thermostat_rounded,
          ),
          DetailTile(
            label: 'Humidité',
            value: '${_myLocker.humidity}%',
            icon: Icons.water_drop_outlined,
          ),
          const DetailTile(
            label: 'Dernière activité',
            value: '13:14',
            icon: Icons.schedule_rounded,
          ),
        ],
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.line),
        ),
        child: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppColors.cyan),
            SizedBox(width: 11),
            Expanded(
              child: Text(
                'Votre linge est protégé et suivi par ResiDry.',
                style: TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            StatusPill('Sécurisé', color: AppColors.cyan),
          ],
        ),
      ),
    ],
  );

  Widget _lockerHero() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.navy, Color(0xFF2651A9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.door_front_door_outlined,
                color: Colors.white,
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VOTRE CASIER',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'C-024',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const StatusPill('Connecté', color: AppColors.cyan),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${_myLocker.weight}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 39,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 6, bottom: 5),
              child: Text(
                'kg de linge',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            const Spacer(),
            const Icon(Icons.home_outlined, color: Colors.white70, size: 17),
            const SizedBox(width: 4),
            const Text('A-204', style: TextStyle(color: Colors.white)),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            onPressed: () => setState(() => _selectedIndex = 1),
            style: FilledButton.styleFrom(
              foregroundColor: AppColors.navy,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: const Text(
              'Voir mon casier',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _myLockerPage() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
    children: [
      PageHeading(
        title: 'Casier ${_myLocker.id}',
        subtitle: 'Suivi en temps réel · ${_myLocker.apartment}',
        trailing: const StatusPill('Connecté', color: AppColors.cyan),
      ),
      const SizedBox(height: 18),
      _lockerHero(),
      const SizedBox(height: 18),
      const SectionTitle('Informations du casier'),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.55,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          DetailTile(
            label: 'Poids du linge',
            value: '${_myLocker.weight} kg',
            icon: Icons.scale_outlined,
          ),
          DetailTile(
            label: 'Porte',
            value: _myLocker.doorOpen ? 'Ouverte' : 'Fermée',
            icon: Icons.door_front_door_outlined,
          ),
          DetailTile(
            label: 'Verrou',
            value: _myLocker.locked ? 'Verrouillé' : 'Déverrouillé',
            icon: Icons.lock_outline_rounded,
            color: _myLocker.locked ? AppColors.cyan : AppColors.coral,
          ),
          DetailTile(
            label: 'Température',
            value: '${_myLocker.temperature}°C',
            icon: Icons.thermostat_rounded,
          ),
          DetailTile(
            label: 'Humidité',
            value: '${_myLocker.humidity}%',
            icon: Icons.water_drop_outlined,
          ),
          const DetailTile(
            label: 'Dernière activité',
            value: 'Aujourd’hui · 13:14',
            icon: Icons.schedule_rounded,
          ),
        ],
      ),
      const SizedBox(height: 22),
      SizedBox(
        height: 54,
        child: FilledButton.icon(
          onPressed: _myLocker.locked ? () => _setLocked(false) : null,
          icon: const Icon(Icons.lock_open_rounded),
          label: const Text('Déverrouiller le casier'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.cyan,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: 54,
        child: OutlinedButton.icon(
          onPressed: _myLocker.locked ? null : () => _setLocked(true),
          icon: const Icon(Icons.lock_rounded),
          label: const Text('Verrouiller le casier'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.navy,
            side: const BorderSide(color: AppColors.navy),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ),
      const SizedBox(height: 18),
      const TrendCard(title: 'Suivi du poids aujourd’hui', value: '5.2 kg'),
    ],
  );

  Widget _historyPage() {
    final events = switch (_historyFilter) {
      'Cette semaine' => const [
        ('Aujourd’hui · 13:14', 'Porte fermée', Icons.door_front_door_outlined),
        ('Aujourd’hui · 13:12', 'Linge ajouté · 5.2 kg', Icons.scale_outlined),
        ('Aujourd’hui · 13:10', 'Porte ouverte', Icons.meeting_room_outlined),
        ('Hier · 18:40', 'Casier verrouillé', Icons.lock_outline_rounded),
        (
          'Lun. · 09:16',
          'Collecte de linge',
          Icons.local_laundry_service_outlined,
        ),
      ],
      'Ce mois' => const [
        ('Aujourd’hui · 13:14', 'Porte fermée', Icons.door_front_door_outlined),
        ('Hier · 18:40', 'Casier verrouillé', Icons.lock_outline_rounded),
        (
          'Lun. · 09:16',
          'Collecte de linge',
          Icons.local_laundry_service_outlined,
        ),
        ('01 oct. · 11:20', 'Nouveau cycle de lavage', Icons.refresh_rounded),
      ],
      _ => const [
        ('13:14', 'Porte fermée', Icons.door_front_door_outlined),
        ('13:12', 'Linge ajouté · 5.2 kg', Icons.scale_outlined),
        ('13:10', 'Porte ouverte', Icons.meeting_room_outlined),
        ('12:45', 'Casier déverrouillé', Icons.lock_open_outlined),
      ],
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const PageHeading(
          title: 'Historique',
          subtitle: 'Activité de votre casier C-024.',
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          children: [
            for (final period in ['Aujourd’hui', 'Cette semaine', 'Ce mois'])
              ChoiceChip(
                label: Text(period),
                selected: _historyFilter == period,
                onSelected: (_) => setState(() => _historyFilter = period),
                selectedColor: AppColors.cyan.withValues(alpha: 0.18),
                side: BorderSide(
                  color: _historyFilter == period
                      ? AppColors.cyan
                      : AppColors.line,
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        for (var i = 0; i < events.length; i++)
          _historyTile(
            events[i].$1,
            events[i].$2,
            events[i].$3,
            isLast: i == events.length - 1,
          ),
      ],
    );
  }

  Widget _historyTile(
    String time,
    String title,
    IconData icon, {
    required bool isLast,
  }) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 24,
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: 0.13),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.navy, size: 17),
            ),
            if (!isLast) Container(width: 1, height: 38, color: AppColors.line),
          ],
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 1, bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _notificationsPage() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
    children: [
      const PageHeading(
        title: 'Notifications',
        subtitle: 'Les informations importantes de votre casier.',
      ),
      const SizedBox(height: 12),
      _notification(
        'Votre casier est bien verrouillé.',
        'Il y a 2 min · C-024',
        Icons.verified_user_outlined,
        AppColors.cyan,
      ),
      _notification(
        'La porte est restée ouverte pendant 10 minutes.',
        'Aujourd’hui · 13:10',
        Icons.door_front_door_outlined,
        const Color(0xFFE77B32),
      ),
      _notification(
        'Une activité inhabituelle a été détectée.',
        'Hier · 18:42',
        Icons.warning_amber_rounded,
        const Color(0xFFE77B32),
      ),
      _notification(
        'Le module IoT est temporairement hors ligne.',
        'Lun. · 09:16',
        Icons.wifi_off_rounded,
        const Color(0xFFE45858),
      ),
      _notification(
        'Du linge a été détecté dans votre casier.',
        'Lun. · 08:52',
        Icons.local_laundry_service_outlined,
        AppColors.cyan,
      ),
    ],
  );

  Widget _notification(String title, String time, IconData icon, Color color) =>
      Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    time,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _profilePage() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
    children: [
      const PageHeading(
        title: 'Mon profil',
        subtitle: 'Vos informations personnelles et votre logement.',
      ),
      const SizedBox(height: 24),
      CircleAvatar(
        radius: 38,
        backgroundColor: AppColors.navy,
        child: Text(
          (widget.userName?.isNotEmpty ?? false)
              ? widget.userName![0].toUpperCase()
              : 'M',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(height: 12),
      Center(
        child: Text(
          widget.userName ?? 'Mohamed Khalil',
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const Center(
        child: Text(
          'Résident · A-204',
          style: TextStyle(color: AppColors.muted),
        ),
      ),
      const SizedBox(height: 24),
      const DetailTile(
        label: 'Mon casier attribué',
        value: 'C-024 · Appartement A-204',
        icon: Icons.door_front_door_outlined,
      ),
      const SizedBox(height: 10),
      const DetailTile(
        label: 'Sécurité du compte',
        value: 'Compte protégé',
        icon: Icons.shield_outlined,
        color: AppColors.cyan,
      ),
    ],
  );

  void _setLocked(bool locked) {
    setState(() => _myLocker.locked = locked);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          locked
              ? 'Votre casier est verrouillé.'
              : 'Votre casier est déverrouillé.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
