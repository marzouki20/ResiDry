import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../models/delivery_driver.dart';
import '../../../../models/delivery_order.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../casiers/presentation/widgets/casier_components.dart';
import 'navigation/driver_navigation_bar.dart';
import 'widgets/driver_components.dart';

class DriverInterface extends StatefulWidget {
  const DriverInterface({super.key, this.userName});

  final String? userName;

  @override
  State<DriverInterface> createState() => _DriverInterfaceState();
}

class _DriverInterfaceState extends State<DriverInterface> {
  int _selectedIndex = 0;
  bool _isOnDuty = true;
  String _filter = 'Toutes';
  String _searchQuery = '';

  late final DeliveryDriver _driver = demoDeliveryDrivers.firstWhere(
    (d) => d.name.toLowerCase().contains((widget.userName ?? '').toLowerCase()),
    orElse: () => DeliveryDriver(
      id: 'LIV-001',
      name: widget.userName ?? 'Aymen Abdellatif',
      email: 'aymen@residry.tn',
      phone: '+216 55 123 456',
      status: 'En service',
      vehicleType: 'Scooter électrique',
      rating: 4.9,
      assignedZone: 'Résidence Université',
      deliveriesCompleted: 68,
    ),
  );

  late final List<DeliveryOrder> _orders =
      List<DeliveryOrder>.of(demoDeliveryOrders);

