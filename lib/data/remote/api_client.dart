import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../core/config.dart';
import '../../domain/repositories.dart';
import '../session_store.dart';

class ApiClient {
  ApiClient(this._session)
      : _dio = Dio(BaseOptions(
          baseUrl: AppConfig.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (o, h) async {
        final t = await _session.token;
        if (t != null) o.headers['Authorization'] = 'Bearer $t';
        h.next(o);
      },
      onError: (e, h) {
        if (e.response?.statusCode == 401 &&
            !e.requestOptions.path.startsWith('/api/auth')) {
          _unauthorized.add(null);
        }
        h.next(e);
      },
    ));
  }

  final Dio _dio;
  final SessionStore _session;
  final _unauthorized = StreamController<void>.broadcast();
  Stream<void> get unauthorized => _unauthorized.stream;

  Future<T> _call<T>(Future<Response<dynamic>> Function() fn,
      T Function(dynamic data) map) async {
    try {
      return map((await fn()).data);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      var msg = status == null
          ? 'No connection to the server'
          : 'Request failed ($status)';
      if (data is Map && data['error'] is String) msg = data['error'] as String;
      throw ApiException(msg, statusCode: status);
    }
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) =>
      _call(
          () => _dio.post(path, data: body), (d) => d as Map<String, dynamic>);

  Future<Map<String, dynamic>> get(String path,
          {Map<String, dynamic>? query}) =>
      _call(() => _dio.get(path, queryParameters: query),
          (d) => d as Map<String, dynamic>);

  Future<void> put(String path, Map<String, dynamic> body) =>
      _call(() => _dio.put(path, data: body), (_) {});

  Future<void> delete(String path) => _call(() => _dio.delete(path), (_) {});

  Future<Map<String, dynamic>> uploadPhoto(String noteId, Uint8List bytes,
          {String filename = 'photo.jpg'}) =>
      _call(() async {
        final form = FormData.fromMap(
            {'file': MultipartFile.fromBytes(bytes, filename: filename)});
        return _dio.post('/api/notes/$noteId/photo', data: form);
      }, (d) => d as Map<String, dynamic>);

  Future<void> download(String urlPath, String savePath) =>
      _call(() => _dio.download(urlPath, savePath), (_) {});

  Future<Uint8List> downloadBytes(String urlPath) => _call(
        () => _dio.get<List<int>>(urlPath,
            options: Options(responseType: ResponseType.bytes)),
        (data) => Uint8List.fromList(List<int>.from(data as List)),
      );
}
