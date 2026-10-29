part of 'laundry_repository.dart';

/// Kept in the same library to reuse authentication and transaction checks.
extension LaundryEssentialOperations on LaundryRepository {
  Future<List<LaundryServiceType>> getServices() => _authorized(
    LaundryRepository._allRoles,
    (db, actor, role) async => (await LaundryStorage.services(
      db,
      activeOnly: true,
    )).map(LaundryServiceType.fromMap).toList(),
  );

  Future<List<LaundryTariff>> getTariffs() => _authorized(
    {LaundryRole.admin},
    (db, actor, role) async =>
        (await LaundryStorage.tariffs(db)).map(LaundryTariff.fromMap).toList(),
  );

  Future<void> saveTariff({
    required String serviceId,
    required LaundryPricingBasis basis,
    required int unitPriceMillimes,
    int? estimatedMinutes,
  }) => _authorized({LaundryRole.admin}, (db, actor, role) async {
    if (unitPriceMillimes < 0 ||
        unitPriceMillimes > 9007199254740 ||
        (estimatedMinutes != null &&
            (estimatedMinutes <= 0 || estimatedMinutes > 525600))) {
      throw const LaundryException('Vérifiez le tarif et la durée.');
    }
    final services = (await LaundryStorage.services(
      db,
      activeOnly: true,
    )).where((s) => s['id'] == serviceId).toList();
    if (services.length != 1) {
      throw const LaundryException('Service indisponible.');
    }
    final now = _clock().toUtc();
    final stamp = now.toIso8601String();
    final previous = await LaundryStorage.tariffs(db, serviceId: serviceId);
    for (final row in previous) {
      if (row['pricing_basis'] != basisCode(basis)) continue;
      final tariff = LaundryTariff.fromMap(row);
      if (tariff.rate.appliesAt(now)) {
        if (!now.isAfter(tariff.rate.validFrom)) {
          throw const LaundryException(
            'Ce tarif vient d’être enregistré. Réessayez.',
          );
        }
        row['valid_until'] = stamp;
      }
    }
    previous.add({
      'id': 'RATE:$serviceId:${basisCode(basis)}:${now.microsecondsSinceEpoch}',
      'service_id': serviceId,
      'pricing_basis': basisCode(basis),
      'unit_price_millimes': unitPriceMillimes,
      'estimated_minutes': estimatedMinutes,
      'valid_from': stamp,
      'created_by_user_id': actor.id,
      'created_at': stamp,
    });
    await LaundryStorage.writeTariffs(db, serviceId, previous);
  });

  Future<LaundryDetails> getDetails(String id) =>
      _authorized(LaundryRepository._allRoles, (db, actor, role) async {
        final rows = await db.query(
          'laundry_items',
          where: 'id = ?',
          whereArgs: [id],
        );
        if (rows.isEmpty) {
          throw const LaundryException('Cette demande n’existe plus.');
        }
        _checkRead(LaundryItem.fromMap(rows.single), actor, role);
        return (await _details(db, rows, role)).single;
      });

  Future<List<LaundryDetails>> _details(
    Transaction db,
    List<Map<String, Object?>> rows,
    LaundryRole role,
  ) async {
    final hide = role == LaundryRole.resident || role == LaundryRole.driver;
    final items = await _resolve(db, rows, hidePrices: hide);
    final result = <LaundryDetails>[];
    for (var index = 0; index < items.length; index++) {
      final row = rows[index];
      final item = items[index];
      final history = (await LaundryStorage.history(
        db,
        item.id,
      )).map(LaundryStatusChange.fromMap).toList();
      final names = <int, String>{};
      for (final userId
          in history.map((h) => h.changedByUserId).whereType<int>().toSet()) {
        final user = await _users.getUserById(userId, executor: db);
        if (user != null) names[userId] = user.name;
      }
      result.add(
        LaundryDetails(
          item: item,
          actorNames: names,
          dueAt: row['treatment_due_at'] == null
              ? null
              : DateTime.parse(row['treatment_due_at'] as String),
          urgency: row['urgency'] == 'urgent'
              ? LaundryUrgency.urgent
              : LaundryUrgency.normal,
          revision: row['revision'] as int? ?? 0,
          lines: (await LaundryStorage.lines(
            db,
            item.id,
          )).map((r) => LaundryLine.fromMap(r, hidePrices: hide)).toList(),
          history: history,
        ),
      );
    }
    return result;
  }

