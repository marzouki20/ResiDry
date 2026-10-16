// Test fixtures only: these accounts are never seeded by the application.
import 'package:ttttttteee/models/user.dart';

const testResident = User(
  id: 1,
  name: 'Ahmed',
  email: 'resident@test.invalid',
  password: 'test-only',
  role: 'Résident',
);
const testOtherResident = User(
  id: 2,
  name: 'Sara',
  email: 'other@test.invalid',
  password: 'test-only',
  role: 'Résident',
);
const testPressing = User(
  id: 7,
  name: 'Pressing',
  email: 'pressing@test.invalid',
  password: 'test-only',
  role: 'Société de lavage',
);
const testDriver = User(
  id: 8,
  name: 'Livreur',
  email: 'driver@test.invalid',
  password: 'test-only',
  role: 'Livreur',
);
const testAdmin = User(
  id: 9,
  name: 'Admin',
  email: 'admin@test.invalid',
  password: 'test-only',
  role: 'Administrateur',
);
const testUnknown = User(
  id: 99,
  name: 'Inconnu',
  email: 'unknown@test.invalid',
  password: 'test-only',
  role: 'unknown',
);
const testAccounts = [
  testResident,
  testOtherResident,
  testPressing,
  testDriver,
  testAdmin,
  testUnknown,
];
