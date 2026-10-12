import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../../domain/entities.dart';

/// One queued change that still has to be sent to the server.
class OutboxOp {
  OutboxOp(this.seq, this.type, this.entityId, this.op, this.ver);
  final int seq;
  final String type; // customer | site | note
  final String entityId;
  final String op; // upsert | delete | photo
  final int ver;
}

/// SQLite storage = the app's source of truth. UI only ever reads from here.
class LocalDb {
  Future<Database>? _opening;
  final _changes = StreamController<void>.broadcast(); // any data change
  final _local = StreamController<void>.broadcast(); // user-made change (needs a sync)

  Stream<void> get changes => _changes.stream;
  Stream<void> get localChanges => _local.stream;

  Future<Database> get _d => _opening ??= _open();

  Future<Database> _open() async {
    final path = kIsWeb ? 'field_notes_web.db' : p.join(await getDatabasesPath(), 'field_notes.db');
    if (kIsWeb) databaseFactory = databaseFactoryFfiWeb;
    return openDatabase(
      path,
      version: 1,
      onConfigure: (d) => d.execute('PRAGMA foreign_keys = ON'),
      onCreate: (d, _) async {
        await d.execute('''CREATE TABLE customers(
          id TEXT PRIMARY KEY, name TEXT NOT NULL, contact_info TEXT NOT NULL DEFAULT '', updated_at INTEGER NOT NULL)''');
        await d.execute('''CREATE TABLE sites(
          id TEXT PRIMARY KEY, customer_id TEXT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
          name TEXT NOT NULL, address TEXT NOT NULL DEFAULT '', updated_at INTEGER NOT NULL)''');
        await d.execute('CREATE INDEX idx_sites_customer ON sites(customer_id)');
        await d.execute('''CREATE TABLE field_notes(
          id TEXT PRIMARY KEY, site_id TEXT NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
          title TEXT NOT NULL, description TEXT NOT NULL DEFAULT '', latitude REAL, longitude REAL,
          note_date_time INTEGER NOT NULL, status TEXT NOT NULL, photo_path TEXT, photo_url TEXT,
          updated_at INTEGER NOT NULL)''');
        await d.execute('CREATE INDEX idx_notes_site ON field_notes(site_id)');
        await d.execute('''CREATE TABLE outbox(
          seq INTEGER PRIMARY KEY AUTOINCREMENT, entity_type TEXT NOT NULL, entity_id TEXT NOT NULL,
          op TEXT NOT NULL, ver INTEGER NOT NULL DEFAULT 0, UNIQUE(entity_type, entity_id, op))''');
      },
    );
  }

  // ---------- helpers ----------
  void _notify(bool local) {
    _changes.add(null);
    if (local) _local.add(null);
  }

  Stream<T> _watch<T>(Future<T> Function() query) {
    late StreamController<T> c;
    StreamSubscription<void>? sub;
    var run = 0;
    Future<void> refresh() async {
      final id = ++run;
      try {
        final v = await query();
        if (id == run && !c.isClosed) c.add(v);
      } catch (e) {
        if (!c.isClosed) c.addError(e);
      }
    }

    c = StreamController<T>(
      onListen: () {
        refresh();
        sub = _changes.stream.listen((_) => refresh());
      },
      onCancel: () => sub?.cancel(),
    );
    return c.stream;
  }

  static DateTime _dt(Object? v) => DateTime.fromMillisecondsSinceEpoch(v as int, isUtc: true);
  static int _ms(DateTime d) => d.toUtc().millisecondsSinceEpoch;

  Future<void> _save(String table, String type, String id, Map<String, Object?> row, bool queue,
      {List<String> extraOps = const []}) async {
    final d = await _d;
    await d.transaction((t) async {
      // update-then-insert (NOT "insert or replace": REPLACE would trigger ON DELETE CASCADE on children)
      final n = await t.update(table, row, where: 'id = ?', whereArgs: [id]);
      if (n == 0) await t.insert(table, row);
      if (queue) {
        await _enqueue(t, type, id, 'upsert');
        for (final op in extraOps) {
          await _enqueue(t, type, id, op);
        }
      }
    });
    _notify(queue);
  }

  Future<void> _enqueue(DatabaseExecutor t, String type, String id, String op) async {
    final n = await t.rawUpdate(
        'UPDATE outbox SET ver = ver + 1 WHERE entity_type = ? AND entity_id = ? AND op = ?', [type, id, op]);
    if (n == 0) await t.insert('outbox', {'entity_type': type, 'entity_id': id, 'op': op, 'ver': 0});
  }

  Future<void> _clearOutbox(DatabaseExecutor t, List<String> ids) async {
    if (ids.isEmpty) return;
    await t.delete('outbox', where: 'entity_id IN (${List.filled(ids.length, '?').join(',')})', whereArgs: ids);
  }

  // ---------- customers ----------
  Customer _customer(Map<String, Object?> r) => Customer(
      id: r['id'] as String,
      name: r['name'] as String,
      contactInfo: r['contact_info'] as String,
      updatedAt: _dt(r['updated_at']));

