import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../mock/residents_mock_data.dart';
import 'pages/edit_profile_page.dart';
import 'pages/laundry_request_details_page.dart';
import 'pages/laundry_requests_page.dart';
import 'pages/locker_assignment_page.dart';
import 'pages/notifications_page.dart';
import 'pages/residence_page.dart';
import 'pages/resident_profile_page.dart';
import 'widgets/quick_action_card.dart';
import 'widgets/request_card.dart';
import 'widgets/resident_header.dart';

class ResidentsHomePage extends StatefulWidget {
  const ResidentsHomePage({super.key, this.userName});

  final String? userName;

  @override
  State<ResidentsHomePage> createState() => _ResidentsHomePageState();
}

class _ResidentsHomePageState extends State<ResidentsHomePage> {
  int _selectedIndex = 0;
  ResidentProfile _resident = demoResidentProfile;
  final List<LaundryRequest> _laundryRequests = List<LaundryRequest>.from(
    demoLaundryRequests,
  );
  List<NotificationItem> _notifications = List<NotificationItem>.from(
    demoNotifications,
  );

  @override
  Widget build(BuildContext context) {
    final titles = <String>[
      'Dashboard',
      'Profile',
      'Residence',
      'Laundry requests',
      'Notifications',
      'Locker assignment',
    ];

    return Scaffold(
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
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: 'Ouvrir le menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu_rounded),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => setState(() => _selectedIndex = 4),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        width: 304,
        backgroundColor: Colors.white,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 18, 18),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.water_drop_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ResiDry',
                            style: TextStyle(
                              color: AppColors.navy,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'RESIDENT PORTAL',
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
                      tooltip: 'Fermer le menu',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.line),
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 20, 16, 10),
                child: Text(
                  'MY SPACE',
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
                    _drawerItem(0, Icons.dashboard_outlined, 'Dashboard'),
                    _drawerItem(1, Icons.person_outline_rounded, 'Profile'),
                    _drawerItem(2, Icons.home_outlined, 'Residence'),
                    _drawerItem(
                      3,
                      Icons.local_laundry_service_outlined,
                      'Laundry requests',
                    ),
                    _drawerItem(
                      4,
                      Icons.notifications_none_rounded,
                      'Notifications',
                    ),
                    _drawerItem(
                      5,
                      Icons.lock_outline_rounded,
                      'Locker assignment',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _dashboardPage(),
          ResidentProfilePage(
            resident: _resident,
            onEditProfile: _openEditProfile,
          ),
          ResidencePage(resident: _resident),
          LaundryRequestsPage(
            requests: _laundryRequests,
            onRequestSelected: _openRequestDetails,
          ),
          NotificationsPage(
            notifications: _notifications,
            onMarkAllAsRead: _markAllAsRead,
          ),
          LockerAssignmentPage(assignment: demoLockerAssignment),
        ],
      ),
    );
  }

  Widget _dashboardPage() {
    final unreadNotifications = _notifications
        .where((item) => !item.isRead)
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour, ${widget.userName ?? _resident.firstName}',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your residence, services, and requests in one place.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.line),
              ),
              child: const Icon(Icons.home_rounded, color: AppColors.cyan),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ResidentHeader(resident: _resident),
        const SizedBox(height: 22),
        const Text(
          'Statistiques utiles',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: [
            _metricCard(
              label: 'Laundry requests',
              value: '${_laundryRequests.length}',
              icon: Icons.local_laundry_service_outlined,
              color: AppColors.cyan,
            ),
            _metricCard(
              label: 'Unread alerts',
              value: '$unreadNotifications',
              icon: Icons.notifications_active_outlined,
              color: AppColors.navy,
            ),
            _metricCard(
              label: 'Residence',
              value: 'ResiDry',
              icon: Icons.location_city_outlined,
              color: const Color(0xFF7B61FF),
            ),
            _metricCard(
              label: 'Status',
              value: _resident.status,
              icon: Icons.verified_outlined,
              color: const Color(0xFF1EAA8B),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Quick actions',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _selectedIndex = 1),
              child: const Text('Manage profile'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.2,
          children: [
            QuickActionCard(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              onTap: () => setState(() => _selectedIndex = 1),
            ),
            QuickActionCard(
              icon: Icons.home_outlined,
              label: 'Residence',
              onTap: () => setState(() => _selectedIndex = 2),
            ),
            QuickActionCard(
              icon: Icons.lock_outline_rounded,
              label: 'Locker',
              onTap: () => setState(() => _selectedIndex = 5),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const Text(
          'Recent laundry requests',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        ..._laundryRequests
            .take(2)
            .map(
              (request) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RequestCard(
                  request: request,
                  onTap: () => _openRequestDetails(request),
                ),
              ),
            ),
        const SizedBox(height: 18),
        const Text(
          'Recent notifications',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        ..._notifications
            .take(2)
            .map(
              (notification) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        notification.icon == 'local_laundry_service'
                            ? Icons.local_laundry_service_outlined
                            : notification.icon == 'person'
                            ? Icons.person_outline_rounded
                            : Icons.door_front_door_outlined,
                        color: AppColors.navy,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.title,
                              style: const TextStyle(
                                color: AppColors.navy,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification.message,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ],
    );
  }

  Widget _metricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: AppColors.cyan.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(
          icon,
          color: isSelected ? AppColors.navy : AppColors.muted,
        ),
        title: Text(label),
        textColor: isSelected ? AppColors.navy : AppColors.muted,
        iconColor: isSelected ? AppColors.navy : AppColors.muted,
        onTap: () {
          setState(() => _selectedIndex = index);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _openEditProfile() async {
    final updatedResident = await Navigator.of(context).push<ResidentProfile>(
      MaterialPageRoute<ResidentProfile>(
        builder: (context) => EditProfilePage(
          resident: _resident,
          onSave: (profile) => setState(() => _resident = profile),
        ),
      ),
    );

    if (updatedResident != null) {
      setState(() => _resident = updatedResident);
    }
  }

  void _openRequestDetails(LaundryRequest request) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => LaundryRequestDetailsPage(request: request),
      ),
    );
  }

  void _markAllAsRead() {
    setState(() {
      for (final notification in _notifications) {
        if (!notification.isRead) {
          // UI-only update; mutation is intentionally local and in-memory.
        }
      }
      _notifications = _notifications
          .map(
            (notification) => NotificationItem(
              icon: notification.icon,
              title: notification.title,
              message: notification.message,
              dateTime: notification.dateTime,
              isRead: true,
            ),
          )
          .toList();
    });
  }
}
