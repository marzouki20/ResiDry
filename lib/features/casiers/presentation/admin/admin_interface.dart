import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../laundry_companies/presentation/societes_lavage_page.dart';
import '../navigation/admin_navigation_bar.dart';
import '../widgets/casier_components.dart';

class AdminInterface extends StatefulWidget {
  const AdminInterface({super.key, this.userName});

  final String? userName;

  @override
  State<AdminInterface> createState() => _AdminInterfaceState();
}

class _AdminInterfaceState extends State<AdminInterface> {
  int _selectedIndex = 0;
  String _query = '';
  String _filter = 'Tous';
  final Set<String> _handledAnomalies = {};
  late final List<LockerRecord> _lockers = List<LockerRecord>.of(demoLockers);

  @override
  Widget build(BuildContext context) {
    final titles = [
      'Tableau de bord',
      'Gestion des casiers',
      'Anomalies',
      'Maintenance',
      'Profil',
      'Sociétés de lavage',
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
            onPressed: () => setState(() => _selectedIndex = 2),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: AdminNavigationBar(
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
          _lockersPage(),
          _anomaliesPage(),
          _maintenancePage(),
          _profilePage(),
          SocietesLavagePage(userName: widget.userName),
        ],
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () => _editLocker(),
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }

  Widget _dashboard() {
    final connected = _lockers.where((locker) => locker.connected).length;
    final offline = _lockers.length - connected;
    final maintenance = _lockers
        .where((locker) => locker.status == 'Maintenance')
        .length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        PageHeading(
          title:
              'Bonjour${widget.userName == null ? '' : ', ${widget.userName}'}',
          subtitle: 'Voici l’état de vos casiers en temps réel.',
          trailing: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.line),
            ),
            child: const Icon(
              Icons.sensors_rounded,
              color: AppColors.cyan,
              size: 23,
            ),
          ),
        ),
        const SizedBox(height: 22),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            MetricCard(
              label: 'Casiers au total',
              value: '${_lockers.length}',
              icon: Icons.door_front_door_outlined,
            ),
            MetricCard(
              label: 'Disponibles',
              value:
                  '${_lockers.where((locker) => locker.status == 'Disponible').length}',
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.cyan,
            ),
            MetricCard(
              label: 'Occupés',
              value:
                  '${_lockers.where((locker) => locker.status == 'Normal' || locker.status == 'Anomalie').length}',
              icon: Icons.inventory_2_outlined,
            ),
            MetricCard(
              label: 'En maintenance',
              value: '$maintenance',
              icon: Icons.handyman_outlined,
              color: const Color(0xFF7457E8),
            ),
            MetricCard(
              label: 'IoT connectés',
              value: '$connected',
              icon: Icons.wifi_rounded,
              color: AppColors.cyan,
            ),
            MetricCard(
              label: 'IoT hors ligne',
              value: '$offline',
              icon: Icons.wifi_off_rounded,
              color: const Color(0xFFE45858),
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
              Icon(Icons.warning_amber_rounded, color: AppColors.coral),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Anomalies actives',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${5 - _handledAnomalies.length} cas nécessitent votre attention',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const SectionTitle('Alertes récentes'),
        _alertTile(
          'C-024',
          'Porte ouverte depuis 12 minutes',
          Icons.door_front_door_outlined,
          const Color(0xFFE77B32),
          'Il y a 2 min',
        ),
        _alertTile(
          'C-017',
          'Appareil IoT déconnecté',
          Icons.wifi_off_rounded,
          const Color(0xFFE45858),
          'Il y a 8 min',
        ),
        _alertTile(
          'C-031',
          'Humidité anormale détectée',
          Icons.water_drop_outlined,
          const Color(0xFFE77B32),
          'Il y a 15 min',
        ),
      ],
    );
  }

  Widget _lockersPage() {
    final lockers = _lockers.where((locker) {
      final matchesQuery =
          locker.id.toLowerCase().contains(_query.toLowerCase()) ||
          locker.resident.toLowerCase().contains(_query.toLowerCase()) ||
          locker.apartment.toLowerCase().contains(_query.toLowerCase());
      final matchesFilter = switch (_filter) {
        'Connectés' => locker.connected,
        'Anomalies' => locker.status == 'Anomalie',
        'Maintenance' => locker.status == 'Maintenance',
        _ => true,
      };
      return matchesQuery && matchesFilter;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        const PageHeading(
          title: 'Gestion des casiers',
          subtitle: 'Surveillez et gérez les équipements de la résidence.',
        ),
        const SizedBox(height: 20),
        TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            hintText: 'Rechercher un casier, résident...',
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
              for (final filter in [
                'Tous',
                'Connectés',
                'Anomalies',
                'Maintenance',
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: _filter == filter,
                    onSelected: (_) => setState(() => _filter = filter),
                    selectedColor: AppColors.cyan.withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                      color: _filter == filter
                          ? AppColors.navy
                          : AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: _filter == filter
                          ? AppColors.cyan
                          : AppColors.line,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (final locker in lockers) _lockerCard(locker),
        if (lockers.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                'Aucun casier trouvé.',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          ),
      ],
    );
  }

  Widget _lockerCard(LockerRecord locker) => Card(
    margin: const EdgeInsets.only(bottom: 13),
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: AppColors.line),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.door_front_door_outlined,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locker.id,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${locker.resident} · ${locker.apartment}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (action) => _lockerAction(action, locker),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'details', child: Text('Voir détails')),
                  PopupMenuItem(value: 'edit', child: Text('Modifier')),
                  PopupMenuItem(
                    value: 'assign',
                    child: Text('Attribuer résident'),
                  ),
                  PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _miniValue('Poids', '${locker.weight} kg')),
              Expanded(
                child: _miniValue(
                  'Porte',
                  locker.doorOpen ? 'Ouverte' : 'Fermée',
                ),
              ),
              Expanded(
                child: _miniValue(
                  'Verrou',
                  locker.locked ? 'Verrouillé' : 'Ouvert',
                ),
              ),
            ],
          ),
          const Divider(height: 22, color: AppColors.line),
          Row(
            children: [
              Expanded(
                child: Text(
                  'IoT ${locker.connected ? 'connecté' : 'hors ligne'} · ${locker.temperature}°C · ${locker.humidity}%',
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ),
              StatusPill(
                locker.status,
                color: lockerStatusColor(locker.status),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _openDetails(locker),
              child: const Text('Voir le suivi IoT'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _miniValue(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );

  Widget _anomaliesPage() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
    children: [
      const PageHeading(
        title: 'Anomalies & alertes',
        subtitle: 'Détection intelligente et suivi des événements.',
      ),
      const SizedBox(height: 16),
      MetricCard(
        label: 'À traiter',
        value: '${5 - _handledAnomalies.length}',
        icon: Icons.notification_important_outlined,
        color: Color(0xFFE77B32),
        caption: '2 critiques · 1 modérée',
      ),
      const SizedBox(height: 12),
      if (!_handledAnomalies.contains('C-024'))
        _anomalyTile(
          'C-024',
          'Porte laissée ouverte',
          'Aujourd’hui · 13:02',
          'Élevée',
          const Color(0xFFE77B32),
        ),
      if (!_handledAnomalies.contains('C-031'))
        _anomalyTile(
          'C-031',
          'Humidité anormale · 71%',
          'Aujourd’hui · 12:48',
          'Modérée',
          const Color(0xFFE77B32),
        ),
      if (!_handledAnomalies.contains('C-017'))
        _anomalyTile(
          'C-017',
          'Déconnexion du module IoT',
          'Aujourd’hui · 12:35',
          'Critique',
          const Color(0xFFE45858),
        ),
      if (!_handledAnomalies.contains('C-009'))
        _anomalyTile(
          'C-009',
          'Tentatives d’accès répétées',
          'Hier · 19:24',
          'Critique',
          const Color(0xFFE45858),
        ),
      if (!_handledAnomalies.contains('C-042'))
        _anomalyTile(
          'C-042',
          'Variation inhabituelle du poids',
          'Hier · 16:10',
          'Modérée',
          const Color(0xFFE77B32),
        ),
    ],
  );

  Widget _anomalyTile(
    String id,
    String title,
    String time,
    String severity,
    Color color,
  ) => Card(
    margin: const EdgeInsets.only(top: 11),
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(17),
      side: const BorderSide(color: AppColors.line),
    ),
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Casier $id',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              StatusPill(severity, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(color: AppColors.ink)),
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _handledAnomalies.add(id));
                    _showMessage('Anomalie $id marquée comme résolue.');
                  },
                  child: const Text('Résoudre'),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () {
                    final locker = _lockers.where((item) => item.id == id);
                    setState(() {
                      _handledAnomalies.add(id);
                      if (locker.isNotEmpty) {
                        locker.first.status = 'Maintenance';
                      }
                    });
                    _showMessage('Casier $id marqué en maintenance.');
                  },
                  child: const Text('Maintenance'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _maintenancePage() {
    final lockers = _lockers.where((locker) => locker.status == 'Maintenance');
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const PageHeading(
          title: 'Maintenance',
          subtitle: 'Équipements à contrôler ou en cours de réparation.',
        ),
        const SizedBox(height: 16),
        for (final locker in lockers)
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(17),
              side: const BorderSide(color: AppColors.line),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0x147457E8),
                child: Icon(Icons.handyman_outlined, color: Color(0xFF7457E8)),
              ),
              title: Text(locker.id),
              subtitle: Text('${locker.resident} · Vérification du verrou'),
              trailing: const StatusPill('En cours', color: Color(0xFF7457E8)),
            ),
          ),
        const SizedBox(height: 14),
        _anomalyTile(
          'C-017',
          'Module IoT hors ligne — diagnostic nécessaire',
          'Signalé aujourd’hui · 12:35',
          'Prioritaire',
          const Color(0xFFE45858),
        ),
      ],
    );
  }

  Widget _profilePage() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
    children: [
      const PageHeading(
        title: 'Profil administrateur',
        subtitle: 'Gestion de la résidence et des équipements.',
      ),
      const SizedBox(height: 24),
      const CircleAvatar(
        radius: 38,
        backgroundColor: AppColors.navy,
        child: Icon(
          Icons.admin_panel_settings_outlined,
          color: Colors.white,
          size: 35,
        ),
      ),
      const SizedBox(height: 12),
      Center(
        child: Text(
          widget.userName ?? 'Administrateur',
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const Center(
        child: Text(
          'Gestionnaire ResiDry',
          style: TextStyle(color: AppColors.muted),
        ),
      ),
      const SizedBox(height: 24),
      const DetailTile(
        label: 'Résidence',
        value: 'Résidence universitaire',
        icon: Icons.apartment_rounded,
      ),
      const SizedBox(height: 10),
      const DetailTile(
        label: 'Réseau',
        value: 'Passerelle IoT opérationnelle',
        icon: Icons.hub_outlined,
        color: AppColors.cyan,
      ),
    ],
  );

  Widget _alertTile(
    String locker,
    String message,
    IconData icon,
    Color color,
    String time,
  ) => Container(
    margin: const EdgeInsets.only(top: 9),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: AppColors.line),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Casier $locker',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                message,
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: const TextStyle(color: AppColors.muted, fontSize: 10),
        ),
      ],
    ),
  );

  void _lockerAction(String action, LockerRecord locker) {
    switch (action) {
      case 'details':
        _openDetails(locker);
        break;
      case 'edit':
        _editLocker(locker);
        break;
      case 'assign':
        _editLocker(locker);
        break;
      case 'delete':
        _confirmDelete(locker);
        break;
    }
  }

  Future<void> _confirmDelete(LockerRecord locker) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le casier ?'),
        content: Text('Le casier ${locker.id} sera retiré de la liste.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _lockers.remove(locker));
      _showMessage('Casier ${locker.id} supprimé.');
    }
  }

  Future<void> _editLocker([LockerRecord? locker]) async {
    final idController = TextEditingController(text: locker?.id ?? '');
    final residentController = TextEditingController(
      text: locker?.resident == 'Non attribué' ? '' : locker?.resident ?? '',
    );
    final apartmentController = TextEditingController(
      text: locker?.apartment ?? '',
    );
    final weightController = TextEditingController(
      text: locker?.maxWeight.toString() ?? '8.0',
    );
    var type = locker?.lockerType ?? 'Standard';
    var iotEnabled = locker?.connected ?? true;
    var climateMonitoring = locker?.climateMonitoring ?? true;
    var rfidEnabled = locker?.rfidEnabled ?? true;
    var electronicLock = locker?.electronicLock ?? true;
    final formKey = GlobalKey<FormState>();

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(locker == null ? 'Nouveau casier' : 'Modifier le casier'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _formField(idController, 'Identifiant du casier'),
                    _formField(residentController, 'Résident'),
                    _formField(apartmentController, 'Appartement'),
                    _formField(
                      weightController,
                      'Poids maximal (kg)',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final weight = double.tryParse(value ?? '');
                        return weight == null || weight <= 0
                            ? 'Saisissez un poids valide'
                            : null;
                      },
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: const [
                        DropdownMenuItem(
                          value: 'Standard',
                          child: Text('Standard'),
                        ),
                        DropdownMenuItem(value: 'Grand', child: Text('Grand')),
                        DropdownMenuItem(
                          value: 'Réfrigéré',
                          child: Text('Contrôlé'),
                        ),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => type = value ?? 'Standard'),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Appareil IoT activé'),
                      value: iotEnabled,
                      onChanged: (value) =>
                          setDialogState(() => iotEnabled = value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Suivi température / humidité'),
                      value: climateMonitoring,
                      onChanged: (value) =>
                          setDialogState(() => climateMonitoring = value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('RFID / NFC'),
                      value: rfidEnabled,
                      onChanged: (value) =>
                          setDialogState(() => rfidEnabled = value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Verrou électronique'),
                      value: electronicLock,
                      onChanged: (value) =>
                          setDialogState(() => electronicLock = value),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
    if (save != true || !mounted) {
      idController.dispose();
      residentController.dispose();
      apartmentController.dispose();
      weightController.dispose();
      return;
    }
    final parsedWeight = double.tryParse(weightController.text) ?? 8;
    final lockerId = idController.text.trim();
    final residentName = residentController.text.trim();
    final apartment = apartmentController.text.trim();
    idController.dispose();
    residentController.dispose();
    apartmentController.dispose();
    weightController.dispose();
    setState(() {
      if (locker == null) {
        _lockers.insert(
          0,
          LockerRecord(
            id: lockerId,
            resident: residentName.isEmpty ? 'Non attribué' : residentName,
            apartment: apartment.isEmpty ? '—' : apartment,
            maxWeight: parsedWeight,
            lockerType: type,
            climateMonitoring: climateMonitoring,
            rfidEnabled: rfidEnabled,
            electronicLock: electronicLock,
            weight: 0,
            connected: iotEnabled,
            status: residentName.isEmpty ? 'Disponible' : 'Normal',
          ),
        );
      } else {
        locker
          ..id = lockerId
          ..resident = residentName.isEmpty ? 'Non attribué' : residentName
          ..apartment = apartment.isEmpty ? '—' : apartment
          ..maxWeight = parsedWeight
          ..lockerType = type
          ..climateMonitoring = climateMonitoring
          ..rfidEnabled = rfidEnabled
          ..electronicLock = electronicLock
          ..connected = iotEnabled
          ..status = residentName.isEmpty
              ? 'Disponible'
              : locker.status == 'Disponible'
              ? 'Normal'
              : locker.status;
      }
    });
    _showMessage(locker == null ? 'Casier créé.' : 'Casier mis à jour.');
  }

  Widget _formField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
      validator:
          validator ??
          (value) => value == null || value.trim().isEmpty
              ? 'Champ obligatoire'
              : null,
    ),
  );

  void _openDetails(LockerRecord locker) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _LockerDetailsPage(locker: locker),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _LockerDetailsPage extends StatelessWidget {
  const _LockerDetailsPage({required this.locker});

  final LockerRecord locker;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Casier ${locker.id}')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                locker.id,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            StatusPill(locker.status, color: lockerStatusColor(locker.status)),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          '${locker.resident} · ${locker.apartment}',
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 6),
        Text(
          '${locker.lockerType} · Charge max. ${locker.maxWeight} kg · RFID/NFC ${locker.rfidEnabled ? 'activé' : 'désactivé'}',
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            DetailTile(
              label: 'Connexion IoT',
              value: locker.connected ? 'Connecté' : 'Hors ligne',
              icon: Icons.wifi_rounded,
              color: locker.connected ? AppColors.cyan : Colors.red,
            ),
            DetailTile(
              label: 'Porte',
              value: locker.doorOpen ? 'Ouverte' : 'Fermée',
              icon: Icons.door_front_door_outlined,
            ),
            DetailTile(
              label: 'Verrou',
              value: locker.locked ? 'Verrouillé' : 'Déverrouillé',
              icon: Icons.lock_outline_rounded,
            ),
            DetailTile(
              label: 'Poids actuel',
              value: '${locker.weight} kg',
              icon: Icons.scale_outlined,
              color: AppColors.cyan,
            ),
            DetailTile(
              label: 'Température',
              value: '${locker.temperature}°C',
              icon: Icons.thermostat_rounded,
            ),
            DetailTile(
              label: 'Humidité',
              value: '${locker.humidity}%',
              icon: Icons.water_drop_outlined,
            ),
          ],
        ),
        const SizedBox(height: 13),
        const DetailTile(
          label: 'Dernière activité',
          value: 'Aujourd’hui à 13:14',
          icon: Icons.schedule_rounded,
        ),
        const SizedBox(height: 24),
        const SectionTitle('Surveillance IoT'),
        const SizedBox(height: 10),
        const TrendCard(title: 'Historique du poids', value: '5.2 kg'),
        const SizedBox(height: 10),
        const TrendCard(title: 'Température', value: '24°C'),
        const SizedBox(height: 10),
        const TrendCard(title: 'Humidité', value: '48%'),
        const SizedBox(height: 10),
        const TrendCard(title: 'Activité de la porte', value: '4 ouvertures'),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: locker.status == 'Anomalie'
                ? const Color(0xFFFFF1E8)
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Détection IA des anomalies',
                style: TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              StatusPill(
                locker.status == 'Anomalie'
                    ? 'Comportement anormal détecté'
                    : 'Aucune anomalie détectée',
                color: locker.status == 'Anomalie'
                    ? const Color(0xFFE77B32)
                    : AppColors.cyan,
              ),
              const SizedBox(height: 8),
              const Text(
                'Confiance du modèle · 96%',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
