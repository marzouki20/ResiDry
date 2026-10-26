import 'package:flutter/material.dart';

class LaundryCompanyHomePage extends StatelessWidget {
  const LaundryCompanyHomePage({
    super.key,
    this.userName,
    this.userRole,
    this.onLogout,
  });

  final String? userName;
  final String? userRole;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ResiDry'),
        centerTitle: false,
        actions: [
          if (onLogout != null)
            IconButton(
              tooltip: 'Sign out',
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              userName == null ? 'Welcome' : 'Welcome, $userName',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              userRole == null
                  ? 'Manage your laundry services here.'
                  : '$userRole account · Manage your laundry services here.',
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.local_laundry_service_outlined,
                      size: 32,
                      color: colors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Laundry services',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your laundry service information will appear here.',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
