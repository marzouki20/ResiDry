import 'package:flutter_test/flutter_test.dart';
import 'package:ttttttteee/database/database.dart';
import 'package:ttttttteee/features/residents/mock/residents_mock_data.dart';

void main() {
  test('resident CRUD persists locally in the database', () async {
    final database = AppDatabase.instance;

    final createdId = await database.createResident(
      const ResidentProfile(
        firstName: 'Test',
        lastName: 'Resident',
        email: 'test.resident@example.com',
        phone: '+216 11 222 333',
        residenceName: 'Test Residence',
        residenceAddress: '12 Avenue Test',
        city: 'Sousse',
        postalCode: '4000',
        apartmentNumber: 'B-12',
        floor: '3',
        status: 'Active',
      ),
    );

    expect(createdId, isNonZero);

    final residents = await database.listResidents();
    expect(residents, isNotEmpty);
    expect(
      residents.any(
        (resident) => resident.email == 'test.resident@example.com',
      ),
      isTrue,
    );

    final updated = residents
        .firstWhere((resident) => resident.email == 'test.resident@example.com')
        .copyWith(firstName: 'Updated');

    final updatedRows = await database.updateResident(updated);
    expect(updatedRows, 1);

    final fetched = await database.getResidentByEmail(
      'test.resident@example.com',
    );
    expect(fetched, isNotNull);
    expect(fetched!.firstName, 'Updated');

    final deletedRows = await database.deleteResident(fetched.id!);
    expect(deletedRows, 1);
  });
}
