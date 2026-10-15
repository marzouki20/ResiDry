import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_screen.dart';
import '../data/sample_laundry_data.dart';
import '../domain/models/lavage_order.dart';
import '../domain/models/machine.dart';
import '../domain/models/societe_lavage.dart';
import '../domain/models/programme_lavage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pages/machine_detail_page.dart';
import 'widgets/machine_card.dart';
import 'widgets/machine_form_dialog.dart';
import 'widgets/programme_selector_sheet.dart';

class SocieteInterface extends StatefulWidget {
  const SocieteInterface({super.key, this.userName});

  final String? userName;

  @override
  State<SocieteInterface> createState() => _SocieteInterfaceState();
}

class _SocieteInterfaceState extends State<SocieteInterface> {
  int _selectedIndex = 0;
  late SocieteLavage _currentSociete;
  late final List<LavageOrder> _orders;
  String _machineFilter = 'Toutes';
  bool _isAtelierOpen = true;

  @override
  void initState() {
    super.initState();
    _currentSociete = LaundryRepository.instance.findSocieteForUser(widget.userName);
    _orders = List<LavageOrder>.of(initialLavageOrders);
  }

  void _switchCompany(SocieteLavage societe) {
    setState(() {
      _currentSociete = societe;
    });
    Navigator.of(context).pop(); // close drawer
  }

