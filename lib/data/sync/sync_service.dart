import '../../domain/entities.dart';
import '../../domain/repositories.dart';
import '../local/local_db.dart';
import '../local/photo_storage.dart';
import '../remote/api_client.dart';
import '../remote/mappers.dart';
import '../session_store.dart';

/// Outbox pattern:
///  1. PUSH  - replay queued local changes in order (idempotent PUT/DELETE by client UUID).
///  2. PULL  - GET /api/sync/pull?since=<cursor>, apply server changes (last-write-wins).
///  3. Download photos that exist on the server but not on this device.
class SyncService {
  SyncService(this._db, this._api, this._session, this._photos);
  final LocalDb _db;
  final ApiClient _api;
  final SessionStore _session;
  final PhotoStorage _photos;
  bool _running = false;

  Future<void> sync() async {
    if (_running) return;
    _running = true;
    try {
      await _push();
      await _pull();
      await _downloadPhotos();
    } finally {
      _running = false;
    }
  }

  // ---------------- push ----------------
  Future<void> _push() async {
    for (final op in await _db.pendingOps()) {
      try {
        await _send(op);
        await _db.completeOp(op);
      } on ApiException {
        // Keep every failed operation queued until it is fixed and successfully sent.
        rethrow;
      }
    }
  }

  Future<void> _send(OutboxOp op) async {
    final id = op.entityId;
    switch ('${op.type}:${op.op}') {
      case 'customer:upsert':
        final c = await _db.getCustomer(id);
        if (c != null) await _api.put('/api/customers/$id', customerToJson(c));
      case 'site:upsert':
        final s = await _db.getSite(id);
        if (s != null) await _api.put('/api/sites/$id', siteToJson(s));
      case 'note:upsert':
        final n = await _db.getNote(id);
        if (n != null) await _api.put('/api/notes/$id', noteToJson(n));
      case 'note:photo':
        final n = await _db.getNote(id);
        final path = n?.photoPath;
        if (path != null) {
          final bytes = await _photos.readBytes(path);
          if (bytes == null) {
            throw ApiException(
              'The selected photo is unavailable. Choose it again.',
              statusCode: 422,
            );
          }
          final extension = switch (PhotoStorage.mimeTypeFromPath(path)) {
            'image/png' => 'png',
            'image/webp' => 'webp',
            _ => 'jpg',
          };
          final r = await _api.uploadPhoto(id, bytes,
              filename: 'note-$id.$extension');
          await _db.setNotePhoto(id, url: r['photoUrl'] as String?);
        }
      case 'customer:delete':
        await _api.delete('/api/customers/$id');
      case 'site:delete':
        await _api.delete('/api/sites/$id');
      case 'note:delete':
        await _api.delete('/api/notes/$id');
    }
  }

  // ---------------- pull ----------------
  Future<void> _pull() async {
    final since = _session.lastSyncIso ?? '1970-01-01T00:00:00.000Z';
    final r = await _api.get('/api/sync/pull', query: {'since': since});
    final serverTime = DateTime.parse(r['serverTime'] as String).toUtc();

    List<Map<String, dynamic>> list(String k) =>
        (r[k] as List).cast<Map<String, dynamic>>();

    // parents first (foreign keys)
    for (final j in list('customers')) {
      await _applyCustomer(j);
    }
    for (final j in list('sites')) {
      await _applySite(j);
    }
    for (final j in list('notes')) {
      await _applyNote(j);
    }
    // small overlap so rows committed around the cursor are never missed (applying twice is harmless)
    await _session
        .setLastSync(serverTime.subtract(const Duration(seconds: 10)));
  }

  Future<void> _applyCustomer(Map<String, dynamic> j) async {
    final c = customerFromJson(j);
    if (await _db.hasPending(c.id)) return; // local unsynced edit wins for now
    if (j['deleted'] == true) return _db.deleteCustomer(c.id, queue: false);
    final local = await _db.getCustomer(c.id);
    if (local == null || !c.updatedAt.isBefore(local.updatedAt)) {
      await _db.saveCustomer(c, queue: false);
    }
  }

  Future<void> _applySite(Map<String, dynamic> j) async {
    final s = siteFromJson(j);
    if (await _db.hasPending(s.id)) return;
    if (j['deleted'] == true) return _db.deleteSite(s.id, queue: false);
    final local = await _db.getSite(s.id);
    if (local == null || !s.updatedAt.isBefore(local.updatedAt)) {
      if (await _db.getCustomer(s.customerId) == null) {
        return; // parent missing locally
      }
      await _db.saveSite(s, queue: false);
    }
  }

  Future<void> _applyNote(Map<String, dynamic> j) async {
    final n = noteFromJson(j);
    if (await _db.hasPending(n.id)) return;
    if (j['deleted'] == true) return _db.deleteNote(n.id, queue: false);
    final local = await _db.getNote(n.id);
    if (local != null && n.updatedAt.isBefore(local.updatedAt)) return;
    if (await _db.getSite(n.siteId) == null) return;
    // keep the local photo file unless the server has a different photo now
    final keepPhoto = local != null && local.photoUrl == n.photoUrl;
    final merged = FieldNote(
      id: n.id,
      siteId: n.siteId,
      title: n.title,
      description: n.description,
      latitude: n.latitude,
      longitude: n.longitude,
      dateTime: n.dateTime,
      status: n.status,
      photoPath: keepPhoto ? local.photoPath : null,
      photoUrl: n.photoUrl,
      updatedAt: n.updatedAt,
    );
    await _db.saveNote(merged, queue: false, withPhotoUrl: true);
  }

  // ---------------- photos ----------------
  Future<void> _downloadPhotos() async {
    for (final item in await _db.notesNeedingPhoto()) {
      if (await _db.hasPendingOp(item.id, 'photo')) continue;
      try {
        final bytes = await _api.downloadBytes(item.url);
        final path =
            await _photos.persistBytes(bytes, mimeType: _mimeType(item.url));
        await _db.setNotePhoto(item.id, path: path);
      } catch (_) {
        // not fatal; tried again on the next sync
      }
    }
  }

  String _mimeType(String url) {
    final clean = url.split('?').first.toLowerCase();
    if (clean.endsWith('.png')) return 'image/png';
    if (clean.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
