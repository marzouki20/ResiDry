import 'package:flutter/material.dart';
import '../../../core/navigation/app_back_button.dart';

import '../../../core/localization/localized_text.dart';

import '../../../../core/localization/app_locale.dart';
import '../../../../core/localization/language_picker_button.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/delivery_driver.dart';
import '../../../../models/delivery_order.dart';
import '../../auth/presentation/widgets/sign_out_button.dart';
import '../../casiers/presentation/widgets/casier_components.dart';
import '../data/delivery_repository.dart';
import '../data/sqlite_delivery_repository.dart';
import '../data/driver_profile_repository.dart';
import 'driver_onboarding_page.dart';
import '../domain/vehicle_capacity_evidence.dart';
import 'navigation/driver_navigation_bar.dart';
import 'widgets/driver_components.dart';

class DriverInterface extends StatefulWidget {
  const DriverInterface(
      {super.key, this.userName, this.userEmail, this.repository});

  final String? userName;
  final String? userEmail;
  final DeliveryRepository? repository;

  @override
  State<DriverInterface> createState() => _DriverInterfaceState();
}

class _DriverInterfaceState extends State<DriverInterface> {
  int _selectedIndex = 0;
  bool _isOnDuty = true;
  String _filter = 'Toutes';
  String _searchQuery = '';
  bool _isLoading = true;
  String? _loadError;
  late final DeliveryRepository _repository =
      widget.repository ?? SqliteDeliveryRepository();

  late DeliveryDriver _driver;
  List<DeliveryOrder> _orders = [];

  @override
  void initState() {
    super.initState();
    _driver = DeliveryDriver(
      id: 'LIV-001',
      name: widget.userName ?? 'Aymen Abdellatif',
      email: 'aymen@residry.tn',
      phone: '+216 55 123 456',
    );
    _loadDeliveryData();
  }

  Future<void> _loadDeliveryData() async {
    try {
      final drivers = await _repository.getDrivers();
      final requestedName = (widget.userName ?? '').trim().toLowerCase();
      DeliveryDriver? matchedDriver;
      for (final candidate in drivers) {
        if (widget.userEmail != null
            ? candidate.email.toLowerCase() == widget.userEmail!.toLowerCase()
            : requestedName.isNotEmpty &&
                candidate.name.toLowerCase() == requestedName) {
          matchedDriver = candidate;
          break;
        }
      }
      final driver = matchedDriver ?? _driver;
      final missions = matchedDriver == null
          ? <DeliveryOrder>[]
          : await _repository.getMissions(driverName: driver.name);
      if (!mounted) return;
      setState(() {
        _driver = driver;
        _orders = missions;
        _isLoading = false;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'missions_load_failed';
      });
    }
  }

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<int> _navigationHistory = [];

