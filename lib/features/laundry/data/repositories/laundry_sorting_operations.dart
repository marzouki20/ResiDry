part of 'laundry_repository.dart';

extension LaundrySortingOperations on LaundryRepository {
  Future<LaundrySortingData> getSortingData() => _authorized(
    {LaundryRole.admin, LaundryRole.pressing},
    (db, actor, role) async {
      final requests = await db.query(
        'laundry_items',
        where: 'status = ?',
        whereArgs: ['deposited'],
        orderBy: 'id ASC',
      );
      final lots = <LaundrySortingLot>[];
      final revisions = <String, int>{};
      final legacy = <String>[];
      for (final request in requests) {
        final id = request['id'] as String;
        revisions[id] = request['revision'] as int? ?? 0;
        final rows = await LaundryStorage.lines(db, id);
        if (rows.isEmpty) legacy.add(id);
        for (final row in rows) {
          lots.add(
            LaundrySortingLot(
              requestId: id,
              lineId: row['id'] as String,
              garment: row['garment_type'] as String,
              serviceId: row['service_id'] as String,
              status: LaundryStatus.deposited,
              quantity: row['quantity'] as int,
              weightGrams: row['weight_grams'] as int?,
              instructions: row['instructions'] as String,
              profile: readSortingProfile(row),
            ),
          );
        }
      }
      return LaundrySortingData(
        lots: lots,
        revisions: revisions,
        requestsWithoutLots: legacy,
        plan: const SortingService().propose(lots, now: _clock().toUtc()),
      );
    },
  );

  /// The caller supplies observations, never the identity/date of the verifier.
  Future<void> saveSortingProfile({
    required String requestId,
    required String lineId,
    required int expectedRevision,
    required LaundrySortingProfile profile,
  }) => _authorized({LaundryRole.admin, LaundryRole.pressing}, (
    db,
    actor,
    role,
  ) async {
    final requests = await db.query(
      'laundry_items',
      where: 'id = ?',
      whereArgs: [requestId],
    );
    if (requests.isEmpty ||
        requests.single['status'] != 'deposited' ||
        (requests.single['revision'] as int? ?? 0) != expectedRevision) {
      throw const LaundryException(
        'La demande a changé. Actualisez avant de modifier.',
      );
    }
    final allLines = await LaundryStorage.lines(db, requestId);
    final rows = allLines.where((r) => r['id'] == lineId).toList();
    if (rows.length != 1 || rows.single['service_id'] != 'washing') {
      throw const LaundryException('Service indisponible.');
    }
    if (profile.maxTemperatureC != null &&
        (profile.maxTemperatureC! < 1 || profile.maxTemperatureC! > 95)) {
      throw const LaundryException(
        'Vérifiez la température indiquée sur l’étiquette.',
      );
    }
    final now = _clock().toUtc().toIso8601String();
    final count = await db.update(
      'laundry_items',
      {'revision': expectedRevision + 1, 'updated_at': now},
      where: 'id = ? AND revision = ?',
      whereArgs: [requestId, expectedRevision],
    );
    if (count != 1) {
      throw const LaundryException('La demande a changé. Actualisez.');
    }
    rows.single.addAll({
      'sorting_color': profile.color?.name,
      'sorting_fabric': profile.fabric?.name,
      'sorting_cycle': profile.cycle?.name,
      'sorting_max_temperature_c': profile.maxTemperatureC,
      'sorting_dye_transfer_risk': profile.dyeTransferRisk.name,
      'sorting_wash_separately': profile.washSeparately == null
          ? null
          : (profile.washSeparately! ? 1 : 0),
      'sorting_verified_by_user_id': actor.id,
      'sorting_verified_at': now,
    });
    await LaundryStorage.writeLines(db, requestId, allLines);
  });
}
