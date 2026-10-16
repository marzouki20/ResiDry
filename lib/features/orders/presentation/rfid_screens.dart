library residry.orders.presentation.rfid_screens;

import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui/animations.dart';
import '../../../database/database.dart';
import '../data/sqlite_order_repository.dart';
import '../domain/services/rfid_workflow_engine.dart';
import 'order_pages.dart';

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});

  final RfidReaderRole role;

  @override
  Widget build(BuildContext context) {
    final color = _roleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        _roleLabel(role),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Color _roleColor(RfidReaderRole r) => switch (r) {
        RfidReaderRole.admin => AppColors.navy,
        RfidReaderRole.delivery => AppColors.cyan,
        RfidReaderRole.laundry => AppColors.purple,
        RfidReaderRole.casier => const Color(0xFF7C3AED),
        RfidReaderRole.resident => AppColors.coral,
      };

  String _roleLabel(RfidReaderRole r) => switch (r) {
        RfidReaderRole.admin => 'Administrateur',
        RfidReaderRole.delivery => 'Livreur',
        RfidReaderRole.laundry => 'Blanchisserie',
        RfidReaderRole.casier => 'Casiers',
        RfidReaderRole.resident => 'Résident',
      };
}

class RfidHubScreen extends StatelessWidget {
  const RfidHubScreen({super.key, required this.role, required this.userName});

  final RfidReaderRole role;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return switch (role) {
      RfidReaderRole.admin => RfidAdminDashboard(userName: userName),
      RfidReaderRole.delivery => RfidDeliveryScreen(userName: userName),
      RfidReaderRole.laundry => RfidLaundryScreen(userName: userName),
      RfidReaderRole.casier => RfidCasierScreen(userName: userName),
      RfidReaderRole.resident => RfidResidentScreen(userName: userName),
    };
  }

  static void navigateTo(BuildContext context, Widget page) {
    Navigator.of(context).push(
      PageTransition(
        type: PageTransitionType.fade,
        duration: const Duration(milliseconds: 400),
        child: page,
      ),
    );
  }
}

