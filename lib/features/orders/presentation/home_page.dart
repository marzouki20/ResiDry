import 'package:flutter/material.dart';
import '../../../core/navigation/app_back_button.dart';
import '../../auth/presentation/widgets/sign_out_button.dart';

import '../../../core/localization/localized_text.dart';

class OrdersHomePage extends StatelessWidget {
  const OrdersHomePage({super.key, this.userName});

  final String? userName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
          leading: AppBackButton(onPressed: () => confirmSignOut(context)),
          title: const LocalizedText('ResiDry'),
          centerTitle: false),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            LocalizedText(
              userName == null ? 'Delivery home' : 'Welcome, $userName',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LocalizedText(
              'Manage your delivery orders here.',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
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
                      Icons.local_shipping_outlined,
                      size: 32,
                      color: colors.primary,
                    ),
                    const SizedBox(height: 16),
                    LocalizedText(
                      'Your orders',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    LocalizedText(
                      'Your assigned delivery orders will appear here.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
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
