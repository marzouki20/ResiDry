import 'package:flutter/material.dart';

import '../../../../models/user.dart';
import '../navigation/laundry_routes.dart';

/// Adds access to Laundry without editing the teammate's company screen.
class LaundryNavigationAccess extends StatelessWidget {
  const LaundryNavigationAccess({
    super.key,
    required this.currentUser,
    required this.child,
  });
  final User currentUser;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      child,
      if (currentUser.role == 'Société de lavage')
        Positioned(
          right: 16,
          bottom: 24 + MediaQuery.paddingOf(context).bottom,
          child: FloatingActionButton(
            heroTag: 'laundry-workflow-entry',
            tooltip: 'Gestion du linge',
            onPressed: () =>
                Navigator.of(context)
                    .push(LaundryRoutes.pressingPage(currentUser: currentUser)),
            child: const Icon(Icons.local_laundry_service_outlined),
          ),
        ),
    ],
  );
}