  void _navigateTo(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _navigationHistory.add(_selectedIndex);
      _selectedIndex = index;
    });
  }

  void _goBack() {
    if (_navigationHistory.isNotEmpty) {
      setState(() => _selectedIndex = _navigationHistory.removeLast());
    } else if (_selectedIndex != 0) {
      setState(() => _selectedIndex = 0);
    } else {
      confirmSignOut(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      context.tr(en: 'Dashboard', fr: 'Tableau de bord'),
      context.tr(en: 'My deliveries', fr: 'Mes livraisons'),
      context.tr(en: 'IoT locker access', fr: 'Accès Casiers IoT'),
      context.tr(en: 'Notifications', fr: 'Notifications'),
      context.tr(en: 'My profile', fr: 'Mon profil'),
    ];

    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
              _scaffoldKey.currentState?.closeDrawer();
            } else {
              _goBack();
            }
          }
        },
        child: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: LocalizedText(
              titles[_selectedIndex],
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
              ),
            ),
            backgroundColor: AppColors.cream,
            surfaceTintColor: Colors.transparent,
            leadingWidth: 96,
            leading: Row(children: [
              AppBackButton(onPressed: _goBack),
              Builder(
                builder: (context) => IconButton(
                  tooltip: context.tr(en: 'Open menu', fr: 'Ouvrir le menu'),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(Icons.menu_rounded),
                ),
              ),
            ]),
            actions: [
              const LanguagePickerButton(),
              IconButton(
                tooltip: context.tr(en: 'Notifications', fr: 'Notifications'),
                onPressed: () => _navigateTo(3),
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              const SizedBox(width: 8),
            ],
          ),
          drawer: DriverNavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              _navigateTo(index);
              _scaffoldKey.currentState?.closeDrawer();
            },
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _loadError != null
                  ? Center(
                      child: FilledButton.icon(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _loadError = null;
                          });
                          _loadDeliveryData();
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: LocalizedText(context.tr(
                          en: 'Could not load missions. Retry',
                          fr: 'Impossible de charger les missions. Réessayer',
                        )),
                      ),
                    )
                  : IndexedStack(
                      index: _selectedIndex,
                      children: [
                        _dashboard(),
                        _missionsPage(),
                        _lockersPage(),
                        _notificationsPage(),
                        _profilePage(),
                      ],
                    ),
        ));
  }

  Widget _dashboard() {
    final pendingCount = _orders.where((o) => o.status == 'À récupérer').length;
    final inTransitCount =
        _orders.where((o) => o.status.contains('transit')).length;
    final completedCount = _orders
        .where((o) => o.status == 'Déposé au casier' || o.status == 'Livré')
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        PageHeading(
          title: context.tr(
            en: 'Hello${widget.userName == null ? '' : ', ${widget.userName}'}',
            fr: 'Bonjour${widget.userName == null ? '' : ', ${widget.userName}'}',
          ),
          subtitle: context.tr(
            en: 'Welcome to your ResiDry driver area.',
            fr: 'Bienvenue dans votre espace livreur ResiDry.',
          ),
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
            color:
                _isOnDuty ? const Color(0xFFE6F8F6) : const Color(0xFFFFF0F0),
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
                    LocalizedText(
                      _isOnDuty
                          ? context.tr(
                              en: 'Status: On duty', fr: 'Statut : En Service')
                          : context.tr(
                              en: 'Status: Off duty',
                              fr: 'Statut : Hors Service'),
                      style: TextStyle(
                        color: _isOnDuty
                            ? AppColors.navy
                            : const Color(0xFFE45858),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    LocalizedText(
                      _isOnDuty
                          ? context.tr(
                              en: 'Ready to receive delivery notifications',
                              fr: 'Prêt à recevoir des notifications de livraison',
                            )
                          : context.tr(
                              en: 'Pause mode enabled',
                              fr: 'Mode pause activé',
                            ),
                      style:
                          const TextStyle(color: AppColors.muted, fontSize: 11),
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
                    value
                        ? context.tr(
                            en: 'You are now on duty',
                            fr: 'Vous êtes maintenant en service',
                          )
                        : context.tr(
                            en: 'You are now off duty',
                            fr: 'Vous êtes hors service',
                          ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GridView(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 170 * MediaQuery.textScalerOf(context).scale(1),
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            DriverMetricCard(
              label: context.tr(en: "Today's missions", fr: 'Missions du jour'),
              value: '${_orders.length}',
              icon: Icons.assignment_outlined,
            ),
            DriverMetricCard(
              label: context.tr(en: 'To collect', fr: 'À récupérer'),
              value: '$pendingCount',
              icon: Icons.pending_actions_rounded,
              color: const Color(0xFFE77B32),
            ),
            DriverMetricCard(
              label: context.tr(en: 'In transit', fr: 'En transit'),
              value: '$inTransitCount',
              icon: Icons.directions_bike_rounded,
              color: AppColors.navy,
            ),
            DriverMetricCard(
              label: context.tr(en: 'Completed', fr: 'Complétées'),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      context.tr(
                        en: 'IoT locker unlocking',
                        fr: 'Déverrouillage Casier IoT',
                      ),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 2),
                    LocalizedText(
                      context.tr(
                        en: 'Scan or open remotely',
                        fr: 'Scanner ou ouvrir à distance',
                      ),
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _navigateTo(2),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: LocalizedText(context.tr(en: 'Open', fr: 'Accéder')),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SectionTitle(
          context.tr(en: 'Recent missions', fr: 'Missions récentes'),
          action: context.tr(en: 'View all', fr: 'Voir tout'),
          onAction: () => _navigateTo(1),
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
      final matchesSearch = o.id
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
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
        PageHeading(
          title: context.tr(en: 'My deliveries', fr: 'Mes livraisons'),
          subtitle: context.tr(
            en: 'Manage laundry collections and locker drop-offs.',
            fr: 'Gérez vos collectes et dépôts de linge dans la résidence.',
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            hintText: context.tr(
              en: 'Search mission, locker, resident...',
              fr: 'Rechercher commande, casier, résident...',
            ),
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
              for (final cat in [
                'Toutes',
                'À récupérer',
                'En transit',
                'Livrées'
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: LocalizedText(_missionFilterLabel(context, cat)),
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
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: LocalizedText(
                context.tr(
                  en: 'No deliveries found.',
                  fr: 'Aucune livraison trouvée.',
                ),
                style: const TextStyle(color: AppColors.muted),
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
        PageHeading(
          title: context.tr(en: 'IoT locker access', fr: 'Accès Casiers IoT'),
          subtitle: context.tr(
            en: 'Remote unlocking and weight checks.',
            fr: 'Déverrouillage à distance et contrôle de pesée.',
          ),
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
              title: LocalizedText(
                '${context.tr(en: 'Locker', fr: 'Casier')} ${item.$1} · ${item.$2}',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: LocalizedText(
                '${context.tr(en: 'Apt', fr: 'Apt')} ${item.$3} · ${context.tr(en: 'Load', fr: 'Charge')} : ${item.$4}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              trailing: FilledButton.tonal(
                onPressed: () => _showUnlockDialog(item.$1),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                ),
                child: LocalizedText(context.tr(en: 'Open', fr: 'Ouvrir')),
              ),
            ),
          ),
      ],
    );
  }

  Widget _notificationsPage() => ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          PageHeading(
            title: context.tr(en: 'Notifications', fr: 'Notifications'),
            subtitle: context.tr(
              en: 'Delivery and locker drop-off alerts.',
              fr: 'Alertes de livraison et dépôts casiers.',
            ),
          ),
          const SizedBox(height: 16),
          _notifItem(
            context.tr(
              en: 'New mission assigned: CMD-101',
              fr: 'Nouvelle mission assignée : CMD-101',
            ),
            context.tr(
              en: 'Laundry collection at locker C-024 (A-204)',
              fr: 'Récupération linge Casier C-024 (A-204)',
            ),
            context.tr(en: '10 minutes ago', fr: 'Il y a 10 min'),
            Icons.assignment_ind_outlined,
            AppColors.cyan,
          ),
          _notifItem(
            context.tr(
              en: 'Locker C-031 locked by driver',
              fr: 'Casier C-031 verrouillé par livreur',
            ),
            context.tr(
              en: 'Clean laundry drop-off confirmed',
              fr: 'Dépôt de linge propre confirmé',
            ),
            context.tr(en: 'Today · 11:30', fr: 'Aujourd’hui · 11:30'),
            Icons.lock_rounded,
            AppColors.navy,
          ),
          _notifItem(
            context.tr(
              en: 'Reminder: EcoClean Laundry pickup',
              fr: 'Rappel : Récupération EcoClean Laundry',
            ),
            context.tr(
              en: '3 laundry bags ready for return delivery',
              fr: '3 sacs de linge prêts pour livraison retour',
            ),
            context.tr(en: 'Today · 09:15', fr: 'Aujourd’hui · 09:15'),
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
                  LocalizedText(
                    title,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  LocalizedText(
                    desc,
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  LocalizedText(
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
          PageHeading(
            title:
                context.tr(en: 'My driver profile', fr: 'Mon profil livreur'),
            subtitle: context.tr(
              en: 'Professional information and service area.',
              fr: 'Informations professionnelles et zone de service.',
            ),
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
            child: LocalizedText(
              '${context.tr(en: 'ResiDry driver', fr: 'Livreur ResiDry')} · ${_driver.id}',
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
          const SizedBox(height: 20),
          DetailTile(
            label: context.tr(en: 'Vehicle', fr: 'Véhicule'),
            value: _driver.vehicleType,
            icon: Icons.two_wheeler_rounded,
          ),
          const SizedBox(height: 10),
          DetailTile(
            label: context.tr(en: 'Assigned area', fr: 'Zone assignée'),
            value: _driver.assignedZone,
            icon: Icons.apartment_rounded,
          ),
          if (_driver.capacityKg != null) ...[
            const SizedBox(height: 10),
            DetailTile(
                label: context.tr(
                    en: 'Maximum carrying capacity',
                    fr: 'Capacité de charge maximale',
                    ar: 'سعة الحمولة القصوى'),
                value: '${_driver.capacityKg} kg',
                icon: Icons.scale_outlined),
          ],
          const SizedBox(height: 10),
          DetailTile(
              label: context.tr(
                  en: 'Capacity check',
                  fr: 'Contrôle de capacité',
                  ar: 'فحص السعة'),
              value: context.localize(_driver.capacityAssessment),
              icon: Icons.fact_check_outlined),
          const SizedBox(height: 10),
          DetailTile(
            label: context.tr(en: 'Service rating', fr: 'Note de service'),
            value: '${_driver.rating} / 5.0 ⭐',
            icon: Icons.star_outline_rounded,
            color: AppColors.cyan,
          ),
          const SizedBox(height: 10),
          DetailTile(
            label: context.tr(en: 'Completed trips', fr: 'Courses effectuées'),
            value:
                '${_driver.deliveriesCompleted} ${context.tr(en: 'deliveries', fr: 'livraisons')}',
            icon: Icons.task_alt_rounded,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            label: LocalizedText(
              context.tr(en: 'Sign out', fr: 'Se déconnecter'),
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
          if (widget.userEmail != null)
            OutlinedButton.icon(
              icon: const Icon(Icons.edit_outlined),
              label: Text(context.tr(
                  en: 'Edit delivery profile',
                  fr: 'Modifier le profil de livraison',
                  ar: 'تعديل ملف التوصيل')),
              onPressed: _editProfile,
            ),
        ],
      );

  Future<void> _logout() => confirmSignOut(context);

  Future<void> _editProfile() async {
    try {
      final zones = await DriverProfileRepository().getZones(_driver.id);
      final evidence = await DriverProfileRepository().getEvidence(_driver.id);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => DriverOnboardingPage(
              userName: _driver.name,
              userEmail: widget.userEmail,
              initialVehicle: ['Moto', 'Voiture', 'Vélo', 'Camionnette']
                      .contains(_driver.vehicleType)
                  ? _driver.vehicleType
                  : 'Moto',
              initialCapacity: _driver.capacityKg ?? 40,
              initialEvidence: evidence == null
                  ? null
                  : VehicleCapacityEvidence.fromMap(evidence),
              initialZones: zones)));
    } catch (_) {
      if (mounted) {
        _showMessage(context.tr(
            en: 'Could not load your profile. Please try again.',
            fr: 'Impossible de charger le profil. Réessayez.',
            ar: 'تعذر تحميل الملف. أعد المحاولة.'));
      }
    }
  }

  Future<void> _advanceOrderStatus(DeliveryOrder order) async {
    try {
      final updated = await _repository.advanceMission(order.id);
      if (!mounted) return;
      setState(() {
        final index = _orders.indexWhere((mission) => mission.id == order.id);
        if (index != -1) _orders[index] = updated;
      });
      _showMessage(
        context.tr(
          en: 'Mission ${updated.id} updated: ${_missionStatusLabel(context, updated.status)}',
          fr: 'Statut de la commande ${updated.id} mis à jour : ${updated.status}',
        ),
      );
    } on StateError catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) {
        _showMessage(context.tr(
          en: 'The mission update failed.',
          fr: 'La mise à jour de la mission a échoué.',
        ));
      }
    }
  }

  Future<void> _showUnlockDialog(String lockerId) async {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: LocalizedText(context.tr(
          en: 'Unlock locker $lockerId?',
          fr: 'Déverrouiller Casier $lockerId ?',
        )),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LocalizedText(context.tr(
              en: 'IoT unlock request sent to locker $lockerId.',
              fr: 'Action d’ouverture IoT envoyée au casier $lockerId.',
            )),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.wifi_rounded, color: AppColors.cyan, size: 18),
                SizedBox(width: 8),
                LocalizedText(
                  context.tr(
                    en: 'IoT signal received · Door unlocked',
                    fr: 'Signal IoT reçu · Porte déverrouillée',
                  ),
                  style: const TextStyle(color: AppColors.navy, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: LocalizedText(context.tr(en: 'Close', fr: 'Fermer')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showMessage(context.tr(
                en: 'Locker $lockerId unlocked successfully.',
                fr: 'Casier $lockerId déverrouillé avec succès.',
              ));
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.cyan),
            child: LocalizedText(context.tr(en: 'Confirm', fr: 'Confirmer')),
          ),
        ],
      ),
    );
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: LocalizedText(msg), behavior: SnackBarBehavior.floating),
    );
  }

  String _missionFilterLabel(BuildContext context, String filter) {
    return switch (filter) {
      'Toutes' => context.tr(en: 'All', fr: 'Toutes'),
      'À récupérer' => context.tr(en: 'To collect', fr: 'À récupérer'),
      'En transit' => context.tr(en: 'In transit', fr: 'En transit'),
      'Livrées' => context.tr(en: 'Delivered', fr: 'Livrées'),
      _ => filter,
    };
  }

  String _missionStatusLabel(BuildContext context, String status) {
    return switch (status) {
      'À récupérer' => context.tr(en: 'To collect', fr: 'À récupérer'),
      'En transit' => context.tr(en: 'In transit', fr: 'En transit'),
      'En lavage' => context.tr(en: 'At laundry', fr: 'En lavage'),
      'En transit retour' =>
        context.tr(en: 'Return transit', fr: 'En transit retour'),
      'Déposé au casier' =>
        context.tr(en: 'Deposited in locker', fr: 'Déposé au casier'),
      'Livré' => context.tr(en: 'Delivered', fr: 'Livré'),
      _ => status,
    };
  }
}