  void _addOrEditMachine([Machine? machine]) {
    showDialog<void>(
      context: context,
      builder: (context) => MachineFormDialog(
        societeId: _currentSociete.id,
        machine: machine,
        onSave: (savedMachine) {
          final updatedMachines = List<Machine>.of(_currentSociete.machines);
          final index = updatedMachines.indexWhere((m) => m.id == savedMachine.id);

          if (index != -1) {
            updatedMachines[index] = savedMachine;
          } else {
            updatedMachines.insert(0, savedMachine);
          }

          final updatedSociete = _currentSociete.copyWith(machines: updatedMachines);
          LaundryRepository.instance.updateSociete(updatedSociete);

          setState(() => _currentSociete = updatedSociete);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                machine == null
                    ? 'Nouvelle machine ajoutée à votre atelier !'
                    : 'Machine modifiée avec succès !',
              ),
              backgroundColor: AppColors.navy,
            ),
          );
        },
      ),
    );
  }

  void _deleteMachine(Machine machine) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Supprimer la machine'),
          ],
        ),
        content: Text('Voulez-vous supprimer la machine "${machine.nom}" de votre atelier ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler', style: TextStyle(color: AppColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              final updatedMachines = List<Machine>.of(_currentSociete.machines)
                ..removeWhere((m) => m.id == machine.id);
              final updatedSociete = _currentSociete.copyWith(machines: updatedMachines);
              LaundryRepository.instance.deleteMachine(machine.id, _currentSociete.id);

              setState(() => _currentSociete = updatedSociete);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Machine "${machine.nom}" supprimée.'),
                  backgroundColor: AppColors.navy,
                ),
              );
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _toggleMachineCycle(Machine machine) {
    if (machine.statut == 'En cycle') {
      // End cycle -> set to available
      final updatedMachines = List<Machine>.of(_currentSociete.machines);
      final index = updatedMachines.indexWhere((m) => m.id == machine.id);
      if (index == -1) return;

      updatedMachines[index] = machine.copyWith(
        statut: 'Disponible',
        progressionCycle: 0.0,
        tempsRestantMinutes: 0,
        programmeActuel: null,
      );

      final updatedSociete = _currentSociete.copyWith(machines: updatedMachines);
      LaundryRepository.instance.updateSociete(updatedSociete);
      setState(() => _currentSociete = updatedSociete);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cycle terminé pour "${machine.nom}". Machine à nouveau disponible !'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } else {
      // Start cycle with Program Selector Sheet
      _showProgrammeSelectorSheet(machine);
    }
  }

  void _showProgrammeSelectorSheet(Machine machine) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProgrammeSelectorSheet(
        machine: machine,
        onProgrammeSelected: (programme) {
          _demarrerCycleAvecProgramme(machine, programme);
        },
      ),
    );
  }

  void _demarrerCycleAvecProgramme(Machine machine, ProgrammeLavage programme) {
    final updatedMachines = List<Machine>.of(_currentSociete.machines);
    final index = updatedMachines.indexWhere((m) => m.id == machine.id);
    if (index == -1) return;

    final nouvelleConsommation = machine.consommationKwh + programme.consommationKwh;

    updatedMachines[index] = machine.copyWith(
      statut: 'En cycle',
      progressionCycle: 0.1,
      tempsRestantMinutes: programme.dureeMinutes,
      temperatureC: programme.temperatureC,
      consommationKwh: double.parse(nouvelleConsommation.toStringAsFixed(2)),
      programmeActuel: programme.nom,
    );

    final updatedSociete = _currentSociete.copyWith(machines: updatedMachines);
    LaundryRepository.instance.updateSociete(updatedSociete);
    setState(() => _currentSociete = updatedSociete);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(programme.icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${machine.nom} ➔ ${programme.nom} lancé !\nDurée: ${programme.dureeMinutes} min • +${programme.consommationKwh} kWh ajoutés',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        backgroundColor: programme.couleur,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _changeMachineStatusQuick(Machine machine, String newStatus) {
    final updatedMachines = List<Machine>.of(_currentSociete.machines);
    final index = updatedMachines.indexWhere((m) => m.id == machine.id);
    if (index == -1) return;

    updatedMachines[index] = machine.copyWith(
      statut: newStatus,
      progressionCycle: newStatus == 'En cycle' ? 0.2 : 0.0,
      tempsRestantMinutes: newStatus == 'En cycle' ? 30 : 0,
    );

    final updatedSociete = _currentSociete.copyWith(machines: updatedMachines);
    LaundryRepository.instance.updateSociete(updatedSociete);
    setState(() => _currentSociete = updatedSociete);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              newStatus == 'Disponible'
                  ? Icons.check_circle_rounded
                  : newStatus == 'En cycle'
                      ? Icons.sync_rounded
                      : Icons.warning_amber_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${machine.nom} marquée comme : $newStatus',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: newStatus == 'Disponible'
            ? Colors.green.shade700
            : newStatus == 'En cycle'
                ? AppColors.navy
                : Colors.orange.shade800,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showChangeStatusDialog(Machine machine) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top drag handle
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Dialog Header: Machine Identity & Capacity
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.navy.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.precision_manufacturing_rounded,
                        color: AppColors.navy,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            machine.nom,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                machine.type,
                                style: const TextStyle(fontSize: 12, color: AppColors.muted),
                              ),
                              const Text(' • ', style: TextStyle(color: AppColors.muted)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.cyan.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Capacité: ${machine.capaciteKg.toStringAsFixed(0)} kg',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.navy,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fermer',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.line),
                const SizedBox(height: 14),

                const Text(
                  'SÉLECTIONNEZ LE NOUVEAU STATUT :',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w800,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 10),

                _statusOptionTile(
                  icon: Icons.check_circle_rounded,
                  color: Colors.green.shade600,
                  title: 'Disponible',
                  subtitle:
                      'Prête pour une tournée. Rajoute +${machine.capaciteKg.toStringAsFixed(0)} kg à la capacité active.',
                  isSelected: machine.statut == 'Disponible',
                  onTap: () {
                    Navigator.pop(context);
                    _changeMachineStatusQuick(machine, 'Disponible');
                  },
                ),
                const SizedBox(height: 6),
                _statusOptionTile(
                  icon: Icons.sync_rounded,
                  color: AppColors.cyan,
                  title: 'En cycle',
                  subtitle:
                      'En cours de lavage. Capacité tambour (${machine.capaciteKg.toStringAsFixed(0)} kg) actuellement occupée.',
                  isSelected: machine.statut == 'En cycle',
                  onTap: () {
                    Navigator.pop(context);
                    _changeMachineStatusQuick(machine, 'En cycle');
                  },
                ),
                const SizedBox(height: 6),
                _statusOptionTile(
                  icon: Icons.handyman_rounded,
                  color: Colors.orange.shade700,
                  title: 'Maintenance',
                  subtitle:
                      'Révision / nettoyage. Retranche -${machine.capaciteKg.toStringAsFixed(0)} kg de la capacité atelier.',
                  isSelected: machine.statut == 'Maintenance',
                  onTap: () {
                    Navigator.pop(context);
                    _changeMachineStatusQuick(machine, 'Maintenance');
                  },
                ),
                const SizedBox(height: 6),
                _statusOptionTile(
                  icon: Icons.cancel_rounded,
                  color: Colors.redAccent,
                  title: 'Hors service',
                  subtitle:
                      'Panne ou arrêt d\'urgence. Déduite de la capacité de production.',
                  isSelected: machine.statut == 'Hors service',
                  onTap: () {
                    Navigator.pop(context);
                    _changeMachineStatusQuick(machine, 'Hors service');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusOptionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : AppColors.line,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected ? color : AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.2),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
              ),
          ],
        ),
      ),
    );
  }

  void _logout() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      'Atelier & Machines',
      'Flux de Linge (${_orders.length})',
      'Supervision IoT',
      'Profil Partenaire',
    ];

    return Scaffold(
      backgroundColor: AppColors.cream,
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
        actions: [
          // Open/Closed Atelier Status Chip
          GestureDetector(
            onTap: () {
              setState(() => _isAtelierOpen = !_isAtelierOpen);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isAtelierOpen
                        ? 'Atelier marqué comme: OUVERT'
                        : 'Atelier marqué comme: EN PAUSE',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _isAtelierOpen
                    ? Colors.green.shade50
                    : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isAtelierOpen
                      ? Colors.green.shade400
                      : Colors.amber.shade400,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 4,
                    backgroundColor: _isAtelierOpen
                        ? Colors.green.shade700
                        : Colors.amber.shade800,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isAtelierOpen ? 'Ouvert' : 'En pause',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _isAtelierOpen
                          ? Colors.green.shade800
                          : Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Déconnexion',
            icon: const Icon(Icons.logout_rounded, color: AppColors.navy),
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _atelierAndMachinesPage(),
          _laundryOrdersPage(),
          _iotSupervisionPage(),
          _profilePage(),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _addOrEditMachine(),
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nouvelle machine'),
            )
          : null,
    );
  }

  Widget _buildDrawer() {
    return Drawer(
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.cyan,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.local_laundry_service_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentSociete.nom,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'SOCIÉTÉ DE LAVAGE',
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
                    tooltip: 'Fermer',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.line),

            // Atelier Switcher (if user wants to test other partner pressings during demo)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz_rounded, size: 18, color: AppColors.navy),
                    const SizedBox(width: 8),
                    const Text('Atelier :', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _currentSociete.id,
                          isExpanded: true,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                          items: LaundryRepository.instance.societes.map((s) {
                            return DropdownMenuItem(
                              value: s.id,
                              child: Text(s.nom, maxLines: 1, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (selectedId) {
                            if (selectedId != null) {
                              final found = LaundryRepository.instance.societes
                                  .firstWhere((s) => s.id == selectedId);
                              _switchCompany(found);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 16, 8),
              child: Text(
                'MENU PARTENAIRE',
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
                  _drawerItem(
                    index: 0,
                    icon: Icons.local_laundry_service_outlined,
                    selectedIcon: Icons.local_laundry_service_rounded,
                    label: 'Atelier & Machines',
                  ),
                  _drawerItem(
                    index: 1,
                    icon: Icons.inventory_2_outlined,
                    selectedIcon: Icons.inventory_2_rounded,
                    label: 'Commandes de linge',
                  ),
                  _drawerItem(
                    index: 2,
                    icon: Icons.sensors_outlined,
                    selectedIcon: Icons.sensors_rounded,
                    label: 'Supervision IoT',
                  ),
                  _drawerItem(
                    index: 3,
                    icon: Icons.business_outlined,
                    selectedIcon: Icons.business_rounded,
                    label: 'Profil Société',
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.line),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                title: const Text(
                  'Déconnexion',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: _logout,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final selected = _selectedIndex == index;
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
        onTap: () {
          setState(() => _selectedIndex = index);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 0 : ATELIER & MACHINES
  // -------------------------------------------------------------
  Widget _atelierAndMachinesPage() {
    final machines = _currentSociete.machines;
    final filteredMachines = machines.where((m) {
      if (_machineFilter == 'Disponibles') return m.statut == 'Disponible';
      if (_machineFilter == 'En cycle') return m.statut == 'En cycle';
      if (_machineFilter == 'Maintenance') return m.statut == 'Maintenance' || m.statut == 'Hors service';
      return true;
    }).toList();

    final disponiblesCount = machines.where((m) => m.statut == 'Disponible').length;
    final enCycleCount = machines.where((m) => m.statut == 'En cycle').length;
    final maintenanceCount = machines.where((m) => m.statut == 'Maintenance' || m.statut == 'Hors service').length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
      children: [
        // Company Identity Banner Card
        _companyBannerCard(),
        const SizedBox(height: 16),

        // Live KPI Grid
        Row(
          children: [
            Expanded(
              child: _kpiCard(
                label: 'Disponibles',
                count: '$disponiblesCount',
                icon: Icons.check_circle_outline_rounded,
                color: Colors.green.shade600,
                onTap: () => setState(() => _machineFilter = 'Disponibles'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _kpiCard(
                label: 'En cycle',
                count: '$enCycleCount',
                icon: Icons.sync_rounded,
                color: AppColors.cyan,
                onTap: () => setState(() => _machineFilter = 'En cycle'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _kpiCard(
                label: 'Maintenance',
                count: '$maintenanceCount',
                icon: Icons.handyman_outlined,
                color: Colors.orange.shade700,
                onTap: () => setState(() => _machineFilter = 'Maintenance'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Section Title & Filters (Responsive without overflow)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mon Parc de Machines',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${filteredMachines.length} machine(s)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: ['Toutes', 'Disponibles', 'En cycle', 'Maintenance'].map((f) {
                  final isSelected = _machineFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        f,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.navy,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.navy),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSelected ? AppColors.navy : AppColors.line,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onSelected: (selected) {
                        if (selected) setState(() => _machineFilter = f);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Machine Cards List
        if (filteredMachines.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                const Icon(Icons.inbox_rounded, size: 48, color: AppColors.muted),
                const SizedBox(height: 12),
                Text(
                  'Aucune machine pour le filtre "$_machineFilter"',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ajoutez une machine ou changez le filtre.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          )
        else
          ...filteredMachines.map((machine) {
            return Column(
              children: [
                MachineCard(
                  machine: machine,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => MachineDetailPage(
                          machine: machine,
                          onMachineUpdated: (updated) {
                            final list = List<Machine>.of(_currentSociete.machines);
                            final i = list.indexWhere((m) => m.id == updated.id);
                            if (i != -1) list[i] = updated;
                            final soc = _currentSociete.copyWith(machines: list);
                            LaundryRepository.instance.updateSociete(soc);
                            setState(() => _currentSociete = soc);
                          },
                        ),
                      ),
                    );
                  },
                  onEdit: () => _addOrEditMachine(machine),
                  onDelete: () => _deleteMachine(machine),
                  onToggleCycle: () => _toggleMachineCycle(machine),
                ),
                // Direct Action Bar under card to easily change status/cycle
                _quickActionBarForMachine(machine),
                const SizedBox(height: 8),
              ],
            );
          }),
      ],
    );
  }

  Widget _companyBannerCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentSociete.nom,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _currentSociete.adresse,
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.line),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _badgeItem(Icons.star_rounded, '${_currentSociete.noteEvaluation} / 5', Colors.amber.shade800),
              _badgeItem(
                Icons.scale_rounded,
                'Capacité: ${_currentSociete.capaciteTotaleInstallee.toStringAsFixed(0)} kg',
                AppColors.cyan,
              ),
              _badgeItem(Icons.sensors_rounded, 'IoT: ${_currentSociete.iotHealthScore}%', Colors.green.shade700),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badgeItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _kpiCard({
    required String label,
    required String count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              count,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionBarForMachine(Machine machine) {
    return Container(
      margin: const EdgeInsets.only(top: 2, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Statut: ${machine.statut}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.navy),
          ),
          Wrap(
            spacing: 6,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  side: const BorderSide(color: AppColors.navy),
                ),
                icon: const Icon(Icons.tune_rounded, size: 14, color: AppColors.navy),
                label: const Text('Modifier statut', style: TextStyle(fontSize: 11, color: AppColors.navy)),
                onPressed: () => _showChangeStatusDialog(machine),
              ),
              if (machine.statut != 'En cycle')
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 14),
                  label: const Text('Démarrer cycle', style: TextStyle(fontSize: 11)),
                  onPressed: () => _toggleMachineCycle(machine),
                )
              else
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 14),
                  label: const Text('Fin de cycle', style: TextStyle(fontSize: 11)),
                  onPressed: () => _toggleMachineCycle(machine),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1 : COMMANDES & FLUX DE LINGE DES CASIERS
  // -------------------------------------------------------------
  Widget _laundryOrdersPage() {
    final enAttente = _orders.where((o) => o.statut == 'En attente').length;
    final enLavage = _orders.where((o) => o.statut == 'En cours de lavage').length;
    final prets = _orders.where((o) => o.statut == 'Prêt pour retour casier').length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const Text(
          'Commandes issues des casiers',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Linge déposé par les résidents et acheminé par les livreurs.',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 16),

        // Quick Stats Row
        Row(
          children: [
            _orderStatusChip('À traiter ($enAttente)', Colors.amber.shade800),
            const SizedBox(width: 8),
            _orderStatusChip('En lavage ($enLavage)', AppColors.cyan),
            const SizedBox(width: 8),
            _orderStatusChip('Prêts casier ($prets)', Colors.green.shade700),
          ],
        ),
        const SizedBox(height: 16),

        ..._orders.map((order) => _buildOrderCard(order)),
      ],
    );
  }

  Widget _orderStatusChip(String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(LavageOrder order) {
    Color statusColor;
    IconData statusIcon;

    switch (order.statut) {
      case 'En attente':
        statusColor = Colors.amber.shade800;
        statusIcon = Icons.pending_actions_rounded;
        break;
      case 'En cours de lavage':
        statusColor = AppColors.cyan;
        statusIcon = Icons.autorenew_rounded;
        break;
      case 'Prêt pour retour casier':
      default:
        statusColor = Colors.green.shade700;
        statusIcon = Icons.task_alt_rounded;
        break;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.id,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    order.residentName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        order.statut,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.door_front_door_outlined, size: 15, color: AppColors.muted),
                const SizedBox(width: 6),
                Text(order.casierId, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                const SizedBox(width: 16),
                const Icon(Icons.scale_outlined, size: 15, color: AppColors.muted),
                const SizedBox(width: 6),
                Text('${order.poidsKg} kg', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                const SizedBox(width: 16),
                const Icon(Icons.dry_cleaning_outlined, size: 15, color: AppColors.muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.typeService,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ),
              ],
            ),
            if (order.machineAttribuee != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.local_laundry_service_outlined, size: 14, color: AppColors.cyan),
                  const SizedBox(width: 6),
                  Text(
                    'Machine : ${order.machineAttribuee}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.cyan),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.line),
            const SizedBox(height: 8),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (order.statut == 'En attente')
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    icon: const Icon(Icons.play_circle_fill_rounded, size: 16),
                    label: const Text('Lancer le lavage'),
                    onPressed: () {
                      setState(() {
                        order.statut = 'En cours de lavage';
                        // Pick first available machine if any
                        final available = _currentSociete.machines
                            .where((m) => m.statut == 'Disponible')
                            .toList();
                        if (available.isNotEmpty) {
                          order.machineAttribuee = available.first.nom;
                          available.first.statut = 'En cycle';
                          available.first.progressionCycle = 0.3;
                          available.first.tempsRestantMinutes = 35;
                        }
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lavage démarré pour ${order.id} !'),
                          backgroundColor: AppColors.navy,
                        ),
                      );
                    },
                  )
                else if (order.statut == 'En cours de lavage')
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: const Text('Marquer Prêt pour Livreur'),
                    onPressed: () {
                      setState(() {
                        order.statut = 'Prêt pour retour casier';
                        // Free the machine if assigned
                        if (order.machineAttribuee != null) {
                          final m = _currentSociete.machines
                              .where((m) => m.nom == order.machineAttribuee);
                          if (m.isNotEmpty) {
                            m.first.statut = 'Disponible';
                            m.first.progressionCycle = 0.0;
                          }
                        }
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Linge prêt pour le livreur (${order.id}) !'),
                          backgroundColor: Colors.green.shade700,
                        ),
                      );
                    },
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(radius: 3.5, backgroundColor: Colors.green.shade700),
                            const SizedBox(width: 6),
                            Text(
                              'Prêt pour collecte',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                        label: const Text(
                          'Alerter le livreur (WhatsApp)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () => _notifierLivreurWhatsApp(order),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _notifierLivreurWhatsApp(LavageOrder order) async {
    // Numéro de téléphone du livreur de permanence (Tunisie +216)
    const String telephoneLivreur = '+21698765432';

    // Message logistique complet
    final String message =
        '🚚 *ALERTE COLLECTE LINGE - RESIDRY*\n\n'
        'Bonjour Livreur 👋,\n'
        'Une commande vient d\'être traitée par l\'atelier *${_currentSociete.nom}* et attend votre ramassage :\n\n'
        '📋 *Réf Commande :* ${order.id}\n'
        '👤 *Résident :* ${order.residentName}\n'
        '📦 *Destination :* ${order.casierId}\n'
        '⚖️ *Poids :* ${order.poidsKg} kg\n'
        '🧺 *Service :* ${order.typeService}\n\n'
        'Merci de passer récupérer le paquet pour remise en casier !';

    final Uri whatsappUrl = Uri.parse(
      'https://wa.me/$telephoneLivreur?text=${Uri.encodeComponent(message)}',
    );

    try {
      final bool launched = await launchUrl(
        whatsappUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // Fallback avec mode universel
        await launchUrl(whatsappUrl, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir WhatsApp. Vérifiez que l\'application est installée.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // -------------------------------------------------------------
  // TAB 2 : SUPERVISION IOT
  // -------------------------------------------------------------
  Widget _iotSupervisionPage() {
    double totalKwh = 0;
    for (final m in _currentSociete.machines) {
      totalKwh += m.consommationKwh;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const Text(
          'Supervision IoT & Capteurs',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Télémétrie en direct des équipements connectés de l’atelier.',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 16),

        // IoT Gateway Status Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.wifi_tethering_rounded, color: Colors.green.shade700, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Passerelle IoT Résidentielle',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navy),
                    ),
                    Text(
                      'Synchronisation active avec les casiers · 100% Signal',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'EN LIGNE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Telemetry Metrics Row
        Row(
          children: [
            Expanded(
              child: _iotMetricTile(
                title: 'Consommation Élec.',
                value: '${totalKwh.toStringAsFixed(1)} kWh',
                sub: 'Aujourd’hui',
                icon: Icons.bolt_rounded,
                color: Colors.amber.shade800,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _iotMetricTile(
                title: 'Santé Globale IoT',
                value: '${_currentSociete.iotHealthScore}%',
                sub: 'Aucune défaillance',
                icon: Icons.monitor_heart_rounded,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        const Text(
          'Capteurs actifs par machine',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy),
        ),
        const SizedBox(height: 10),

        ..._currentSociete.machines.map((m) {
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.line),
            ),
            color: Colors.white,
            child: ListTile(
              leading: Icon(
                Icons.memory_rounded,
                color: m.santeIot >= 90 ? Colors.green.shade700 : Colors.orange.shade700,
              ),
              title: Text(m.nom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(
                'Temp: ${m.temperatureC}°C · Vibrations: ${m.vibrationLevel} m/s² · ${m.consommationKwh} kWh',
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
              trailing: Text(
                'IoT ${m.santeIot}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: m.santeIot >= 90 ? Colors.green.shade700 : Colors.orange.shade700,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _iotMetricTile({
    required String title,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navy)),
          Text(sub, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 3 : PROFIL SOCIÉTÉ & COORDONNÉES
  // -------------------------------------------------------------
  Widget _profilePage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const Text(
          'Profil de l’Atelier',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Informations contractuelles et coordonnées du pressing.',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 20),

        Center(
          child: CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.navy,
            child: Text(
              _currentSociete.nom.isNotEmpty ? _currentSociete.nom[0].toUpperCase() : 'S',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            _currentSociete.nom,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy),
          ),
        ),
        Center(
          child: Text(
            'Partenaire officiel ResiDry · ID: ${_currentSociete.id}',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ),
        const SizedBox(height: 24),

        _profileTile(Icons.location_on_outlined, 'Adresse', _currentSociete.adresse),
        const SizedBox(height: 10),
        _profileTile(Icons.phone_outlined, 'Téléphone', _currentSociete.telephone),
        const SizedBox(height: 10),
        _profileTile(Icons.email_outlined, 'Email professionnel', _currentSociete.email),
        const SizedBox(height: 10),
        _profileTile(Icons.fitness_center_outlined, 'Capacité maximale', '${_currentSociete.capaciteMaxKg} kg / jour'),
        const SizedBox(height: 10),
        _profileTile(
          Icons.calendar_today_outlined,
          'Début du partenariat',
          '${_currentSociete.datePartenariat.day}/${_currentSociete.datePartenariat.month}/${_currentSociete.datePartenariat.year}',
        ),
        const SizedBox(height: 24),

        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Se déconnecter', style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: _logout,
        ),
      ],
    );
  }

  Widget _profileTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.navy, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navy)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
