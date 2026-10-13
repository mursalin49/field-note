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
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 45),
          sendTimeout: const Duration(seconds: 45),
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (o, h) async {
        final token = await _session.token;
        if (token != null) o.headers['Authorization'] = 'Bearer $token';
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
      if (data is Map) {
        if (data['error'] is String) {
          msg = data['error'] as String;
        } else if (data['message'] is String) {
          msg = data['message'] as String;
        }
      } else if (data is String && data.trim().isNotEmpty) {
        msg = data.trim();
      }
      throw ApiException(msg, statusCode: status);
    }
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) =>
      _call(
          () => _dio.post(path, data: body), (d) => d as Map<String, dynamic>);

  Future<Map<String, dynamic>> register(
    Map<String, dynamic> body, {
    Uint8List? profilePhoto,
    String filename = 'profile.jpg',
  }) {
    if (profilePhoto == null) {
      return _call(
        () => _dio.post(
          '/api/auth/register',
          data: body,
          queryParameters: body,
        ),
        (data) => data as Map<String, dynamic>,
      );
    }
    final form = FormData.fromMap({
      'profilePhoto': MultipartFile.fromBytes(profilePhoto, filename: filename),
    });
    return _call(
      () => _dio.post(
        '/api/auth/register',
        data: form,
        queryParameters: body,
      ),
      (data) => data as Map<String, dynamic>,
    );
  }

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

  Future<Map<String, dynamic>> uploadProfilePhoto(Uint8List bytes,
          {String filename = 'profile.jpg'}) =>
      _call(() async {
        final form = FormData.fromMap(
            {'file': MultipartFile.fromBytes(bytes, filename: filename)});
        return _dio.post('/api/profile/photo', data: form);
      }, (data) => data as Map<String, dynamic>);

  Future<Map<String, dynamic>> getProfile() =>
      _call(() => _dio.get('/api/profile'),
          (data) => data as Map<String, dynamic>);

  Future<void> deleteProfilePhoto() =>
      _call(() => _dio.delete('/api/profile/photo'), (_) {});

  Future<void> download(String urlPath, String savePath) =>
      _call(() => _dio.download(urlPath, savePath), (_) {});

  Future<Uint8List> downloadBytes(String urlPath) => _call(
        () => _dio.get<List<int>>(urlPath,
            options: Options(responseType: ResponseType.bytes)),
        (data) => Uint8List.fromList(List<int>.from(data as List)),
      );

  Future<Uint8List> downloadProfilePhoto() => _call(
        () => _dio.get<List<int>>('/api/profile/photo',
            options: Options(responseType: ResponseType.bytes)),
        (data) => Uint8List.fromList(List<int>.from(data as List)),
      );
}