class RfidAdminDashboard extends StatelessWidget {
  const RfidAdminDashboard({super.key, required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord RFID'),
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, Object?>>>(
        future: AppDatabase.instance.getAllCommandes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: ScanningLoader(label: 'Chargement…'));
          }
          final commandes = snapshot.data ?? [];
          final byStatus = <String, int>{};
          for (final c in commandes) {
            final s = c['statut'] as String;
            byStatus[s] = (byStatus[s] ?? 0) + 1;
          }
          return StaggeredListBuilder(
            itemCount: 4 + byStatus.length,
            itemBuilder: (context, index) {
              if (index == 0) {
                return AnimatedCard(
                  delay: 100,
                  child: _RoleChip(role: RfidReaderRole.admin),
                );
              }
              if (index == 1) {
                return AnimatedCard(
                  delay: 200,
                  child: Text(
                    'Bonjour, $userName',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                );
              }
              if (index == 2) {
                return AnimatedSectionHeader(
                  title: 'Répartition des commandes',
                  action: 'Toutes',
                  onAction: () {},
                  delay: 300,
                );
              }
              final statusIndex = index - 3;
              final entries = byStatus.entries.toList(growable: false);
              if (statusIndex < entries.length) {
                final e = entries[statusIndex];
                return AnimatedCard(
                  delay: 400 + (statusIndex * 80),
                  child: OrderInfoTile(
                    label: e.key,
                    value: '${e.value} commande(s)',
                    icon: Icons.local_shipping,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          );
        },
      ),
      floatingActionButton: AnimatedFab(
        onPressed: () => RfidHubScreen.navigateTo(
          context,
          RfidScanScreen(role: RfidReaderRole.admin, userName: userName),
        ),
        child: const Icon(Icons.radio_button_checked, color: Colors.white),
      ),
    );
  }
}

class RfidScanScreen extends StatefulWidget {
  const RfidScanScreen({
    super.key,
    required this.role,
    required this.userName,
  });

  final RfidReaderRole role;
  final String userName;

  @override
  State<RfidScanScreen> createState() => _RfidScanScreenState();
}

class _RfidScanScreenState extends State<RfidScanScreen> {
  final _tagController = TextEditingController();
  final _engine = const RfidWorkflowEngine();
  final _repository = SqliteOrderRepository();
  String? _result;
  bool _success = false;
  List<String> _alerts = [];
  bool _scanning = false;

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final tagId = _tagController.text.trim();
    if (tagId.isEmpty) return;
    setState(() {
      _scanning = true;
      _result = null;
    });

    try {
      final result = await _engine.processRfidScan(
        tagId: tagId,
        lecteurId: '${widget.userName}_mobile',
        role: widget.role,
        localisation: 'Mobile',
        latitude: null,
        longitude: null,
        eventType: RfidEventType.scanIn,
        repository: _repository,
        timestamp: DateTime.now(),
      );
      setState(() {
        _success = result.success;
        _result = result.message;
        _alerts = result.alerts;
      });
    } finally {
      setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan RFID'),
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StaggeredListBuilder(
        itemCount: 6 + _alerts.length,
        itemBuilder: (context, index) {
          if (index == 0) {
            return AnimatedCard(
              delay: 50,
              child: _RoleChip(role: widget.role),
            );
          }
          if (index == 1) {
            return AnimatedCard(
              delay: 150,
              child: Text(
                'Scanner un tag RFID',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            );
          }
          if (index == 2) {
            return AnimatedCard(
              delay: 250,
              child: Text(
                'Rôle : ${_roleLabel(widget.role)}',
                style: const TextStyle(color: AppColors.muted, fontSize: 16),
              ),
            );
          }
          if (index == 3) {
            return AnimatedCard(
              delay: 350,
              child: TextField(
                controller: _tagController,
                decoration: InputDecoration(
                  labelText: 'ID du tag RFID',
                  hintText: 'Ex: RFID-00123',
                  prefixIcon: const Icon(Icons.radio_button_checked),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.navy, width: 2),
                  ),
                ),
                onSubmitted: (_) => _scan(),
              ),
            );
          }
          if (index == 4) {
            return AnimatedCard(
              delay: 450,
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _scanning ? null : _scan,
                  icon: _scanning
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : const Icon(Icons.send, size: 24),
                  label: Text(
                    _scanning ? 'Scan en cours…' : 'Valider le scan',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            );
          }
          if (_result != null && index == 5) {
            return AnimatedCard(
              delay: 550,
              child: ScanResultCard(
                success: _success,
                message: _result!,
                alerts: _alerts,
              ),
            );
          }
          if (_alerts.isNotEmpty && _result == null && index == 5) {
            return AnimatedCard(
              delay: 550,
              child: OrderSectionTitle('Alertes', action: null),
            );
          }
          if (_alerts.isNotEmpty) {
            final alertIndex = _result != null ? index - 6 : index - 6;
            if (alertIndex >= 0 && alertIndex < _alerts.length) {
              return AnimatedCard(
                delay: 550 + (alertIndex * 80),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.coral.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.coral.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: AppColors.coral, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _alerts[alertIndex],
                          style: const TextStyle(
                            color: AppColors.coral,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  String _roleLabel(RfidReaderRole r) => switch (r) {
        RfidReaderRole.admin => 'Administrateur',
        RfidReaderRole.delivery => 'Livreur',
        RfidReaderRole.laundry => 'Blanchisserie',
        RfidReaderRole.casier => 'Casiers',
        RfidReaderRole.resident => 'Résident',
      };
}

class RfidDeliveryScreen extends StatelessWidget {
  const RfidDeliveryScreen({super.key, required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return RfidScanScreen(role: RfidReaderRole.delivery, userName: userName);
  }
}

class RfidLaundryScreen extends StatelessWidget {
  const RfidLaundryScreen({super.key, required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return RfidScanScreen(role: RfidReaderRole.laundry, userName: userName);
  }
}

class RfidCasierScreen extends StatelessWidget {
  const RfidCasierScreen({super.key, required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return RfidScanScreen(role: RfidReaderRole.casier, userName: userName);
  }
}

class RfidResidentScreen extends StatelessWidget {
  const RfidResidentScreen({super.key, required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return RfidScanScreen(role: RfidReaderRole.resident, userName: userName);
  }
}

class RfidAlertsScreen extends StatefulWidget {
  const RfidAlertsScreen({super.key});

  @override
  State<RfidAlertsScreen> createState() => _RfidAlertsScreenState();
}

class _RfidAlertsScreenState extends State<RfidAlertsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertes commandes'),
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, Object?>>>(
        future: AppDatabase.instance.getUnreadAlerts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: ScanningLoader(label: 'Chargement…'));
          }
          final alerts = snapshot.data ?? [];
          if (alerts.isEmpty) {
            return EmptyStateIllustration(
              icon: Icons.check_circle,
              title: 'Aucune alerte',
              subtitle: 'Toutes les commandes sont à jour.',
            );
          }
          return StaggeredListBuilder(
            itemCount: alerts.length,
            itemBuilder: (context, i) {
              final a = alerts[i];
              final severity = a['gravite'] as String;
              final severityColor = switch (severity) {
                'Élevée' => AppColors.coral,
                'Moyenne' => const Color(0xFFF59E0B),
                _ => AppColors.navy,
              };
              return AnimatedCard(
                delay: i * 60,
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: severityColor.withValues(alpha: 0.3)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      a['titre'] as String,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          a['description'] as String,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: severityColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Gravité : $severity',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: severityColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: PulseDot(color: severityColor),
                    onTap: () async {
                      await AppDatabase.instance.markAlertRead(a['id'] as int);
                      if (mounted) setState(() {});
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class RfidGpsMapScreen extends StatefulWidget {
  const RfidGpsMapScreen({super.key});

  @override
  State<RfidGpsMapScreen> createState() => _RfidGpsMapScreenState();
}

class _RfidGpsMapScreenState extends State<RfidGpsMapScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte GPS des commandes'),
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, Object?>>>(
        future: AppDatabase.instance.getGpsReadEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: ScanningLoader(label: 'Localisation…'));
          }
          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return EmptyStateIllustration(
              icon: Icons.map,
              title: 'Aucune donnée GPS',
              subtitle: 'Aucun scan avec géolocalisation pour le moment.',
            );
          }
          return StaggeredListBuilder(
            itemCount: events.length,
            itemBuilder: (context, i) {
              final e = events[i];
              final lat = e['latitude'];
              final lng = e['longitude'];
              return AnimatedCard(
                delay: i * 60,
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on, color: AppColors.cyan, size: 28),
                    ),
                    title: Text(
                      e['nom_resident'] as String? ?? 'Inconnu',
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          'Commande : ${e['commande_id'] ?? '-'}',
                          style: const TextStyle(fontSize: 13, color: AppColors.muted),
                        ),
                        Text(
                          'Statut : ${e['commande_statut'] ?? '-'}',
                          style: const TextStyle(fontSize: 13, color: AppColors.muted),
                        ),
                        Text(
                          'Lieu : ${e['localisation']}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          'GPS: $lat, $lng',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppColors.cyan,
                          ),
                        ),
                        Text(
                          'Le ${e['lu_le']}',
                          style: const TextStyle(fontSize: 11, color: AppColors.muted),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.map, color: AppColors.cyan, size: 24),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class RfidTagManagementScreen extends StatefulWidget {
  const RfidTagManagementScreen({
    super.key,
    required this.commandeId,
  });

  final String commandeId;

  @override
  State<RfidTagManagementScreen> createState() => _RfidTagManagementScreenState();
}

class _RfidTagManagementScreenState extends State<RfidTagManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des tags RFID'),
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, Object?>>>(
        future: AppDatabase.instance.getRfidTagsByCommande(widget.commandeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: ScanningLoader(label: 'Chargement…'));
          }
          final tags = snapshot.data ?? [];
          if (tags.isEmpty) {
            return EmptyStateIllustration(
              icon: Icons.radio_button_checked,
              title: 'Aucun tag RFID',
              subtitle: 'Aucun tag associé à cette commande.',
            );
          }
          return StaggeredListBuilder(
            itemCount: tags.length,
            itemBuilder: (context, i) {
              final t = tags[i];
              final isActive = (t['actif'] as int) == 1;
              return AnimatedCard(
                delay: i * 60,
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      t['tag_id'] as String,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      t['garment_id'] != null
                          ? 'Vêtement : ${t['garment_id']}'
                          : 'Non assigné',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                    trailing: Switch(
                      value: isActive,
                      onChanged: (_) {},
                      activeThumbColor: AppColors.navy,
                      activeTrackColor: AppColors.navy.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
