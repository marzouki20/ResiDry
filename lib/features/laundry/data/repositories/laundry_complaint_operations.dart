part of 'laundry_repository.dart';

extension LaundryComplaintOperations on LaundryRepository {
  Future<void> _ensureNoComplaint(DatabaseExecutor db, String laundryId) async {
    if ((await db.query(
      'laundry_complaints',
      where: 'laundry_id = ?',
      whereArgs: [laundryId],
      limit: 1,
    )).isNotEmpty) {
      throw const LaundryException(
        'Cette demande doit être conservée : une réclamation y est liée.',
      );
    }
  }

  Future<ComplaintInbox> getComplaintInbox({String? laundryId}) => _authorized(
    {LaundryRole.resident, LaundryRole.admin},
    (db, actor, role) async {
      final clauses = <String>[];
      final args = <Object?>[];
      if (role == LaundryRole.resident) {
        clauses.add('resident_id = ?');
        args.add(actor.id);
      }
      if (laundryId != null) {
        clauses.add('laundry_id = ?');
        args.add(laundryId);
      }
      final rows = await db.query(
        'laundry_complaints',
        columns: LaundryStorage.complaintColumns,
        where: clauses.isEmpty ? null : clauses.join(' AND '),
        whereArgs: args.isEmpty ? null : args,
        orderBy: 'updated_at DESC, id DESC',
      );
      final cases = rows.map(readComplaint).toList();
      final names = <int, String>{};
      for (final id in cases.map((c) => c.residentId).toSet()) {
        final account = await _users.getUserById(id, executor: db);
        if (account != null) names[id] = account.name;
      }
      return ComplaintInbox(role: role, complaints: cases, names: names);
    },
  );

  Future<LaundryComplaint> _requireComplaint(
    Transaction db,
    String id,
    User actor,
    LaundryRole role,
  ) async {
    final rows = await db.query(
      'laundry_complaints',
      columns: LaundryStorage.complaintColumns,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) throw const LaundryException('Réclamation introuvable.');
    final complaint = readComplaint(rows.single);
    if (role != LaundryRole.admin && complaint.residentId != actor.id) {
      throw const LaundryException('Cette réclamation ne vous appartient pas.');
    }
    return complaint;
  }

  Future<ComplaintDetails> getComplaintDetails(String id) => _authorized(
    {LaundryRole.resident, LaundryRole.admin},
    (db, actor, role) async {
      final complaint = await _requireComplaint(db, id, actor, role);
      final events = (await LaundryStorage.complaintEvents(db, id))
          .map(
            (r) => ComplaintEvent(
              id: r['id'] as int,
              oldStatus: r['old_status'] == null
                  ? null
                  : ComplaintStatus.values.byName(r['old_status'] as String),
              newStatus: ComplaintStatus.values.byName(
                r['new_status'] as String,
              ),
              actorId: r['actor_id'] as int,
              note: r['note'] as String,
              createdAt: DateTime.parse(r['created_at'] as String),
            ),
          )
          .toList();
      final photos = (await LaundryStorage.photos(db, id)).map(
        (r) => ComplaintPhoto(
          bytes: r['content'] as List<int>,
          mimeType: r['mime_type'] as String,
        ),
      );
      final names = <int, String>{};
      for (final userId in {
        complaint.residentId,
        ...events.map((e) => e.actorId),
      }) {
        final user = await _users.getUserById(userId, executor: db);
        if (user != null) names[userId] = user.name;
      }
      return ComplaintDetails(
        complaint: complaint,
        role: role,
        events: events,
        photos: photos,
        names: names,
      );
    },
  );

