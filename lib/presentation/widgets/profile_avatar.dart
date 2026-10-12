import 'package:flutter/material.dart';

import '../../core/di.dart';
import '../../data/local/profile_photo_store.dart';
import 'stored_photo.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    required this.userId,
    required this.radius,
  });

  final String name;
  final int? userId;
  final double radius;

  String _initials() {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    final initials = parts.take(2).map((part) => part[0].toUpperCase()).join();
    return initials.isEmpty ? 'FN' : initials;
  }

  @override
  Widget build(BuildContext context) {
    final store = getIt<ProfilePhotoStore>();
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final path = userId == null ? null : store.photoPath(userId!);
        return CircleAvatar(
          radius: radius,
          backgroundColor: const Color(0xFF1B2026),
          foregroundColor: Colors.white,
          child: path == null
              ? Text(_initials(),
                  style: const TextStyle(fontWeight: FontWeight.w700))
              : ClipOval(
                  child: SizedBox(
                    width: radius * 2,
                    height: radius * 2,
                    child: StoredPhoto(
                      path: path,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => ColoredBox(
                        color: const Color(0xFF1B2026),
                        child: Center(
                          child: Text(_initials(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
