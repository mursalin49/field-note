import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class PhotoStorage {
  Future<Directory> _dir() async {
    final d = Directory(
        p.join((await getApplicationDocumentsDirectory()).path, 'photos'));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  Future<Directory> _profileDir() async {
    final d = Directory(p.join(
        (await getApplicationDocumentsDirectory()).path, 'profile_photos'));
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  /// Copies a picked/captured image into app storage (camera temp files can be purged).
  Future<String> persist(String sourcePath) async {
    final dir = await _dir();
    final ext =
        p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
    final dest = p.join(dir.path, '${const Uuid().v4()}$ext');
    await File(sourcePath).copy(dest);
    return dest;
  }

  /// Keeps profile photos separate so logging out does not remove them.
  Future<String> persistProfile(String sourcePath) async {
    final dir = await _profileDir();
    final ext =
        p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
    final dest = p.join(dir.path, '${const Uuid().v4()}$ext');
    await File(sourcePath).copy(dest);
    return dest;
  }

  Future<String> persistBytes(Uint8List bytes,
      {String mimeType = 'image/jpeg'}) async {
    if (kIsWeb) {
      return 'data:$mimeType;base64,${base64Encode(bytes)}';
    }
    final extension = switch (mimeType) {
      'image/png' => '.png',
      'image/webp' => '.webp',
      _ => '.jpg',
    };
    final dir = await _dir();
    final dest = p.join(dir.path, '${const Uuid().v4()}$extension');
    await File(dest).writeAsBytes(bytes, flush: true);
    return dest;
  }

  Future<Uint8List?> readBytes(String path) async {
    if (kIsWeb) {
      if (!path.startsWith('data:') || !path.contains(';base64,')) return null;
      return base64Decode(path.substring(path.indexOf(';base64,') + 8));
    }
    final file = File(path);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  static Uint8List decodeDataUrl(String dataUrl) =>
      base64Decode(dataUrl.substring(dataUrl.indexOf(';base64,') + 8));

  static String mimeTypeFromPath(String path) {
    if (path.startsWith('data:')) return path.substring(5, path.indexOf(';'));
    final extension = p.extension(path).toLowerCase();
    if (extension == '.png') return 'image/png';
    if (extension == '.webp') return 'image/webp';
    return 'image/jpeg';
  }

  Future<String> pathForDownload(String noteId, String url) async {
    final dir = await _dir();
    final ext = p.extension(url).isEmpty ? '.jpg' : p.extension(url);
    return p.join(
        dir.path, '$noteId-${DateTime.now().millisecondsSinceEpoch}$ext');
  }

  Future<void> deleteAll() async {
    // Browser photo storage is not backed by dart:io; SQLite web data is wiped separately.
    if (kIsWeb) return;
    final d = await _dir();
    if (await d.exists()) await d.delete(recursive: true);
  }
}