  @override
  Widget build(BuildContext context) {
    const titles = [
      'Tableau de bord',
      'Mes livraisons',
      'Accès Casiers IoT',
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
      drawer: DriverNavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          Navigator.of(context).pop();
        },
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _dashboard(),
          _missionsPage(),
          _lockersPage(),
          _notificationsPage(),
          _profilePage(),
        ],
      ),
    );
  }

  Widget _dashboard() {
    final pendingCount =
        _orders.where((o) => o.status == 'À récupérer').length;
    final inTransitCount =
        _orders.where((o) => o.status.contains('transit')).length;
    final completedCount =
        _orders.where((o) => o.status == 'Déposé au casier' || o.status == 'Livré').length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        PageHeading(
          title:
              'Bonjour${widget.userName == null ? '' : ', ${widget.userName}'}',
          subtitle: 'Bienvenue dans votre espace livreur ResiDry.',
          trailing: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.line),
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              color: AppColors.cyan,
              size: 23,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _isOnDuty ? const Color(0xFFE6F8F6) : const Color(0xFFFFF0F0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isOnDuty ? AppColors.cyan : const Color(0xFFFF8B8B),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _isOnDuty
                    ? Icons.check_circle_outline_rounded
                    : Icons.pause_circle_outline_rounded,
                color: _isOnDuty ? AppColors.cyan : const Color(0xFFE45858),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isOnDuty ? 'Statut : En Service' : 'Statut : Hors Service',
                      style: TextStyle(
                        color: _isOnDuty ? AppColors.navy : const Color(0xFFE45858),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _isOnDuty
                          ? 'Prêt à recevoir des notifications de livraison'
                          : 'Mode pause activé',
                      style: const TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isOnDuty,
                activeColor: AppColors.cyan,
                onChanged: (value) {
                  setState(() => _isOnDuty = value);
                  _showMessage(
                    value ? 'Vous êtes maintenant en service' : 'Vous êtes hors service',
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.35,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            DriverMetricCard(
              label: 'Missions du jour',
              value: '${_orders.length}',
              icon: Icons.assignment_outlined,
            ),
            DriverMetricCard(
              label: 'À récupérer',
              value: '$pendingCount',
              icon: Icons.pending_actions_rounded,
              color: const Color(0xFFE77B32),
            ),
            DriverMetricCard(
              label: 'En transit',
              value: '$inTransitCount',
              icon: Icons.directions_bike_rounded,
              color: AppColors.navy,
            ),
            DriverMetricCard(
              label: 'Complétées',
              value: '$completedCount',
              icon: Icons.task_alt_rounded,
              color: AppColors.cyan,
            ),
          ],
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Déverrouillage Casier IoT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Scanner ou ouvrir à distance',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => setState(() => _selectedIndex = 2),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Accéder'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SectionTitle(
          'Missions récentes',
          action: 'Voir tout',
          onAction: () => setState(() => _selectedIndex = 1),
        ),
        const SizedBox(height: 10),
        for (final order in _orders.take(2))
          DeliveryOrderCard(
            order: order,
            onAdvanceStatus: () => _advanceOrderStatus(order),
            onOpenLocker: () => _showUnlockDialog(order.lockerId),
          ),
      ],
    );
  }

  Widget _missionsPage() {
    final filteredOrders = _orders.where((o) {
      final matchesSearch =
          o.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          o.residentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          o.lockerId.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter = switch (_filter) {
        'À récupérer' => o.status == 'À récupérer',
        'En transit' => o.status.contains('transit') || o.status == 'En lavage',
        'Livrées' => o.status == 'Déposé au casier' || o.status == 'Livré',
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const PageHeading(
          title: 'Mes livraisons',
          subtitle: 'Gérez vos collectes et dépôts de linge dans la résidence.',
        ),
        const SizedBox(height: 18),
        TextField(
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            hintText: 'Rechercher commande, casier, résident...',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppColors.line),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final cat in ['Toutes', 'À récupérer', 'En transit', 'Livrées'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: _filter == cat,
                    onSelected: (_) => setState(() => _filter = cat),
                    selectedColor: AppColors.cyan.withValues(alpha: 0.18),
                    side: BorderSide(
                      color: _filter == cat ? AppColors.cyan : AppColors.line,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final order in filteredOrders)
          DeliveryOrderCard(
            order: order,
            onAdvanceStatus: () => _advanceOrderStatus(order),
            onOpenLocker: () => _showUnlockDialog(order.lockerId),
          ),
        if (filteredOrders.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                'Aucune livraison trouvée.',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          ),
      ],
    );
  }

  Widget _lockersPage() {
    final assignedLockers = [
      ('C-024', 'Mohamed Khalil', 'A-204', '5.2 kg', true),
      ('C-017', 'Sara Benali', 'B-105', '3.8 kg', true),
      ('C-031', 'Yassine Amrani', 'A-310', '4.5 kg', true),
      ('C-012', 'Lina Haddad', 'C-206', '3.1 kg', false),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const PageHeading(
          title: 'Accès Casiers IoT',
          subtitle: 'Déverrouillage à distance et contrôle de pesée.',
        ),
        const SizedBox(height: 18),
        for (final item in assignedLockers)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.line),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.door_front_door_outlined,
                  color: AppColors.navy,
                ),
              ),
              title: Text(
                'Casier ${item.$1} · ${item.$2}',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                'Apt ${item.$3} · Charge : ${item.$4}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              trailing: FilledButton.tonal(
                onPressed: () => _showUnlockDialog(item.$1),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Ouvrir'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _notificationsPage() => ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const PageHeading(
            title: 'Notifications',
            subtitle: 'Alertes de livraison et dépôts casiers.',
          ),
          const SizedBox(height: 16),
          _notifItem(
            'Nouvelle mission assignée : CMD-101',
            'Récupération linge Casier C-024 (A-204)',
            'Il y a 10 min',
            Icons.assignment_ind_outlined,
            AppColors.cyan,
          ),
          _notifItem(
            'Casier C-031 verrouillé par livreur',
            'Dépôt de linge propre confirmé',
            'Aujourd’hui · 11:30',
            Icons.lock_rounded,
            AppColors.navy,
          ),
          _notifItem(
            'Rappel : Récupération EcoClean Laundry',
            '3 sacs de linge prêts pour livraison retour',
            'Aujourd’hui · 09:15',
            Icons.local_laundry_service_outlined,
            const Color(0xFFE77B32),
          ),
        ],
      );

  Widget _notifItem(
    String title,
    String desc,
    String time,
    IconData icon,
    Color color,
  ) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    time,
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 10),
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
            title: 'Mon profil livreur',
            subtitle: 'Informations professionnelles et zone de service.',
          ),
          const SizedBox(height: 24),
          const CircleAvatar(
            radius: 38,
            backgroundColor: AppColors.navy,
            child: Icon(
              Icons.local_shipping_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _driver.name,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Center(
            child: Text(
              'Livreur ResiDry · ${_driver.id}',
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
          const SizedBox(height: 20),
          DetailTile(
            label: 'Véhicule',
            value: _driver.vehicleType,
            icon: Icons.two_wheeler_rounded,
          ),
          const SizedBox(height: 10),
          DetailTile(
            label: 'Zone assignée',
            value: _driver.assignedZone,
            icon: Icons.apartment_rounded,
          ),
          const SizedBox(height: 10),
          DetailTile(
            label: 'Note de service',
            value: '${_driver.rating} / 5.0 ⭐',
            icon: Icons.star_outline_rounded,
            color: AppColors.cyan,
          ),
          const SizedBox(height: 10),
          DetailTile(
            label: 'Courses effectuées',
            value: '${_driver.deliveriesCompleted} livraisons',
            icon: Icons.task_alt_rounded,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            label: const Text(
              'Se déconnecter',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      );

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter ? Votre statut passera hors-ligne et vous ne recevrez plus de nouvelles missions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isOnDuty = false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  void _advanceOrderStatus(DeliveryOrder order) {
    setState(() {
      order.status = switch (order.status) {
        'À récupérer' => 'En transit',
        'En transit' => 'En lavage',
        'En lavage' => 'En transit retour',
        'En transit retour' => 'Déposé au casier',
        _ => 'Livré',
      };
    });
    _showMessage('Statut de la commande ${order.id} mis à jour : ${order.status}');
  }

  Future<void> _showUnlockDialog(String lockerId) async {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Déverrouiller Casier $lockerId ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Action d’ouverture IoT envoyée au casier $lockerId.'),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.wifi_rounded, color: AppColors.cyan, size: 18),
                SizedBox(width: 8),
                Text(
                  'Signal IoT reçu · Porte déverrouillée',
                  style: TextStyle(color: AppColors.navy, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showMessage('Casier $lockerId déverrouillé avec succès.');
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.cyan),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }
}
