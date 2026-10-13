class AppConfig {
  /// Override for local development: flutter run --dart-define=API_URL=http://10.0.2.2:8080
  static const _defaultBaseUrl = 'https://field-note-backend.onrender.com';
  static const _rawBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: _defaultBaseUrl,
  );

  static String get baseUrl {
    final value = _rawBaseUrl.trim();
    if (value.isEmpty) return _defaultBaseUrl;

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return value.replaceFirst(RegExp(r'/$'), '');
    }

    final path = uri.path.toLowerCase();
    final pointsToSwagger =
        path == '/swagger-ui.html' || path.startsWith('/swagger-ui');
    if (pointsToSwagger) {
      final port = uri.hasPort ? ':${uri.port}' : '';
      return '${uri.scheme}://${uri.host}$port';
    }

    return value.split('#').first.replaceFirst(RegExp(r'/$'), '');
  }

  static const syncInterval = Duration(seconds: 45);
}
