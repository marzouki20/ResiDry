
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'data/models/laundry_role.dart';
import 'data/repositories/laundry_repository.dart';
import 'presentation/laundry_page.dart';
import 'presentation/resident_laundry_page.dart';

// Starts the laundry module for testing.
// This does not replace the team's main.dart.
void main() {
  runApp(const LaundryDevApp());
}

class LaundryDevApp extends StatefulWidget {
  const LaundryDevApp({super.key});

  @override
  State<LaundryDevApp> createState() => _LaundryDevAppState();
}

class _LaundryDevAppState extends State<LaundryDevApp> {

  // The role selected in the test application.
  LaundryRole selectedRole = LaundryRole.admin;

  // Repository used by the resident CRUD.
  final LaundryRepository _repository = LaundryRepository();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ResiDry - Gestion du linge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,

      home: Scaffold(
        body: SafeArea(
          child: Column(
            children: [

              // Dropdown used to test the four roles.
              Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<LaundryRole>(
                  key: ValueKey(selectedRole),
                  initialValue: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Choisir un utilisateur',
                    border: OutlineInputBorder(),
                  ),

                  items: LaundryRole.values.map((role) {
                    return DropdownMenuItem<LaundryRole>(
                      value: role,
                      child: Text(role.label),
                    );
                  }).toList(),

                  onChanged: (role) {
                    if (role != null) {
                      setState(() {
                        selectedRole = role;
                      });
                    }
                  },
                ),
              ),

              // Displays a different interface depending on the role.
              Expanded(
                child: selectedRole == LaundryRole.resident

                // RESIDENT: Their own laundry requests.
                    ? ResidentLaundryPage(
                  residentId: 1,
                  residentName: 'Ahmed',
                  repository: _repository,
                )

                // OTHER ROLES: Existing laundry interface.
                    : LaundryPage(
                  key: ValueKey(selectedRole),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