  Stream<List<Customer>> watchCustomers() => _watch(() async {
        final rows = await (await _d).query('customers', orderBy: 'name COLLATE NOCASE');
        return rows.map(_customer).toList();
      });

  Stream<Customer?> watchCustomer(String id) => _watch(() => getCustomer(id));

  Future<Customer?> getCustomer(String id) async {
    final r = await (await _d).query('customers', where: 'id = ?', whereArgs: [id]);
    return r.isEmpty ? null : _customer(r.first);
  }

  Future<void> saveCustomer(Customer c, {required bool queue}) => _save(
      'customers',
      'customer',
      c.id,
      {'id': c.id, 'name': c.name, 'contact_info': c.contactInfo, 'updated_at': _ms(c.updatedAt)},
      queue);

  Future<void> deleteCustomer(String id, {required bool queue}) async {
    final d = await _d;
    final files = <String>[];
    await d.transaction((t) async {
      final siteIds = (await t.query('sites', columns: ['id'], where: 'customer_id = ?', whereArgs: [id]))
          .map((r) => r['id'] as String)
          .toList();
      final noteIds = <String>[];
      if (siteIds.isNotEmpty) {
        final rows = await t.rawQuery(
            'SELECT id, photo_path FROM field_notes WHERE site_id IN (${List.filled(siteIds.length, '?').join(',')})',
            siteIds);
        for (final r in rows) {
          noteIds.add(r['id'] as String);
          if (r['photo_path'] != null) files.add(r['photo_path'] as String);
        }
      }
      await _clearOutbox(t, [id, ...siteIds, ...noteIds]);
      await t.delete('customers', where: 'id = ?', whereArgs: [id]); // cascades to sites + notes
      if (queue) await _enqueue(t, 'customer', id, 'delete');
    });
    _deleteFiles(files);
    _notify(queue);
  }

  // ---------- sites ----------
  static const _siteSelect = 'SELECT s.*, c.name AS customer_name FROM sites s JOIN customers c ON c.id = s.customer_id';

  Site _site(Map<String, Object?> r) => Site(
      id: r['id'] as String,
      customerId: r['customer_id'] as String,
      customerName: r['customer_name'] as String,
      name: r['name'] as String,
      address: r['address'] as String,
      updatedAt: _dt(r['updated_at']));

  Stream<List<Site>> watchSites({String? customerId}) => _watch(() async {
        final rows = await (await _d).rawQuery(
            '$_siteSelect ${customerId == null ? '' : 'WHERE s.customer_id = ?'} ORDER BY s.name COLLATE NOCASE',
            customerId == null ? <Object?>[] : <Object?>[customerId]);
        return rows.map(_site).toList();
      });

  Stream<Site?> watchSite(String id) => _watch(() => getSite(id));

  Future<Site?> getSite(String id) async {
    final r = await (await _d).rawQuery('$_siteSelect WHERE s.id = ?', [id]);
    return r.isEmpty ? null : _site(r.first);
  }

  Future<void> saveSite(Site s, {required bool queue}) => _save(
      'sites',
      'site',
      s.id,
      {
        'id': s.id,
        'customer_id': s.customerId,
        'name': s.name,
        'address': s.address,
        'updated_at': _ms(s.updatedAt)
      },
      queue);

  Future<void> deleteSite(String id, {required bool queue}) async {
    final d = await _d;
    final files = <String>[];
    await d.transaction((t) async {
      final rows = await t.query('field_notes', columns: ['id', 'photo_path'], where: 'site_id = ?', whereArgs: [id]);
      for (final r in rows) {
        if (r['photo_path'] != null) files.add(r['photo_path'] as String);
      }
      await _clearOutbox(t, [id, ...rows.map((r) => r['id'] as String)]);
      await t.delete('sites', where: 'id = ?', whereArgs: [id]);
      if (queue) await _enqueue(t, 'site', id, 'delete');
    });
    _deleteFiles(files);
    _notify(queue);
  }

  // ---------- notes ----------
  static const _noteSelect = '''SELECT n.*, s.name AS site_name, s.customer_id AS customer_id, c.name AS customer_name
      FROM field_notes n JOIN sites s ON s.id = n.site_id JOIN customers c ON c.id = s.customer_id''';

  FieldNote _note(Map<String, Object?> r) => FieldNote(
        id: r['id'] as String,
        siteId: r['site_id'] as String,
        siteName: r['site_name'] as String,
        customerId: r['customer_id'] as String,
        customerName: r['customer_name'] as String,
        title: r['title'] as String,
        description: r['description'] as String,
        latitude: r['latitude'] as double?,
        longitude: r['longitude'] as double?,
        dateTime: _dt(r['note_date_time']),
        status: NoteStatus.fromApi(r['status'] as String?),
        photoPath: r['photo_path'] as String?,
        photoUrl: r['photo_url'] as String?,
        updatedAt: _dt(r['updated_at']),
      );

