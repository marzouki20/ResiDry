import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class LockerRecord {
  LockerRecord({
    required this.id,
    required this.resident,
    required this.apartment,
    this.maxWeight = 8,
    this.lockerType = 'Standard',
    this.climateMonitoring = true,
    this.rfidEnabled = true,
    this.electronicLock = true,
    this.weight = 5.2,
    this.temperature = 24,
    this.humidity = 48,
    this.doorOpen = false,
    this.locked = true,
    this.connected = true,
    this.status = 'Normal',
  });

  String id;
  String resident;
  String apartment;
  double maxWeight;
  String lockerType;
  bool climateMonitoring;
  bool rfidEnabled;
  bool electronicLock;
  double weight;
  int temperature;
  int humidity;
  bool doorOpen;
  bool locked;
  bool connected;
  String status;
}

final demoLockers = <LockerRecord>[
  LockerRecord(id: 'C-024', resident: 'Mohamed Khalil', apartment: 'A-204'),
  LockerRecord(
    id: 'C-017',
    resident: 'Sara Benali',
    apartment: 'B-105',
    weight: 2.8,
    temperature: 23,
    humidity: 46,
    connected: false,
    status: 'Hors ligne',
  ),
  LockerRecord(
    id: 'C-031',
    resident: 'Yassine Amrani',
    apartment: 'A-310',
    weight: 6.4,
    temperature: 25,
    humidity: 71,
    status: 'Anomalie',
  ),
  LockerRecord(
    id: 'C-009',
    resident: 'Non attribué',
    apartment: 'C-102',
    weight: 0,
    status: 'Disponible',
  ),
  LockerRecord(
    id: 'C-012',
    resident: 'Lina Haddad',
    apartment: 'C-206',
    weight: 3.1,
    status: 'Maintenance',
  ),
];

class PageHeading extends StatelessWidget {
  const PageHeading({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 25,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ],
        ),
      ),
      ?trailing,
    ],
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, this.color = AppColors.cyan});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.navy,
    this.caption,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? caption;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 21),
        const SizedBox(height: 13),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        if (caption != null) ...[
          const SizedBox(height: 6),
          Text(caption!, style: TextStyle(color: color, fontSize: 10)),
        ],
      ],
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
    ],
  );
}

class DetailTile extends StatelessWidget {
  const DetailTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.navy,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.line),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class TrendCard extends StatelessWidget {
  const TrendCard({super.key, required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 48,
          width: double.infinity,
          child: CustomPaint(painter: _TrendPainter()),
        ),
      ],
    ),
  );
}

class _TrendPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const values = [0.72, 0.52, 0.63, 0.37, 0.49, 0.24, 0.33];
    final points = [
      for (var i = 0; i < values.length; i++)
        Offset(size.width * i / (values.length - 1), size.height * values[i]),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.cyan
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Color lockerStatusColor(String status) => switch (status) {
  'Anomalie' => const Color(0xFFE77B32),
  'Maintenance' => const Color(0xFF7457E8),
  'Hors ligne' => const Color(0xFFE45858),
  'Disponible' => AppColors.cyan,
  _ => AppColors.navy,
};
