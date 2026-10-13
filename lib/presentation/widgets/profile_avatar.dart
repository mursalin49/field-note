import 'package:flutter/material.dart';

import '../../core/di.dart';
import '../../data/local/profile_photo_store.dart';
import 'dialogs.dart';
import 'stored_photo.dart';

class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    required this.userId,
    required this.radius,
  });

  final String name;
  final int? userId;
  final double radius;

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  String _initials() {
    final parts =
        widget.name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    final initials = parts.take(2).map((part) => part[0].toUpperCase()).join();
    return initials.isEmpty ? 'FN' : initials;
  }

  @override
  void initState() {
    super.initState();
    _synchronize();
  }

  @override
  void didUpdateWidget(covariant ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) _synchronize();
  }

  Future<void> _synchronize() async {
    final userId = widget.userId;
    if (userId == null) return;
    try {
      await getIt<ProfilePhotoStore>().synchronize(userId);
    } catch (_) {
      if (mounted) {
        showSnack(context,
            'Could not sync your profile photo. You can retry in Settings.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = getIt<ProfilePhotoStore>();
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final path =
            widget.userId == null ? null : store.photoPath(widget.userId!);
        return CircleAvatar(
          radius: widget.radius,
          backgroundColor: const Color(0xFF1B2026),
          foregroundColor: Colors.white,
          child: path == null
              ? Text(_initials(),
                  style: const TextStyle(fontWeight: FontWeight.w700))
              : ClipOval(
                  child: SizedBox(
                    width: widget.radius * 2,
                    height: widget.radius * 2,
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
