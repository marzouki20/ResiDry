import 'package:flutter/material.dart';
import '../../../core/localization/app_locale.dart';

class TunisiaGovernorate {
  const TunisiaGovernorate(this.code, this.name, this.arabicName);
  final String code;
  final String name;
  final String arabicName;
  String label(BuildContext context) => context.isArabic ? arabicName : name;
}

const tunisiaGovernorates = <TunisiaGovernorate>[
  TunisiaGovernorate('11', 'Tunis', 'تونس'),
  TunisiaGovernorate('12', 'Ariana', 'أريانة'),
  TunisiaGovernorate('13', 'Ben Arous', 'بن عروس'),
  TunisiaGovernorate('14', 'Manouba', 'منوبة'),
  TunisiaGovernorate('21', 'Nabeul', 'نابل'),
  TunisiaGovernorate('22', 'Zaghouan', 'زغوان'),
  TunisiaGovernorate('23', 'Bizerte', 'بنزرت'),
  TunisiaGovernorate('31', 'Béja', 'باجة'),
  TunisiaGovernorate('32', 'Jendouba', 'جندوبة'),
  TunisiaGovernorate('33', 'Le Kef', 'الكاف'),
  TunisiaGovernorate('34', 'Siliana', 'سليانة'),
  TunisiaGovernorate('41', 'Kairouan', 'القيروان'),
  TunisiaGovernorate('42', 'Kasserine', 'القصرين'),
  TunisiaGovernorate('43', 'Sidi Bouzid', 'سيدي بوزيد'),
  TunisiaGovernorate('51', 'Sousse', 'سوسة'),
  TunisiaGovernorate('52', 'Monastir', 'المنستير'),
  TunisiaGovernorate('53', 'Mahdia', 'المهدية'),
  TunisiaGovernorate('61', 'Sfax', 'صفاقس'),
  TunisiaGovernorate('71', 'Gafsa', 'قفصة'),
  TunisiaGovernorate('72', 'Tozeur', 'توزر'),
  TunisiaGovernorate('73', 'Kébili', 'قبلي'),
  TunisiaGovernorate('81', 'Gabès', 'قابس'),
  TunisiaGovernorate('82', 'Médenine', 'مدنين'),
  TunisiaGovernorate('83', 'Tataouine', 'تطاوين'),
];
