import 'presentation/driver_laundry_page.dart';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'data/models/laundry_role.dart';
import 'data/repositories/laundry_repository.dart';
import 'presentation/laundry_page.dart';
import 'presentation/pressing_laundry_page.dart';
import 'presentation/resident_laundry_page.dart';

// Entry point used only to test the laundry module.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LaundryDevApp());
}

class LaundryDevApp extends StatefulWidget {
  const LaundryDevApp({super.key, this.repository});
  final LaundryRepository? repository;

  @override
  State<LaundryDevApp> createState() => _LaundryDevAppState();
}

class _LaundryDevAppState extends State<LaundryDevApp> {
  // The currently selected test role.
  LaundryRole selectedRole = LaundryRole.admin;

  // All test screens share the same SQLite repository (one device).
  late final LaundryRepository _repository =
      widget.repository ?? LaundryRepository();

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
              // Select which user's interface to test.
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

              // Display the interface corresponding to the role.
              Expanded(
                child: selectedRole == LaundryRole.resident
                    ? ResidentLaundryPage(
                        embedded: true,
                        residentId: 1,
                        residentName: 'Ahmed',
                        repository: _repository,
                      )
                    : selectedRole == LaundryRole.pressing
                    ? PressingLaundryPage(repository: _repository)
                    : selectedRole == LaundryRole.driver
                    ? DriverLaundryPage(repository: _repository)
                    : LaundryPage(
                        key: ValueKey(selectedRole),
                        repository: _repository,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
