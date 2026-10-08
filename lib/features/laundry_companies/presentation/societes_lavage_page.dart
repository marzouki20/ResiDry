import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/sample_laundry_data.dart';
import '../domain/models/societe_lavage.dart';
import 'pages/societe_detail_page.dart';
import 'widgets/societe_card.dart';
import 'widgets/societe_form_dialog.dart';

class SocietesLavagePage extends StatefulWidget {
  const SocietesLavagePage({
    super.key,
    this.userName,
    this.drawer,
  });

  final String? userName;
  final Widget? drawer;

  @override
  State<SocietesLavagePage> createState() => _SocietesLavagePageState();
}

class _SocietesLavagePageState extends State<SocietesLavagePage> {
  late final List<SocieteLavage> _societes = List<SocieteLavage>.of(initialSocietesLavage);
  String _searchQuery = '';
  String _statusFilter = 'Tous';

  void _addOrEditSociete([SocieteLavage? societe]) {
    showDialog<void>(
      context: context,
      builder: (context) => SocieteFormDialog(
        societe: societe,
        onSave: (savedSociete) {
          setState(() {
            final index = _societes.indexWhere((s) => s.id == savedSociete.id);
            if (index != -1) {
              _societes[index] = savedSociete;
            } else {
              _societes.insert(0, savedSociete);
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                societe == null
                    ? 'Société partenaire ajoutée avec succès !'
                    : 'Informations de la société mises à jour !',
              ),
              backgroundColor: AppColors.navy,
            ),
          );
        },
      ),
    );
  }

  void _deleteSociete(SocieteLavage societe) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Supprimer la société'),
          ],
        ),
        content: Text(
          'Voulez-vous vraiment supprimer la société "${societe.nom}" ? Cette action est irréversible.',
        ),
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
              setState(() {
                _societes.removeWhere((s) => s.id == societe.id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Société "${societe.nom}" supprimée.'),
                  action: SnackBarAction(
                    label: 'Annuler',
                    textColor: Colors.amber,
                    onPressed: () {
                      setState(() {
                        _societes.add(societe);
                      });
                    },
                  ),
                ),
              );
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  List<SocieteLavage> get _filteredSocietes {
    return _societes.where((s) {
      final matchesSearch = s.nom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.adresse.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.email.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter =
          _statusFilter == 'Tous' || s.statut == _statusFilter;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  int get _totalMachines {
    return _societes.fold<int>(0, (int sum, SocieteLavage s) => sum + s.machines.length);
  }

  int get _activeCycles {
    return _societes.fold<int>(0, (int sum, SocieteLavage s) => sum + s.runningCyclesCount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.drawer != null
          ? AppBar(
              title: const Text(
                'Sociétés de Lavage',
                style: TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.bold,
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
            )
          : null,
      drawer: widget.drawer,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Heading
            const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sociétés de Lavage Partenaires',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Supervision intelligente des blanchisseries, machines et cycles IoT.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Summary Stats Dashboard
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    'Sociétés',
                    _societes.length.toString(),
                    Icons.store_rounded,
                    AppColors.navy,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    'Machines IoT',
                    _totalMachines.toString(),
                    Icons.precision_manufacturing_rounded,
                    AppColors.cyan,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statCard(
                    'Cycles Actifs',
                    _activeCycles.toString(),
                    Icons.sync_rounded,
                    Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search Bar & Filter Chips
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                children: [
                  // Search input
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Rechercher par nom, adresse, email...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.navy),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.cream.withValues(alpha: 0.5),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Tous', 'Actif', 'Sous Maintenance', 'Inactif'].map((filter) {
                        final isSelected = _statusFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: isSelected,
                            selectedColor: AppColors.navy,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.navy,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            onSelected: (selected) {
                              if (selected) setState(() => _statusFilter = filter);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // List of Societes
            if (_filteredSocietes.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(36),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.search_off_rounded,
                      size: 48,
                      color: AppColors.muted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Aucune société ne correspond à la recherche "$_searchQuery"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._filteredSocietes.map((SocieteLavage societe) {
                return SocieteCard(
                  societe: societe,
                  onViewDetails: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SocieteDetailPage(
                          societe: societe,
                          onSocieteUpdated: (updatedSociete) {
                            setState(() {
                              final idx = _societes.indexWhere((s) => s.id == updatedSociete.id);
                              if (idx != -1) _societes[idx] = updatedSociete;
                            });
                          },
                        ),
                      ),
                    );
                  },
                  onEdit: () => _addOrEditSociete(societe),
                  onDelete: () => _deleteSociete(societe),
                );
              }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditSociete(),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Nouvelle Société'),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
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
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