  /// Draft prices and names are ignored. Stored tariffs are the only source.
  Future<LaundryDetails> previewRequest(LaundryDetails draft) => _authorized(
    {LaundryRole.admin, LaundryRole.resident},
    (db, actor, role) async {
      if (role == LaundryRole.resident && draft.item.residentId != actor.id) {
        throw const LaundryException('Cette demande ne vous appartient pas.');
      }
      final existing = await _find(db, draft.item.id);
      if (existing != null) {
        _checkRead(existing, actor, role);
        if (role == LaundryRole.resident) _checkResident(existing, actor);
      }
      final result = await _calculate(db, draft, _clock().toUtc());
      return role == LaundryRole.resident
          ? LaundryDetails(
              item: result.item.copyWith(price: 0, priceConfirmed: false),
              lines: result.lines
                  .map(
                    (line) => LaundryLine(
                      id: line.id,
                      garment: line.garment,
                      serviceId: line.serviceId,
                      quantity: line.quantity,
                      basis: line.basis,
                      weightGrams: line.weightGrams,
                      instructions: line.instructions,
                      estimatedMinutes: line.estimatedMinutes,
                    ),
                  )
                  .toList(),
              dueAt: result.dueAt,
              urgency: result.urgency,
              revision: result.revision,
            )
          : result;
    },
  );

  Future<LaundryDetails> _calculate(
    Transaction db,
    LaundryDetails draft,
    DateTime now,
  ) async {
    final services = (await LaundryStorage.services(
      db,
      activeOnly: true,
    )).map(LaundryServiceType.fromMap).toList();
    final tariffs = (await LaundryStorage.tariffs(db))
        .map(LaundryTariff.fromMap)
        .toList();
    if (draft.lines.isEmpty ||
        draft.lines.length > 100 ||
        draft.lines.map((l) => l.id).toSet().length != draft.lines.length) {
      throw const LaundryException('Ajoutez entre 1 et 100 lots distincts.');
    }
    final lines = <LaundryLine>[];
    var total = 0;
    var complete = true;
    for (final line in draft.lines) {
      if (line.id.trim().isEmpty ||
          line.garment.trim().isEmpty ||
          line.garment.length > 120 ||
          line.quantity <= 0 ||
          line.quantity > 100000 ||
          (line.weightGrams != null &&
              (line.weightGrams! <= 0 || line.weightGrams! > 100000000)) ||
          line.instructions.length > 2000 ||
          !services.any((s) => s.id == line.serviceId)) {
        throw const LaundryException(
          'Vérifiez les articles, les quantités et les poids.',
        );
      }
      final quote = const PricingService().calculate(
        serviceCode: line.serviceId,
        basis: line.basis,
        rates: tariffs.map((t) => t.rate),
        now: now,
        quantity: line.quantity,
        weightGrams: line.weightGrams,
      );
      complete = complete && quote.canCalculate;
      total += quote.totalMillimes ?? 0;
      if (total > 9007199254740991) {
        throw const LaundryException('Montant trop élevé.');
      }
      final matched = tariffs.where(
        (t) =>
            t.rate.serviceCode == line.serviceId &&
            t.rate.basis == line.basis &&
            t.rate.appliesAt(now),
      );
      lines.add(
        LaundryLine(
          id: line.id,
          garment: line.garment.trim(),
          serviceId: line.serviceId,
          quantity: line.quantity,
          basis: line.basis,
          weightGrams: line.weightGrams,
          instructions: line.instructions.trim(),
          tariffId: quote.rateId,
          unitPriceMillimes: quote.unitPriceMillimes,
          totalMillimes: quote.totalMillimes,
          estimatedMinutes: matched.length != 1
              ? null
              : matched.single.estimatedMinutes,
        ),
      );
    }
    final summary = lines
        .map((line) => services.singleWhere((s) => s.id == line.serviceId).fr)
        .toSet()
        .join(' + ');
    return LaundryDetails(
      item: draft.item.copyWith(
        serviceType: summary,
        price: complete ? total / 1000 : 0,
        priceConfirmed: complete,
      ),
      lines: lines,
      dueAt: draft.dueAt,
      urgency: draft.urgency,
      revision: draft.revision,
    );
  }

