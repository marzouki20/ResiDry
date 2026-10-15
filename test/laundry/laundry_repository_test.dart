// Relative imports are required by this module's project instructions.
// ignore_for_file: avoid_relative_lib_imports

import 'package:flutter_test/flutter_test.dart';

import '../../lib/features/laundry/data/models/laundry_item.dart';
import '../../lib/features/laundry/data/models/laundry_role.dart';
import '../../lib/features/laundry/data/repositories/laundry_repository.dart';
import 'support/memory_database.dart';

LaundryItem request({
  String id = 'LD1',
  int? residentId = 1,
  LaundryStatus status = LaundryStatus.deposited,
  double price = 15,
}) => LaundryItem(
  id: id,
  residentId: residentId,
  residentName: 'Ahmed',
  serviceType: 'Lavage',
  status: status,
  price: price,
);

void main() {
  late MemoryDatabase db;
  late LaundryRepository repository;
  setUp(() {
    db = MemoryDatabase();
    repository = LaundryRepository(databaseProvider: () async => db);
  });

  test('mapping preserves nullable resident, price and UTC creation date', () {
    final item = request(residentId: null);
    final restored = LaundryItem.fromMap(item.toMap()..['price'] = 15);
    expect(restored.residentId, isNull);
    expect(restored.price, 15.0);
    expect(restored.createdAt, item.createdAt);
    expect(
      restored.copyWith(serviceType: 'Repassage').createdAt,
      item.createdAt,
    );
  });

  test('empty repository has no automatic demo data', () async {
    expect(await repository.getAll(), isEmpty);
  });

  test('resident CRUD persists through another repository instance', () async {
    final item = request();
    await repository.addForResident(item, residentId: 1);
    final another = LaundryRepository(databaseProvider: () async => db);
    expect((await another.getById(item.id))!.price, 0);
    await repository.updateForResident(
      item.copyWith(serviceType: 'Repassage', price: 10),
      residentId: 1,
    );
    expect((await another.getById(item.id))!.serviceType, 'Repassage');
    await repository.deleteForResident(item.id, residentId: 1);
    expect(await another.getAll(), isEmpty);
  });

  test('resident list excludes other residents and null IDs', () async {
    await repository.add(request());
    await repository.add(request(id: 'LD2', residentId: 2));
    await repository.add(request(id: 'LD3', residentId: null));
    expect((await repository.getByResidentId(1)).map((item) => item.id), [
      'LD1',
    ]);
  });

  test('resident read does not disclose the administrator quote', () async {
    await repository.add(request(price: 75).copyWith(priceConfirmed: true));
    final residentView = (await repository.getByResidentId(1)).single;
    expect(residentView.price, 0);
    expect(residentView.priceConfirmed, isFalse);
    final administratorView = (await repository.getById('LD1'))!;
    expect(administratorView.price, 75);
    expect(administratorView.priceConfirmed, isTrue);
  });

  test(
    'resident cannot create a request for someone else or beyond deposited',
    () async {
      expect(
        () => repository.addForResident(request(residentId: 2), residentId: 1),
        throwsA(isA<LaundryException>()),
      );
      expect(
        () => repository.addForResident(
          request(status: LaundryStatus.ready),
          residentId: 1,
        ),
        throwsA(isA<LaundryException>()),
      );
      expect(await repository.getAll(), isEmpty);
    },
  );

  test(
    'resident cannot edit/delete/read history of another resident',
    () async {
      final item = request(residentId: 2);
      await repository.add(item);
      await expectLater(
        repository.updateForResident(item, residentId: 1),
        throwsA(isA<LaundryException>()),
      );
      await expectLater(
        repository.deleteForResident(item.id, residentId: 1),
        throwsA(isA<LaundryException>()),
      );
      await expectLater(
        repository.getStatusHistory(item.id, residentId: 1),
        throwsA(isA<LaundryException>()),
      );
      expect(await repository.getById(item.id), isNotNull);
    },
  );

  test('resident edit cannot overwrite identity, status or price', () async {
    final item = request().copyWith(priceConfirmed: true);
    await repository.add(item);
    await repository.updateForResident(
      item.copyWith(
        residentName: 'Other',
        residentId: 9,
        status: LaundryStatus.delivered,
        price: 20,
      ),
      residentId: 1,
    );
    final saved = (await repository.getById(item.id))!;
    expect(saved.residentId, 1);
    expect(saved.residentName, 'Ahmed');
    expect(saved.status, LaundryStatus.deposited);
    expect(saved.price, 15);
    expect(saved.priceConfirmed, isTrue);
  });

  test(
    'resident creation ignores supplied price and quote confirmation',
    () async {
      await repository.addForResident(
        request(price: 999).copyWith(priceConfirmed: true),
        residentId: 1,
      );
      final saved = (await repository.getById('LD1'))!;
      expect(saved.price, 0);
      expect(saved.priceConfirmed, isFalse);
    },
  );

  test(
    'service change invalidates quote without overwriting administrator amount',
    () async {
      final quoted = request(price: 25).copyWith(priceConfirmed: true);
      await repository.add(quoted);
      await repository.updateForResident(
        quoted.copyWith(serviceType: 'Repassage', price: 999),
        residentId: 1,
      );
      final saved = (await repository.getById('LD1'))!;
      expect(saved.serviceType, 'Repassage');
      expect(saved.price, 25);
      expect(saved.priceConfirmed, isFalse);
      expect((await repository.getStatusHistory('LD1')).length, 1);
    },
  );

  test('resident cannot confirm an unpriced request through an edit', () async {
    await repository.addForResident(request(), residentId: 1);
    final saved = (await repository.getById('LD1'))!;
    await repository.updateForResident(
      saved.copyWith(price: 50, priceConfirmed: true),
      residentId: 1,
    );
    final updated = (await repository.getById('LD1'))!;
    expect(updated.price, 0);
    expect(updated.priceConfirmed, isFalse);
  });

  test(
    'confirmed free service is distinguishable from unpriced request',
    () async {
      await repository.add(
        request(id: 'FREE', price: 0).copyWith(priceConfirmed: true),
      );
      await repository.addForResident(request(id: 'PENDING'), residentId: 1);
      expect((await repository.getById('FREE'))!.priceConfirmed, isTrue);
      expect((await repository.getById('PENDING'))!.priceConfirmed, isFalse);
      final restored = LaundryItem.fromMap(
        (await repository.getById('FREE'))!.toMap(),
      );
      expect(restored.price, 0);
      expect(restored.priceConfirmed, isTrue);
    },
  );

  test('stale resident edit/delete is blocked after pressing starts', () async {
    final stale = request();
    await repository.add(stale);
    await repository.transitionStatus(
      stale.id,
      expectedStatus: LaundryStatus.deposited,
      newStatus: LaundryStatus.processing,
      role: LaundryRole.pressing,
    );
    await expectLater(
      repository.updateForResident(stale, residentId: 1),
      throwsA(isA<LaundryException>()),
    );
    await expectLater(
      repository.deleteForResident(stale.id, residentId: 1),
      throwsA(isA<LaundryException>()),
    );
  });

  test(
    'pressing and driver complete workflow with attributed history',
    () async {
      await repository.addForResident(request(), residentId: 1);
      await repository.transitionStatus(
        'LD1',
        expectedStatus: LaundryStatus.deposited,
        newStatus: LaundryStatus.processing,
        role: LaundryRole.pressing,
        changedByUserId: 7,
      );
      await repository.transitionStatus(
        'LD1',
        expectedStatus: LaundryStatus.processing,
        newStatus: LaundryStatus.ready,
        role: LaundryRole.pressing,
        changedByUserId: 7,
      );
      await repository.transitionStatus(
        'LD1',
        expectedStatus: LaundryStatus.ready,
        newStatus: LaundryStatus.delivered,
        role: LaundryRole.driver,
        changedByUserId: 8,
      );
      expect(
        (await repository.getById('LD1'))!.status,
        LaundryStatus.delivered,
      );
      final history = await repository.getStatusHistory('LD1', residentId: 1);
      expect(history.map((change) => change.newStatus), LaundryStatus.values);
      expect(history.map((change) => change.changedByUserId), [1, 7, 7, 8]);
      expect(history.first.oldStatus, isNull);
      expect(history.last.oldStatus, LaundryStatus.ready);
    },
  );

  test('invalid role, skipping and backward transitions are blocked', () async {
    await repository.add(request());
    for (final role in LaundryRole.values) {
      await expectLater(
        repository.transitionStatus(
          'LD1',
          expectedStatus: LaundryStatus.deposited,
          newStatus: LaundryStatus.delivered,
          role: role,
        ),
        throwsA(isA<LaundryException>()),
      );
    }
    await expectLater(
      repository.transitionStatus(
        'LD1',
        expectedStatus: LaundryStatus.ready,
        newStatus: LaundryStatus.processing,
        role: LaundryRole.pressing,
      ),
      throwsA(isA<LaundryException>()),
    );
    expect((await repository.getStatusHistory('LD1')).length, 1);
  });

  test('stale transition cannot create duplicate history', () async {
    await repository.add(request());
    await repository.transitionStatus(
      'LD1',
      expectedStatus: LaundryStatus.deposited,
      newStatus: LaundryStatus.processing,
      role: LaundryRole.pressing,
    );
    await expectLater(
      repository.transitionStatus(
        'LD1',
        expectedStatus: LaundryStatus.deposited,
        newStatus: LaundryStatus.processing,
        role: LaundryRole.pressing,
      ),
      throwsA(isA<LaundryException>()),
    );
    expect((await repository.getStatusHistory('LD1')).length, 2);
  });

  test(
    'history insertion failure rolls back creation and transition',
    () async {
      db.failHistory = true;
      await expectLater(repository.add(request()), throwsStateError);
      expect(await repository.getAll(), isEmpty);
      db.failHistory = false;
      await repository.add(request());
      db.failHistory = true;
      await expectLater(
        repository.transitionStatus(
          'LD1',
          expectedStatus: LaundryStatus.deposited,
          newStatus: LaundryStatus.processing,
          role: LaundryRole.pressing,
        ),
        throwsStateError,
      );
      expect(
        (await repository.getById('LD1'))!.status,
        LaundryStatus.deposited,
      );
      expect((await repository.getStatusHistory('LD1')).length, 1);
    },
  );

  test(
    'administrator CRUD records status change and preserves creation date',
    () async {
      final item = request(residentId: null);
      await repository.add(item);
      await repository.update(
        item.copyWith(
          residentName: 'Sara',
          price: 25,
          status: LaundryStatus.ready,
        ),
      );
      final saved = (await repository.getById(item.id))!;
      expect(saved.residentName, 'Sara');
      expect(saved.createdAt, item.createdAt);
      expect((await repository.getStatusHistory(item.id)).length, 2);
      await repository.update(saved.copyWith(price: 30));
      expect((await repository.getStatusHistory(item.id)).length, 2);
      await repository.delete(item.id);
      expect(db.rows['laundry_status_history'], isEmpty);
    },
  );

  test('invalid prices and missing requests are rejected', () async {
    for (final price in [-1.0, double.nan, double.infinity]) {
      await expectLater(
        repository.add(request(price: price)),
        throwsA(isA<LaundryException>()),
      );
    }
    await expectLater(
      repository.update(request()),
      throwsA(isA<LaundryException>()),
    );
    await expectLater(
      repository.deleteForResident('missing', residentId: 1),
      throwsA(isA<LaundryException>()),
    );
  });
}
