import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../database/database.dart';
import '../../mock/residents_mock_data.dart';

class ResidentManagementPage extends StatefulWidget {
  const ResidentManagementPage({super.key});

  @override
  State<ResidentManagementPage> createState() => _ResidentManagementPageState();
}

class _ResidentManagementPageState extends State<ResidentManagementPage> {
  final _searchController = TextEditingController();
  List<ResidentProfile> _residents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _residents = [demoResidentProfile, secondDemoResidentProfile];
    _loading = false;
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadResidents() async {
    final residents = await AppDatabase.instance.listResidents();
    if (!mounted) return;
    setState(() {
      _residents = residents;
      _loading = false;
    });
  }

  List<ResidentProfile> get _filteredResidents {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _residents;
    return _residents.where((resident) {
      return resident.fullName.toLowerCase().contains(query) ||
          resident.email.toLowerCase().contains(query) ||
          resident.apartmentNumber.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final residents = _filteredResidents;
    return RefreshIndicator(
      onRefresh: _loadResidents,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const Text(
            'Gestion des résidents',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ajoutez, modifiez et gérez les résidents de la résidence.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher un résident...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: _searchController.clear,
                      icon: const Icon(Icons.clear_rounded),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => _editResident(),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Ajouter un résident'),
          ),
          const SizedBox(height: 18),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (residents.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: Text('Aucun résident trouvé.')),
            )
          else
            ...residents.map(_residentCard),
        ],
      ),
    );
  }

  Widget _residentCard(ResidentProfile resident) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: AppColors.navy,
          child: Text(
            resident.initials,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          resident.fullName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${resident.email}\nAppartement ${resident.apartmentNumber}',
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') _editResident(resident);
            if (value == 'delete') _deleteResident(resident);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Modifier')),
            PopupMenuItem(value: 'delete', child: Text('Supprimer')),
          ],
        ),
      ),
    );
  }

  Future<void> _editResident([ResidentProfile? resident]) async {
    final result = await showDialog<ResidentProfile>(
      context: context,
      builder: (_) => _ResidentFormDialog(resident: resident),
    );
    if (result == null) return;

    if (resident == null) {
      await AppDatabase.instance.createResident(result);
    } else {
      await AppDatabase.instance.updateResident(result);
    }
    await _loadResidents();
  }

  Future<void> _deleteResident(ResidentProfile resident) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le résident ?'),
        content: Text('Supprimer ${resident.fullName} définitivement ?'),
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
    if (confirmed == true && resident.id != null) {
      await AppDatabase.instance.deleteResident(resident.id!);
      await _loadResidents();
    }
  }
}

class _ResidentFormDialog extends StatefulWidget {
  const _ResidentFormDialog({this.resident});

  final ResidentProfile? resident;

  @override
  State<_ResidentFormDialog> createState() => _ResidentFormDialogState();
}

class _ResidentFormDialogState extends State<_ResidentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _apartment;

  @override
  void initState() {
    super.initState();
    final resident = widget.resident;
    _firstName = TextEditingController(text: resident?.firstName);
    _lastName = TextEditingController(text: resident?.lastName);
    _email = TextEditingController(text: resident?.email);
    _phone = TextEditingController(text: resident?.phone);
    _apartment = TextEditingController(text: resident?.apartmentNumber);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _apartment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.resident == null ? 'Nouveau résident' : 'Modifier le résident',
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(_firstName, 'Prénom'),
                _field(_lastName, 'Nom'),
                _field(
                  _email,
                  'Email',
                  keyboardType: TextInputType.emailAddress,
                ),
                _field(_phone, 'Téléphone', keyboardType: TextInputType.phone),
                _field(_apartment, 'Appartement'),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            final old = widget.resident;
            Navigator.pop(
              context,
              (old ?? demoResidentProfile).copyWith(
                firstName: _firstName.text.trim(),
                lastName: _lastName.text.trim(),
                email: _email.text.trim().toLowerCase(),
                phone: _phone.text.trim(),
                apartmentNumber: _apartment.text.trim(),
              ),
            );
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Champ obligatoire' : null,
      ),
    );
  }
}