  Future<List<FieldNote>> queryNotes(NotesFilter f) async {
    final where = <String>[];
    final args = <Object?>[];
    if (f.status != null) {
      where.add('n.status = ?');
      args.add(f.status!.apiValue);
    }
    if (f.siteId != null) {
      where.add('n.site_id = ?');
      args.add(f.siteId);
    }
    final q = f.query.trim().toLowerCase();
    if (q.isNotEmpty) {
      where.add('(LOWER(n.title) LIKE ? OR LOWER(n.description) LIKE ? OR LOWER(s.name) LIKE ? OR LOWER(c.name) LIKE ?)');
      args.addAll(List.filled(4, '%$q%'));
    }
    final rows = await (await _d).rawQuery(
        '$_noteSelect ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'} ORDER BY n.note_date_time DESC', args);
    return rows.map(_note).toList();
  }

  Stream<List<FieldNote>> watchNotes(NotesFilter f) => _watch(() => queryNotes(f));
  Stream<FieldNote?> watchNote(String id) => _watch(() => getNote(id));

  Future<FieldNote?> getNote(String id) async {
    final r = await (await _d).rawQuery('$_noteSelect WHERE n.id = ?', [id]);
    return r.isEmpty ? null : _note(r.first);
  }

  /// [queue] = user edit (adds outbox ops). [withPhotoUrl] = write the server photo url too (remote apply).
  Future<void> saveNote(FieldNote n, {required bool queue, bool withPhotoUrl = false, bool queuePhoto = false}) {
    final row = <String, Object?>{
      'id': n.id,
      'site_id': n.siteId,
      'title': n.title,
      'description': n.description,
      'latitude': n.latitude,
      'longitude': n.longitude,
      'note_date_time': _ms(n.dateTime),
      'status': n.status.apiValue,
      'photo_path': n.photoPath,
      'updated_at': _ms(n.updatedAt),
    };
    if (withPhotoUrl) row['photo_url'] = n.photoUrl;
    return _save('field_notes', 'note', n.id, row, queue, extraOps: queuePhoto ? ['photo'] : const []);
  }

  Future<void> deleteNote(String id, {required bool queue}) async {
    final d = await _d;
    String? file;
    await d.transaction((t) async {
      final r = await t.query('field_notes', columns: ['photo_path'], where: 'id = ?', whereArgs: [id]);
      if (r.isNotEmpty) file = r.first['photo_path'] as String?;
      await _clearOutbox(t, [id]);
      await t.delete('field_notes', where: 'id = ?', whereArgs: [id]);
      if (queue) await _enqueue(t, 'note', id, 'delete');
    });
    if (file != null) _deleteFiles([file!]);
    _notify(queue);
  }

  /// Update photo columns without touching updatedAt or the outbox (sync bookkeeping).
  Future<void> setNotePhoto(String id, {String? path, String? url}) async {
    final values = <String, Object?>{};
    if (path != null) values['photo_path'] = path;
    if (url != null) values['photo_url'] = url;
    if (values.isEmpty) return;
    await (await _d).update('field_notes', values, where: 'id = ?', whereArgs: [id]);
    _notify(false);
  }

  Future<List<({String id, String url})>> notesNeedingPhoto() async {
    final rows = await (await _d).query('field_notes',
        columns: ['id', 'photo_url'], where: 'photo_url IS NOT NULL AND photo_path IS NULL');
    return rows.map((r) => (id: r['id'] as String, url: r['photo_url'] as String)).toList();
  }

  // ---------- outbox ----------
  Future<List<OutboxOp>> pendingOps() async {
    final rows = await (await _d).query('outbox', orderBy: 'seq');
    return rows
        .map((r) => OutboxOp(r['seq'] as int, r['entity_type'] as String, r['entity_id'] as String,
            r['op'] as String, r['ver'] as int))
        .toList();
  }

  /// Removes the op only if it was not re-queued (edited again) while it was being sent.
  Future<void> completeOp(OutboxOp op) async {
    await (await _d).delete('outbox', where: 'seq = ? AND ver = ?', whereArgs: [op.seq, op.ver]);
    _changes.add(null);
  }

  Future<void> dropOp(OutboxOp op) async {
    await (await _d).delete('outbox', where: 'seq = ?', whereArgs: [op.seq]);
    _changes.add(null);
  }

  Future<bool> hasPending(String entityId) async {
    final r = await (await _d).query('outbox', columns: ['seq'], where: 'entity_id = ?', whereArgs: [entityId], limit: 1);
    return r.isNotEmpty;
  }

  Future<bool> hasPendingOp(String entityId, String op) async {
    final r = await (await _d).query('outbox',
        columns: ['seq'], where: 'entity_id = ? AND op = ?', whereArgs: [entityId, op], limit: 1);
    return r.isNotEmpty;
  }

  Stream<int> watchPendingCount() => _watch(() async {
        final r = await (await _d).rawQuery('SELECT COUNT(*) AS c FROM outbox');
        return Sqflite.firstIntValue(r) ?? 0;
      });

  Future<void> wipe() async {
    final d = await _d;
    await d.transaction((t) async {
      await t.delete('outbox');
      await t.delete('field_notes');
      await t.delete('sites');
      await t.delete('customers');
    });
    _notify(false);
  }

  void _deleteFiles(List<String> paths) {
    if (kIsWeb) return;
    for (final path in paths) {
      File(path).delete().catchError((_) => File(path));
    }
  }
}
