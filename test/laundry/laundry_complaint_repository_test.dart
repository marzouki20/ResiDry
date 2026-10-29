import 'support/laundry_rows.dart';

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ttttttteee/features/laundry/data/models/laundry_details.dart';
import 'package:ttttttteee/features/laundry/data/repositories/laundry_repository.dart';
import 'package:ttttttteee/features/laundry/domain/models/laundry_complaint.dart';
import 'package:ttttttteee/models/laundry_item.dart';

import 'support/complaint_fixtures.dart';
import 'support/sqlite_test_database.dart';
import 'support/test_accounts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Database db;
  late LaundryRepository admin, resident;
  late DateTime now;
  const description = 'Une chemise présente une déchirure constatée au retour.';
  Future<String> create({
    ComplaintReason reason = ComplaintReason.damaged,
    List<ComplaintPhoto> photos = const [],
  }) => resident.createComplaint(
    laundryId: 'R1',
    reason: reason,
    description: description,
    lineId: 'R1-L',
    photos: photos,
  );
  setUp(() async {
    now = DateTime.utc(2026, 10, 28, 12);
    db = await openLaundryTestDatabase();
    admin = LaundryRepository(
      currentUser: testAdmin,
      databaseProvider: () async => db,
      clock: () => now,
    );
    resident = admin.forUser(testResident);
    for (final entry in {'R1': 1, 'R2': 2}.entries) {
      await admin.saveRequest(
        LaundryDetails(
          item: LaundryItem(
            id: entry.key,
            residentId: entry.value,
            residentName: '',
            serviceType: '',
            status: LaundryStatus.deposited,
            price: 0,
          ),
          dueAt: entry.key == 'R1' ? now.add(const Duration(minutes: 5)) : null,
          lines: [
            LaundryLine(
              id: '${entry.key}-L',
              garment: 'Chemise blanche',
              serviceId: 'washing',
              quantity: 3,
            ),
          ],
        ),
      );
    }
  });
  tearDown(() async {
    if (db.isOpen) await db.close();
  });

  test('resident creates a real owned case with persistent photo and actual author', () async {
    final photo = await complaintTestPhoto();
    final before = await db.query('laundry_items');
    final id = await create(photos: [photo]);
    final data = await resident.getComplaintDetails(id);
    expect(data.complaint.residentId, 1);
    expect(data.complaint.status, ComplaintStatus.submitted);
    expect(data.complaint.garmentSnapshot, 'Chemise blanche');
    expect(data.photos.single.bytes, photo.bytes);
    expect(data.events.single.actorId, 1);
    expect(data.names[1], 'Ahmed');
    expect(data.complaint.hasUnreadResponse, isFalse);
    expect(await db.query('laundry_items'), before);
    expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
  });

  test('ownership protects creation photos details inbox and read acknowledgements', () async {
    final id = await create();
    final other = admin.forUser(testOtherResident);
    await expectLater(
      other.getComplaintDetails(id),
      throwsA(isA<LaundryException>()),
    );
    await expectLater(
      other.markComplaintSeen(id, expectedRevision: 1),
      throwsA(isA<LaundryException>()),
    );
    await expectLater(
      other.createComplaint(
        laundryId: 'R1',
        reason: ComplaintReason.damaged,
        description: description,
      ),
      throwsA(isA<LaundryException>()),
    );
    expect((await other.getComplaintInbox()).complaints, isEmpty);
    await expectLater(
      resident.createComplaint(
        laundryId: 'R1',
        lineId: 'R2-L',
        reason: ComplaintReason.missing,
        description: description,
      ),
      throwsA(isA<LaundryException>()),
    );
  });

  test(
    'driver pressing unknown and missing accounts cannot operate on cases',
    () async {
      final id = await create();
      for (final user in [testDriver, testPressing, testUnknown, null]) {
        final repo = LaundryRepository(
          currentUser: user,
          databaseProvider: () async => db,
        );
        await expectLater(
          repo.getComplaintInbox(),
          throwsA(isA<LaundryException>()),
        );
        await expectLater(
          repo.getComplaintDetails(id),
          throwsA(isA<LaundryException>()),
        );
        await expectLater(
          repo.createComplaint(
            laundryId: 'R1',
            reason: ComplaintReason.damaged,
            description: description,
          ),
          throwsA(isA<LaundryException>()),
        );
        await expectLater(
          repo.advanceComplaint(
            id,
            expectedRevision: 1,
            newStatus: ComplaintStatus.reviewing,
          ),
          throwsA(isA<LaundryException>()),
        );
      }
      await expectLater(
        admin.createComplaint(
          laundryId: 'R1',
          reason: ComplaintReason.other,
          description: description,
        ),
        throwsA(isA<LaundryException>()),
      );
      await expectLater(
        resident.advanceComplaint(
          id,
          expectedRevision: 1,
          newStatus: ComplaintStatus.reviewing,
        ),
        throwsA(isA<LaundryException>()),
      );
    },
  );

  test('invalid descriptions and photos never leave a partial case', () async {
    for (final text in ['', '         ', 'court', 'a' * 2001]) {
      await expectLater(
        resident.createComplaint(
          laundryId: 'R1',
          reason: ComplaintReason.other,
          description: text,
        ),
        throwsA(isA<LaundryException>()),
      );
    }
    final valid = await complaintTestPhoto();
    for (final photos in [
      [valid, valid, valid, valid],
      [ComplaintPhoto(bytes: [], mimeType: 'image/png')],
      [ComplaintPhoto(bytes: valid.bytes, mimeType: 'image/jpeg')],
      [ComplaintPhoto(bytes: List.filled(2097153, 0), mimeType: 'image/png')],
      [
        ComplaintPhoto(bytes: [255, 216, 255, 0], mimeType: 'image/jpeg'),
      ],
    ]) {
      await expectLater(
        create(photos: photos),
        throwsA(isA<LaundryException>()),
      );
    }
    for (final table in [
      'laundry_complaints',
      'laundry_complaint_events',
      'laundry_complaint_attachments',
    ]) {
      expect(await readLaundryRows(db, table), isEmpty);
    }
  });

  test(
    'duplicate active reason is rejected without duplicate events',
    () async {
      final first = await create();
      await expectLater(create(), throwsA(isA<LaundryException>()));
      expect((await resident.getComplaintInbox()).complaints.single.id, first);
      expect((await readLaundryRows(db, 'laundry_complaint_events')).length, 1);
    },
  );

  test('review resolution and unread responses use real actors and stale-safe acknowledgements', () async {
    final id = await create();
    await expectLater(
      admin.advanceComplaint(
        id,
        expectedRevision: 1,
        newStatus: ComplaintStatus.resolved,
        decisionReason: 'Solution vérifiée et expliquée.',
      ),
      throwsA(isA<LaundryException>()),
    );
    await admin.advanceComplaint(
      id,
      expectedRevision: 1,
      newStatus: ComplaintStatus.reviewing,
    );
    expect((await resident.getComplaintInbox()).unreadCount, 1);
    await resident.markComplaintSeen(id, expectedRevision: 2);
    expect((await resident.getComplaintInbox()).unreadCount, 0);
    await expectLater(
      admin.advanceComplaint(
        id,
        expectedRevision: 2,
        newStatus: ComplaintStatus.resolved,
        decisionReason: 'court',
      ),
      throwsA(isA<LaundryException>()),
    );
    await admin.advanceComplaint(
      id,
      expectedRevision: 2,
      newStatus: ComplaintStatus.resolved,
      decisionReason:
          'Le vêtement a été repris et réparé avec accord du résident.',
    );
    await resident.markComplaintSeen(id, expectedRevision: 2);
    expect((await resident.getComplaintInbox()).unreadCount, 1);
    final details = await resident.getComplaintDetails(id);
    expect(details.events.map((e) => e.actorId), [1, 9, 9]);
    expect(details.complaint.decisionReason, contains('réparé'));
    await resident.markComplaintSeen(id, expectedRevision: 3);
    expect((await resident.getComplaintInbox()).unreadCount, 0);
    await expectLater(
      admin.advanceComplaint(
        id,
        expectedRevision: 3,
        newStatus: ComplaintStatus.reviewing,
      ),
      throwsA(isA<LaundryException>()),
    );
    expect((await admin.getById('R1'))!.status, LaundryStatus.deposited);
  });

  test('rejection requires a reason and concurrent review cannot overwrite a decision', () async {
    final id = await create();
    await admin.advanceComplaint(
      id,
      expectedRevision: 1,
      newStatus: ComplaintStatus.reviewing,
    );
    await expectLater(
      admin.advanceComplaint(
        id,
        expectedRevision: 1,
        newStatus: ComplaintStatus.rejected,
        decisionReason: description,
      ),
      throwsA(isA<LaundryException>()),
    );
    await admin.advanceComplaint(
      id,
      expectedRevision: 2,
      newStatus: ComplaintStatus.rejected,
      decisionReason:
          'Après examen du dossier, le défaut signalé ne peut être confirmé.',
    );
    expect(
      (await resident.getComplaintDetails(id)).complaint.status,
      ComplaintStatus.rejected,
    );
    expect(
      (await resident.getComplaintDetails(id)).events.last.note,
      contains('examen'),
    );
  });

  test(
    'case preserves its original owner and garment if the request changes',
    () async {
      final id = await create();
      await expectLater(admin.delete('R1'), throwsA(isA<LaundryException>()));
      await expectLater(
        resident.deleteForResident('R1', residentId: 1),
        throwsA(isA<LaundryException>()),
      );
      await expectLater(
        db.delete('laundry_items', where: 'id = ?', whereArgs: ['R1']),
        throwsA(isA<DatabaseException>()),
      );
      final detail = await admin.getDetails('R1');
      await admin.saveRequest(
        LaundryDetails(
          item: detail.item.copyWith(residentId: 2),
          revision: detail.revision,
          lines: [
            const LaundryLine(
              id: 'NEW',
              garment: 'Drap',
              serviceId: 'washing',
              quantity: 1,
            ),
          ],
        ),
      );
      final complaint = (await resident.getComplaintDetails(id)).complaint;
      expect(complaint.residentId, 1);
      expect(complaint.lineId, isNull);
      expect(complaint.garmentSnapshot, 'Chemise blanche');
      await expectLater(
        admin.forUser(testOtherResident).getComplaintDetails(id),
        throwsA(isA<LaundryException>()),
      );
    },
  );

  test(
    'decision history failure rolls back status revision and unread state',
    () async {
      final id = await create();
      final before = await db.query('laundry_complaints');
      await db.execute(
        "CREATE TRIGGER fail_complaint_event BEFORE INSERT ON laundry_events WHEN NEW.event_type = 'complaint_status' BEGIN SELECT RAISE(ABORT,'test-only'); END",
      );
      await expectLater(
        admin.advanceComplaint(
          id,
          expectedRevision: 1,
          newStatus: ComplaintStatus.reviewing,
        ),
        throwsA(isA<DatabaseException>()),
      );
      expect(await db.query('laundry_complaints'), before);
      expect((await resident.getComplaintDetails(id)).events.length, 1);
    },
  );

  test('attachment failure rolls back the case and initial event', () async {
    await db.execute(
      "CREATE TRIGGER fail_complaint_photo BEFORE UPDATE OF photo_1 ON laundry_complaints BEGIN SELECT RAISE(ABORT,'test-only'); END",
    );
    await expectLater(
      create(photos: [await complaintTestPhoto()]),
      throwsA(isA<DatabaseException>()),
    );
    expect(await db.query('laundry_complaints'), isEmpty);
    expect(await readLaundryRows(db, 'laundry_complaint_events'), isEmpty);
  });

  test('delay complaints use actual treatment deadline rather than a fabricated delivery date', () async {
    await expectLater(
      create(reason: ComplaintReason.treatmentDelay),
      throwsA(isA<LaundryException>()),
    );
    await expectLater(
      admin
          .forUser(testOtherResident)
          .createComplaint(
            laundryId: 'R2',
            reason: ComplaintReason.treatmentDelay,
            description: description,
          ),
      throwsA(isA<LaundryException>()),
    );
    now = now.add(const Duration(minutes: 6));
    final id = await create(reason: ComplaintReason.treatmentDelay);
    expect(
      (await resident.getComplaintDetails(id)).complaint.reason,
      ComplaintReason.treatmentDelay,
    );
  });

  test(
    'photos decisions and notifications survive file-backed SQLite reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'residry-complaint-test-',
      );
      try {
        final photo = await complaintTestPhoto();
        final id = await create(photos: [photo]);
        await admin.advanceComplaint(
          id,
          expectedRevision: 1,
          newStatus: ComplaintStatus.reviewing,
        );
        final path = '${directory.path}/residry.db';
        await db.execute('VACUUM INTO ?', [path]);
        await db.close();
        db = await databaseFactoryFfi.openDatabase(
          path,
          options: OpenDatabaseOptions(
            onConfigure: (db) => db.execute('PRAGMA foreign_keys=ON'),
          ),
        );
        expect((await resident.getComplaintInbox()).unreadCount, 1);
        expect(
          (await resident.getComplaintDetails(id)).photos.single.bytes,
          photo.bytes,
        );
        expect((await resident.getComplaintDetails(id)).events.length, 2);
        expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
        await db.close();
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );
}
