import 'package:flutter/material.dart';

import '../../../core/localization/localized_text.dart';

import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/delivery_driver.dart';
import '../../../../models/delivery_order.dart';
import '../../casiers/presentation/widgets/casier_components.dart';
import '../data/delivery_repository.dart';
import '../data/sqlite_delivery_repository.dart';
import 'capacity_review_screen.dart';
import '../../../core/backend/backend_client.dart';
import 'backend_application_review.dart';

class AdminDriverManagementView extends StatefulWidget {
  const AdminDriverManagementView(
      {super.key, this.repository, this.reviewer = 'Administrator'});
  final String reviewer;

  final DeliveryRepository? repository;

  @override
  State<AdminDriverManagementView> createState() =>
      _AdminDriverManagementViewState();
}

class _AdminDriverManagementViewState extends State<AdminDriverManagementView> {
  late final DeliveryRepository _repository =
      widget.repository ?? SqliteDeliveryRepository();
  List<DeliveryDriver> _drivers = [];
  List<DeliveryOrder> _orders = [];
  bool _isLoading = true;
  String? _loadError;
  String _filter = 'Tous';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (BackendClient.enabled) {
      _isLoading = false;
    } else {
      _loadDeliveryData();
    }
  }

  Future<void> _loadDeliveryData() async {
    try {
      final results = await Future.wait([
        _repository.getDrivers(),
        _repository.getMissions(),
      ]);
      if (!mounted) return;
      setState(() {
        _drivers = results[0] as List<DeliveryDriver>;
        _orders = results[1] as List<DeliveryOrder>;
        _isLoading = false;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Impossible de charger les données de livraison.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (BackendClient.enabled) {
      return ListView(padding: const EdgeInsets.all(20), children: [
        PageHeading(
            title:
                context.tr(en: 'Driver management', fr: 'Gestion des livreurs'),
            subtitle: context.tr(
                en: 'Review independent driver applications.',
                fr: 'Examinez les candidatures des livreurs indépendants.',
                ar: 'راجع طلبات السائقين المستقلين.')),
        const SizedBox(height: 16),
        const BackendApplicationInbox(),
      ]);
    }
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
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
            en: 'Could not load delivery data. Retry',
            fr: 'Impossible de charger les données. Réessayer',
          )),
        ),
      );
    }
    final activeDrivers = _drivers
        .where((d) => d.status == 'En service' || d.status == 'En livraison')
        .length;
    final applications = _drivers.where((d) => d.hasPendingApplication).toList()
      ..sort((a, b) =>
          b.applicationSubmittedAt!.compareTo(a.applicationSubmittedAt!));

    final filteredDrivers = _drivers.where((d) {
      final matchesQuery =
          d.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              d.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              d.assignedZone.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter = switch (_filter) {
        'En service' => d.status == 'En service',
        'En livraison' => d.status == 'En livraison',
        'Hors service' => d.status == 'Hors service',
        _ => true,
      };

      return matchesQuery && matchesFilter;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        PageHeading(
          title:
              context.tr(en: 'Driver management', fr: 'Gestion des livreurs'),
          subtitle: context.tr(
            en: 'Monitor drivers and assign missions.',
            fr: 'Suivez la flotte de livreurs et attribuez les missions.',
          ),
        ),
        const SizedBox(height: 18),
        if (BackendClient.enabled) const BackendApplicationInbox(),
        if (!BackendClient.enabled)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    const Icon(Icons.person_add_alt_1_outlined,
                        color: AppColors.navy),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                            context.tr(
                                en: 'New driver applications',
                                fr: 'Nouvelles demandes de livreurs',
                                ar: 'طلبات السائقين الجديدة'),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold))),
                    Text('${applications.length}',
                        key: const ValueKey('pending-applications-count')),
                    IconButton(
                      tooltip: context.tr(
                          en: 'Refresh applications',
                          fr: 'Actualiser les demandes',
                          ar: 'تحديث الطلبات'),
                      onPressed: _loadDeliveryData,
                      icon: const Icon(Icons.refresh),
                    ),
                  ]),
                  Text(context.tr(
                      en: 'Submitted profiles awaiting vehicle approval, including resubmissions. Review evidence before assigning missions.',
                      fr: 'Profils transmis en attente de validation du véhicule, y compris les dossiers soumis à nouveau. Examinez les preuves avant d’attribuer des missions.',
                      ar: 'ملفات مرسلة تنتظر موافقة المركبة، بما فيها الطلبات المعاد تقديمها. افحص الأدلة قبل إسناد المهام.')),
                  if (applications.isEmpty)
                    Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(context.tr(
                            en: 'No applications awaiting review.',
                            fr: 'Aucune demande en attente d’examen.',
                            ar: 'لا توجد طلبات تنتظر المراجعة.'))),
                  for (final driver in applications)
                    ListTile(
                      key: ValueKey('application-${driver.id}'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(driver.name),
                      subtitle: Text(
                          '${driver.email}\n${context.localize(driver.vehicleType)} · ${driver.capacityKg ?? "—"} kg\n${driver.assignedZone}\n${MaterialLocalizations.of(context).formatMediumDate(driver.applicationSubmittedAt!.toLocal())}'),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _reviewApplication(driver),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 18),
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
            MetricCard(
              label:
                  context.tr(en: 'Registered drivers', fr: 'Livreurs inscrits'),
              value: '${_drivers.length}',
              icon: Icons.badge_outlined,
            ),
            MetricCard(
              label: context.tr(en: 'Active drivers', fr: 'Actifs en service'),
              value: '$activeDrivers',
              icon: Icons.local_shipping_outlined,
              color: AppColors.cyan,
            ),
            MetricCard(
              label: context.tr(en: 'Active trips', fr: 'Courses en cours'),
              value: '${_orders.where((o) => o.status != 'Livré').length}',
              icon: Icons.directions_bike_rounded,
            ),
            MetricCard(
              label:
                  context.tr(en: 'Delivered missions', fr: 'Missions livrées'),
              value:
                  '${_orders.where((o) => o.status == 'Livré' || o.status == 'Déposé au casier').length}',
              icon: Icons.task_alt_rounded,
              color: AppColors.cyan,
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          onChanged: (val) => setState(() => _searchQuery = val),
          decoration: InputDecoration(
            hintText: context.tr(
              en: 'Search driver or area...',
              fr: 'Rechercher un livreur, zone...',
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
              for (final f in [
                'Tous',
                'En service',
                'En livraison',
                'Hors service'
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: LocalizedText(_driverFilterLabel(context, f)),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: AppColors.cyan.withValues(alpha: 0.18),
                    side: BorderSide(
                      color: _filter == f ? AppColors.cyan : AppColors.line,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final driver in filteredDrivers) _driverCard(driver),
      ],
    );
  }

  Future<void> _reviewApplication(DeliveryDriver driver) async {
    final changed = await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) => CapacityReviewScreen(
            driverId: driver.id,
            driverName: driver.name,
            reviewer: widget.reviewer)));
    if (changed == true && mounted) await _loadDeliveryData();
  }

  Widget _driverCard(DeliveryDriver driver) {
    final statusColor = switch (driver.status) {
      'En service' => AppColors.cyan,
      'En livraison' => AppColors.navy,
      _ => AppColors.muted,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                CircleAvatar(
                  backgroundColor: AppColors.navy,
                  child: LocalizedText(
                    driver.name[0],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.name,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      LocalizedText(
                        '${driver.id} · ${driver.assignedZone}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusPill(
                  _driverStatusLabel(context, driver.status),
                  color: statusColor,
                ),
              ],
            ),
            const Divider(height: 20, color: AppColors.line),
            Row(
              children: [
                Expanded(
                  child: _miniInfo(
                    context.tr(en: 'Vehicle', fr: 'Véhicule'),
                    driver.vehicleType,
                  ),
                ),
                Expanded(
                  child: _miniInfo(
                    context.tr(en: 'Phone', fr: 'Téléphone'),
                    driver.phone,
                  ),
                ),
                Expanded(
                  child: _miniInfo(
                    context.tr(en: 'Rating', fr: 'Note'),
                    '${driver.rating} ⭐',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
                '${context.tr(en: 'Capacity check', fr: 'Contrôle de capacité', ar: 'فحص السعة')}: ${context.localize(driver.capacityAssessment)}'),
            if (driver.capacityAssessment != 'approved')
              Text(context.tr(
                  en: 'Pending vehicle approval: mission assignment is blocked.',
                  fr: 'Validation du véhicule requise : attribution des missions bloquée.',
                  ar: 'موافقة المركبة مطلوبة: إسناد المهام محظور.')),
            TextButton.icon(
              icon: const Icon(Icons.fact_check_outlined),
              label: Text(context.tr(
                  en: 'Review evidence',
                  fr: 'Examiner la preuve',
                  ar: 'فحص الدليل')),
              onPressed: () => _reviewApplication(driver),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: driver.capacityAssessment == 'approved' &&
                            driver.status != 'Hors service'
                        ? () => _assignOrderDialog(driver)
                        : null,
                    icon: const Icon(Icons.assignment_add, size: 18),
                    label: LocalizedText(
                      context.tr(en: 'Assign mission', fr: 'Assigner course'),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navy,
                      side: const BorderSide(color: AppColors.line),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniInfo(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocalizedText(label,
              style: const TextStyle(color: AppColors.muted, fontSize: 10)),
          const SizedBox(height: 2),
          LocalizedText(
            value,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );

  void _assignOrderDialog(DeliveryDriver driver) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: LocalizedText(context.tr(
          en: 'Assign mission to ${driver.name}',
          fr: 'Assigner course à ${driver.name}',
        )),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final order in _orders)
              ListTile(
                title: LocalizedText(
                  '${order.id} · ${context.tr(en: 'Locker', fr: 'Casier')} ${order.lockerId}',
                ),
                subtitle: LocalizedText(
                  '${order.residentName} (${order.type == 'Collecte' ? context.tr(en: 'Collection', fr: 'Collecte') : context.tr(en: 'Delivery', fr: 'Livraison')})',
                ),
                trailing: TextButton(
                  onPressed: () => _assignMission(ctx, order, driver),
                  child:
                      LocalizedText(context.tr(en: 'Assign', fr: 'Assigner')),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: LocalizedText(context.tr(en: 'Close', fr: 'Fermer')),
          ),
        ],
      ),
    );
  }

  Future<void> _assignMission(
    BuildContext dialogContext,
    DeliveryOrder order,
    DeliveryDriver driver,
  ) async {
    try {
      await _repository.assignMission(
        missionId: order.id,
        driverId: driver.id,
      );
      if (!mounted || !dialogContext.mounted) return;
      Navigator.pop(dialogContext);
      await _loadDeliveryData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: LocalizedText(context.tr(
            en: 'Mission ${order.id} assigned to ${driver.name}',
            fr: 'Commande ${order.id} assignée à ${driver.name}',
          )),
        ),
      );
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: LocalizedText(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: LocalizedText(context.tr(
            en: 'Assignment failed.',
            fr: "L'assignation a échoué.",
          )),
        ),
      );
    }
  }

  String _driverFilterLabel(BuildContext context, String filter) {
    return switch (filter) {
      'Tous' => context.tr(en: 'All', fr: 'Tous'),
      'En service' => context.tr(en: 'On duty', fr: 'En service'),
      'En livraison' => context.tr(en: 'Delivering', fr: 'En livraison'),
      'Hors service' => context.tr(en: 'Off duty', fr: 'Hors service'),
      _ => filter,
    };
  }

  String _driverStatusLabel(BuildContext context, String status) {
    return switch (status) {
      'En service' => context.tr(en: 'On duty', fr: 'En service'),
      'En livraison' => context.tr(en: 'Delivering', fr: 'En livraison'),
      'Hors service' => context.tr(en: 'Off duty', fr: 'Hors service'),
      _ => status,
    };
  }
}