  Future<String> createComplaint({
    required String laundryId,
    required ComplaintReason reason,
    required String description,
    String? lineId,
    List<ComplaintPhoto> photos = const [],
  }) => _authorized({LaundryRole.resident}, (db, actor, role) async {
    final item = await _require(db, laundryId);
    if (item.residentId != actor.id) {
      throw const LaundryException('Cette demande ne vous appartient pas.');
    }
    if (!const ComplaintService().validText(description)) {
      throw const LaundryException(
        'Décrivez le problème en 10 à 2000 caractères.',
      );
    }
    final existing = await db.query(
      'laundry_complaints',
      where: 'laundry_id = ? AND resident_id = ? AND reason = ?',
      whereArgs: [laundryId, actor.id, reason.name],
    );
    if (existing.any(
      (r) => r['status'] == 'submitted' || r['status'] == 'reviewing',
    )) {
      throw const LaundryException(
        'Une réclamation pour ce motif est déjà en cours.',
      );
    }
    String? garment;
    if (lineId != null) {
      final lines = (await LaundryStorage.lines(
        db,
        laundryId,
      )).where((r) => r['id'] == lineId).toList();
      if (lines.length != 1) {
        throw const LaundryException('Sélectionnez un lot de cette demande.');
      }
      garment = lines.single['garment_type'] as String;
    }
    final now = _clock().toUtc();
    if (reason == ComplaintReason.treatmentDelay) {
      final rows = await db.query(
        'laundry_items',
        where: 'id = ?',
        whereArgs: [laundryId],
      );
      final detail = (await _details(db, rows, role)).single;
      if (!const ComplaintService().confirmedTreatmentDelay(
        item: detail.item,
        dueAt: detail.dueAt,
        history: detail.history,
        now: now,
      )) {
        throw const LaundryException(
          'Aucun retard de traitement vérifiable pour cette demande.',
        );
      }
    }
    try {
      await validateComplaintPhotos(photos);
    } catch (_) {
      throw const LaundryException(
        'Photos invalides : 3 maximum, 2 Mo par photo (JPEG, PNG ou WebP).',
      );
    }
    final id =
        'CL${now.microsecondsSinceEpoch}-${math.Random.secure().nextInt(0x100000000).toRadixString(16)}';
    final stamp = now.toIso8601String();
    await db.insert('laundry_complaints', {
      'id': id,
      'laundry_id': laundryId,
      'resident_id': actor.id,
      'line_id': lineId,
      'garment_snapshot': garment,
      'reason': reason.name,
      'description': description.trim(),
      'status': 'submitted',
      'created_at': stamp,
      'updated_at': stamp,
      'revision': 1,
      'resident_seen_revision': 1,
    });
    await LaundryStorage.addComplaintEvent(db, {
      'complaint_id': id,
      'old_status': null,
      'new_status': 'submitted',
      'actor_id': actor.id,
      'note': '',
      'revision': 1,
      'created_at': stamp,
    });
    await LaundryStorage.addPhotos(db, id, [
      for (final photo in photos)
        {
          'complaint_id': id,
          'mime_type': photo.mimeType,
          'content': photo.bytes,
          'created_at': stamp,
        },
    ]);
    return id;
  });

  Future<void> advanceComplaint(
    String id, {
    required int expectedRevision,
    required ComplaintStatus newStatus,
    String decisionReason = '',
  }) => _authorized({LaundryRole.admin}, (db, actor, role) async {
    final current = await _requireComplaint(db, id, actor, role);
    if (current.revision != expectedRevision) {
      throw const LaundryException('La réclamation a changé. Actualisez.');
    }
    if (!const ComplaintService().allows(current.status, newStatus)) {
      throw const LaundryException('Transition de réclamation non autorisée.');
    }
    final terminal =
        newStatus == ComplaintStatus.resolved ||
        newStatus == ComplaintStatus.rejected;
    if (terminal && !const ComplaintService().validText(decisionReason)) {
      throw const LaundryException(
        'Motivez la décision en 10 à 2000 caractères.',
      );
    }
    final stamp = _clock().toUtc().toIso8601String();
    final revision = current.revision + 1;
    final count = await db.update(
      'laundry_complaints',
      {
        'status': newStatus.name,
        'decision_reason': terminal ? decisionReason.trim() : null,
        'revision': revision,
        'updated_at': stamp,
      },
      where: 'id = ? AND revision = ?',
      whereArgs: [id, expectedRevision],
    );
    if (count != 1) {
      throw const LaundryException('La réclamation a changé. Actualisez.');
    }
    await LaundryStorage.addComplaintEvent(db, {
      'complaint_id': id,
      'old_status': current.status.name,
      'new_status': newStatus.name,
      'actor_id': actor.id,
      'note': terminal ? decisionReason.trim() : '',
      'revision': revision,
      'created_at': stamp,
    });
  });

  Future<void> markComplaintSeen(String id, {required int expectedRevision}) =>
      _authorized({LaundryRole.resident}, (db, actor, role) async {
        final current = await _requireComplaint(db, id, actor, role);
        if (current.revision != expectedRevision ||
            current.residentSeenRevision >= expectedRevision) {
          return;
        }
        await db.update(
          'laundry_complaints',
          {'resident_seen_revision': expectedRevision},
          where: 'id = ? AND resident_id = ? AND revision = ?',
          whereArgs: [id, actor.id, expectedRevision],
        );
      });
}
