import 'package:flutter/foundation.dart';

class AppConfig {
  /// Android emulator -> host PC: http://10.0.2.2:8080
  /// iOS simulator: http://localhost:8080 | real device: http://<PC-LAN-IP>:8080
  /// Override: flutter run --dart-define=API_URL=http://192.168.0.10:8080
  static const baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080',
  );
  static const syncInterval = Duration(seconds: 45);
}
