import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/di.dart';
import '../../core/permissions.dart';
import '../../data/local/profile_photo_store.dart';
import '../../domain/entities.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/settings_cubit.dart';
import '../blocs/sync_cubit.dart';
import '../widgets/dialogs.dart';
import '../widgets/status_chip.dart';
import '../widgets/stored_photo.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, auth) => ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          children: [
            Text('Settings',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF15181C),
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    )),
            const SizedBox(height: 18),
            _ProfileCard(key: ValueKey(auth.user?.id), user: auth.user),
            const SizedBox(height: 24),
            _sectionLabel('Preferences'),
            const SizedBox(height: 10),
            BlocBuilder<SettingsCubit, NoteStatus>(
              builder: (context, status) => Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Default note status',
                          style: TextStyle(
                              color: Color(0xFF15181C),
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      const SizedBox(height: 4),
                      const Text('Applied when you create a new note',
                          style: TextStyle(
                              color: Color(0xFF69737C), fontSize: 12)),
                      const SizedBox(height: 10),
                      for (final option in NoteStatus.values)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: option == status
                                ? const Color(0xFFFFEDE4)
                                : const Color(0xFFF2F3F1),
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => context
                                  .read<SettingsCubit>()
                                  .setDefaultStatus(option),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                child: Row(
                                  children: [
                                    StatusChip(option),
                                    const Spacer(),
                                    Icon(
                                      option == status
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      size: 20,
                                      color: option == status
                                          ? const Color(0xFFFF5A1F)
                                          : const Color(0xFFE2E5E3),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Saved on this device only. Not synced to the server.',
                style: TextStyle(color: Color(0xFF69737C), fontSize: 12),
              ),
            ),
            const SizedBox(height: 24),
            _sectionLabel('Sync'),
            const SizedBox(height: 10),
            BlocBuilder<SyncCubit, SyncState>(
              builder: (context, sync) {
                final last = sync.lastSync == null
                    ? 'Never'
                    : DateFormat('d MMM, h:mm a')
                        .format(sync.lastSync!.toLocal());
                return Card(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text('Auto-sync when online',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                            ),
                            const Icon(
                              Icons.toggle_on_rounded,
                              size: 36,
                              color: Color(0xFF1B2026),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        dense: true,
                        title: const Text('Last synced'),
                        trailing: Text(last,
                            style: const TextStyle(
                                color: Color(0xFF69737C), fontSize: 13)),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        dense: true,
                        leading:
                            const Icon(Icons.sync, color: Color(0xFFD9430D)),
                        title: Text(sync.syncing
                            ? 'Syncing…'
                            : sync.pending > 0
                                ? 'Sync now · ${sync.pending} pending'
                                : 'Sync now'),
                        titleTextStyle: const TextStyle(
                            color: Color(0xFFD9430D),
                            fontWeight: FontWeight.w700,
                            fontSize: 15),
                        onTap: sync.syncing
                            ? null
                            : () => context.read<SyncCubit>().sync(),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout, color: Color(0xFFC9301C)),
              label: const Text('Log out',
                  style: TextStyle(
                      color: Color(0xFFC9301C),
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final pending = context.read<SyncCubit>().state.pending;
    final auth = context.read<AuthBloc>();
    final ok = await confirmDialog(
      context,
      title: 'Log out?',
      message: pending > 0
          ? '$pending change(s) have not been synced yet and will be LOST. Connect to the internet and sync first.'
          : 'Local data will be removed from this device. You can log in again to restore it from the server.',
      action: 'Log out',
    );
    if (ok) auth.add(AuthLogoutRequested());
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(
          color: Color(0xFF69737C), fontSize: 13, fontWeight: FontWeight.w700));

}

enum _ProfilePhotoAction { camera, gallery, remove }

class _ProfileCard extends StatefulWidget {
  const _ProfileCard({super.key, required this.user});

  final AppUser? user;

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  final _picker = ImagePicker();
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  void _loadPhoto() {
    final user = widget.user;
    _photoPath =
        user == null ? null : getIt<ProfilePhotoStore>().photoPath(user.id);
  }

  Future<void> _editPhoto() async {
    final user = widget.user;
    if (user == null) return;
    final action = await showModalBottomSheet<_ProfilePhotoAction>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, _ProfilePhotoAction.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, _ProfilePhotoAction.gallery),
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remove photo'),
                onTap: () => Navigator.pop(context, _ProfilePhotoAction.remove),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == _ProfilePhotoAction.remove) {
      await _removePhoto(user.id);
      return;
    }

    final source = action == _ProfilePhotoAction.camera
        ? ImageSource.camera
        : ImageSource.gallery;
    try {
      if (source == ImageSource.camera && !kIsWeb) {
        await DeviceServices.ensureCamera();
      }
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked == null) return;

      await getIt<ProfilePhotoStore>().upload(
        user.id,
        await picked.readAsBytes(),
        filename: picked.name.isEmpty ? 'profile.jpg' : picked.name,
      );
      if (mounted) {
        setState(
            () => _photoPath = getIt<ProfilePhotoStore>().photoPath(user.id));
      }
    } on DeviceFailure catch (failure) {
      if (mounted) {
        showSnack(context, failure.message,
            actionLabel: failure.open == null ? null : 'Settings',
            onAction: failure.open == null ? null : () => failure.open!());
      }
    } catch (_) {
      if (mounted) {
        showSnack(context, 'Could not update profile photo. Please try again.');
      }
    }
  }

  Future<void> _removePhoto(int userId) async {
    try {
      await getIt<ProfilePhotoStore>().remove(userId);
      if (mounted) setState(() => _photoPath = null);
    } catch (_) {
      if (mounted) showSnack(context, 'Could not remove profile photo.');
    }
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    final initials = parts.take(2).map((part) => part[0].toUpperCase()).join();
    return initials.isEmpty ? 'FN' : initials;
  }

  Widget _photoFallback(String name) => Container(
        color: const Color(0xFF1B2026),
        alignment: Alignment.center,
        child: Text(_initials(name),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
      );

  @override
  Widget build(BuildContext context) {
    final name = widget.user?.name ?? '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Semantics(
              button: true,
              label: 'Change profile photo',
              child: InkWell(
                onTap: _editPhoto,
                customBorder: const CircleBorder(),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFF1B2026),
                      foregroundColor: Colors.white,
                      child: _photoPath == null
                          ? Text(_initials(name),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700))
                          : ClipOval(
                              child: SizedBox(
                                width: 60,
                                height: 60,
                                child: StoredPhoto(
                                  path: _photoPath!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _photoFallback(name),
                                ),
                              ),
                            ),
                    ),
                    const Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 11,
                        backgroundColor: Color(0xFFFF5A1F),
                        child: Icon(Icons.edit, size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 3),
                  Text(widget.user?.email ?? '',
                      style: const TextStyle(
                          color: Color(0xFF69737C), fontSize: 12)),
                  const SizedBox(height: 4),
                  const Text('Profile photo syncs across your devices',
                      style:
                          TextStyle(color: Color(0xFF69737C), fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
