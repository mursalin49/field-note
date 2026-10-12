import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// A user-facing permission problem. [open] (if set) jumps to the right system settings screen.
class DeviceFailure implements Exception {
  DeviceFailure(this.message, {this.open});
  final String message;
  final Future<void> Function()? open;
}

class DeviceServices {
  static Future<Position> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw DeviceFailure('Location services are turned off.', open: () async { await Geolocator.openLocationSettings(); });
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied) {
      throw DeviceFailure('Location permission was denied.');
    }
    if (perm == LocationPermission.deniedForever) {
      throw DeviceFailure('Location permission is permanently denied. Enable it in app settings.',
          open: () async { await openAppSettings(); });
    }
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 15),
    );
  }

  static Future<void> ensureCamera() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) status = await Permission.camera.request();
    if (status.isGranted || status.isLimited) return;
    if (status.isPermanentlyDenied || status.isRestricted) {
      throw DeviceFailure('Camera permission is permanently denied. Enable it in app settings.',
          open: () async { await openAppSettings(); });
    }
    throw DeviceFailure('Camera permission was denied.');
  }
}
