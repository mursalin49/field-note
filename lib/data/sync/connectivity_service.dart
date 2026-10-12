import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final _c = Connectivity();
  bool _online(List<ConnectivityResult> r) => r.any((e) => e != ConnectivityResult.none);
  Stream<bool> get onlineChanges => _c.onConnectivityChanged.map(_online);
  Future<bool> get isOnline async => _online(await _c.checkConnectivity());
}