  Future<void> saveRequest(
    LaundryDetails draft,
  ) => _authorized({LaundryRole.admin, LaundryRole.resident}, (
    db,
    actor,
    role,
  ) async {
    final rows = await db.query(
      'laundry_items',
      where: 'id = ?',
      whereArgs: [draft.item.id],
    );
    final current = rows.isEmpty ? null : LaundryItem.fromMap(rows.single);
    if (current != null &&
        (rows.single['revision'] as int? ?? 0) != draft.revision) {
      throw const LaundryException(
        'La demande a changé. Actualisez avant de modifier.',
      );
    }
    if (role == LaundryRole.resident) {
      if (draft.item.residentId != actor.id ||
          draft.item.status != LaundryStatus.deposited) {
        throw const LaundryException('Opération non autorisée.');
      }
      if (current != null) _checkResident(current, actor);
    }
    // An administrator may keep an imported request unassigned. New requests
    // and explicit associations still require a real central resident.
    final keepUnassigned =
        role == LaundryRole.admin &&
        current != null &&
        current.residentId == null &&
        draft.item.residentId == null;
    final resident = keepUnassigned
        ? null
        : await _resident(
            db,
            role == LaundryRole.resident ? actor.id : draft.item.residentId,
          );
    final now = _clock().toUtc();
    final createdAt = current?.createdAt ?? now;
    if (draft.dueAt != null && draft.dueAt!.isBefore(createdAt)) {
      throw const LaundryException(
        'L’échéance doit suivre la création de la demande.',
      );
    }
    final frozen = current != null && current.status != LaundryStatus.deposited;
    LaundryDetails calculated;
    if (frozen) {
      final saved = (await _details(db, rows, role)).single;
      String signature(LaundryLine l) => jsonEncode([
        l.id,
        l.garment,
        l.serviceId,
        l.quantity,
        l.weightGrams,
        basisCode(l.basis),
        l.instructions,
      ]);
      if (jsonEncode(saved.lines.map(signature).toList()) !=
          jsonEncode(draft.lines.map(signature).toList())) {
        throw const LaundryException(
          'Les articles pris en charge ne peuvent plus être modifiés.',
        );
      }
      calculated = LaundryDetails(
        item: current.copyWith(status: draft.item.status),
        lines: saved.lines,
      );
    } else {
      calculated = await _calculate(db, draft, now);
    }
    final item = calculated.item;
    _validate(item);
    final row = item.toMap()
      ..['resident_id'] = resident?.id
      ..['resident_name'] = current?.residentNameSnapshot ?? resident!.name
      ..['created_at'] = createdAt.toIso8601String()
      ..['treatment_due_at'] = draft.dueAt?.toUtc().toIso8601String()
      ..['urgency'] = draft.urgency.name
      ..['updated_at'] = now.toIso8601String()
      ..['revision'] = draft.revision + 1;
    if (current == null) {
      await db.insert('laundry_items', row);
      await _record(db, item.id, null, item.status, actor.id!);
    } else {
      final changed = await db.update(
        'laundry_items',
        row,
        where: 'id = ? AND revision = ?',
        whereArgs: [item.id, draft.revision],
      );
      if (changed != 1) {
        throw const LaundryException('La demande a changé. Actualisez.');
      }
      if (current.status != item.status) {
        await _record(db, item.id, current.status, item.status, actor.id!);
      }
    }
    if (!frozen) {
      final previousLines = {
        for (final row in await LaundryStorage.lines(db, item.id))
          row['id']: row,
      };
      // Editable deposits only. Historical completed lots and tariff snapshots
      // are never repriced by changing a tariff configuration.
      final storedLines = <Map<String, Object?>>[];
      for (final line in calculated.lines) {
        final previous = previousLines[line.id];
        final unchanged =
            previous != null &&
            previous['garment_type'] == line.garment &&
            previous['service_id'] == line.serviceId &&
            previous['quantity'] == line.quantity &&
            previous['weight_grams'] == line.weightGrams &&
            previous['instructions'] == line.instructions;
        storedLines.add({
          'id': line.id,
          'laundry_id': item.id,
          'garment_type': line.garment,
          'service_id': line.serviceId,
          'quantity': line.quantity,
          'weight_grams': line.weightGrams,
          'instructions': line.instructions,
          'pricing_basis': basisCode(line.basis),
          'pricing_rule_id': line.tariffId,
          'unit_price_millimes': line.unitPriceMillimes,
          'total_millimes': line.totalMillimes,
          'estimated_minutes': line.estimatedMinutes,
          'created_at': now.toIso8601String(),
          if (unchanged) ...{
            for (final entry in previous.entries.where(
              (entry) => entry.key.startsWith('sorting_'),
            ))
              entry.key: entry.value,
          },
        });
      }
      try {
        await LaundryStorage.writeLines(db, item.id, storedLines);
      } on FormatException {
        throw const LaundryException(
          'Identifiant de lot déjà utilisé ou invalide.',
        );
      }
    }
  });
}
