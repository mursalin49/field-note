import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/di.dart';
import '../../domain/entities.dart';
import '../../domain/repositories.dart';
import '../blocs/notes_bloc.dart';
import '../blocs/watch_cubit.dart';
import '../widgets/dialogs.dart';
import '../widgets/stored_photo.dart';
import '../widgets/status_chip.dart';
import 'note_form_page.dart';

class NoteDetailPage extends StatelessWidget {
  const NoteDetailPage({super.key, required this.noteId});
  final String noteId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          WatchCubit<FieldNote>(getIt<NoteRepository>().watchNote(noteId)),
      child: BlocConsumer<WatchCubit<FieldNote>, WatchState<FieldNote>>(
        listener: (context, s) {
          if (s.loaded && s.value == null) {
            Navigator.of(context).maybePop(); // deleted (e.g. via sync)
          }
        },
        builder: (context, s) {
          final n = s.value;
          if (n == null) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          final theme = Theme.of(context);
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              foregroundColor: const Color(0xFF15181C),
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.92),
                  shape: const CircleBorder(),
                ),
                icon: const Icon(Icons.arrow_back),
              ),
              title: const SizedBox.shrink(),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.92),
                  ),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => NoteFormPage(note: n))),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFDECE9),
                    foregroundColor: const Color(0xFFC9301C),
                  ),
                  onPressed: () async {
                    final bloc = context.read<NotesBloc>();
                    final ok = await confirmDialog(context,
                        title: 'Delete note?',
                        message:
                            'This note will be deleted from all your devices.');
                    if (!ok || !context.mounted) return;
                    bloc.add(NoteDeleted(n.id));
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: ListView(
              padding: EdgeInsets.zero,
              children: [
                SizedBox(
                  height: 300,
                  child: n.photoPath != null
                      ? StoredPhoto(
                          path: n.photoPath!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _heroMap(n),
                        )
                      : _heroMap(n),
                ),
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF2F3F1),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          children: [
                            StatusChip(n.status),
                            _syncBadge(),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(n.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: const Color(0xFF15181C),
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            )),
                        const SizedBox(height: 14),
                        Card(
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFECEEEC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.place_outlined),
                            ),
                            title: Text(n.siteName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(n.customerName),
                            trailing: const Icon(Icons.chevron_right,
                                color: Color(0xFFA5ADB4)),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 14),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _detailMetric(
                                Icons.calendar_month_outlined,
                                'Date & time',
                                DateFormat('d MMM, h:mm a')
                                    .format(n.dateTime.toLocal()),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _detailMetric(
                                Icons.explore_outlined,
                                'Location',
                                n.hasLocation ? 'Tagged' : 'Not recorded',
                              ),
                            ),
                          ],
                        ),
                        if (n.hasLocation) ...[
                          const SizedBox(height: 12),
                          _locationMap(context, n),
                        ],
                        const SizedBox(height: 18),
                        const Text('Description',
                            style: TextStyle(
                                color: Color(0xFF69737C),
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text(
                          n.description.isEmpty
                              ? 'No description added.'
                              : n.description,
                          style: const TextStyle(
                              color: Color(0xFF15181C),
                              fontSize: 14,
                              height: 1.5),
                        ),
                        if (n.photoUrl != null && n.photoPath == null) ...[
                          const SizedBox(height: 16),
                          const Text('Photo will download when you are online.',
                              style: TextStyle(
                                  color: Color(0xFF69737C), fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _locationMap(BuildContext context, FieldNote note) {
    final point = LatLng(note.latitude!, note.longitude!);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 190,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.field_notes',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 44,
                      height: 52,
                      child: const Icon(Icons.location_pin,
                          color: Color(0xFFFF5A1F), size: 44),
                    ),
                  ],
                ),
              ],
            ),
            const Positioned(
              left: 8,
              bottom: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  child: Text('© OpenStreetMap contributors',
                      style: TextStyle(fontSize: 9)),
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: FilledButton.tonalIcon(
                onPressed: () async {
                  final url = Uri.https('www.google.com', '/maps/search/', {
                    'api': '1',
                    'query': '${point.latitude},${point.longitude}',
                  });
                  if (!await launchUrl(url,
                      mode: LaunchMode.externalApplication)) {
                    if (context.mounted) {
                      showSnack(context, 'Could not open Google Maps.');
                    }
                  }
                },
                icon: const Icon(Icons.map_outlined, size: 17),
                label: const Text('Open in Maps'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroMap(FieldNote note) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5B6670), Color(0xFF262C33)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
                child: CustomPaint(painter: _MapPreviewPainter(dark: true))),
            if (note.hasLocation)
              const Icon(Icons.location_on, size: 38, color: Color(0xFFFF5A1F))
            else
              const Icon(Icons.sticky_note_2_outlined,
                  size: 42, color: Colors.white70),
            if (note.photoPath == null && note.photoUrl == null)
              const Positioned(
                left: 24,
                bottom: 46,
                child: Text('SITE VISIT',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4)),
              ),
          ],
        ),
      );

  Widget _syncBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFDDF3E8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_done_outlined, size: 13, color: Color(0xFF0E7A4F)),
            SizedBox(width: 4),
            Text('Saved',
                style: TextStyle(
                    color: Color(0xFF0E7A4F),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _detailMetric(IconData icon, String label, String value) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, size: 16, color: const Color(0xFF69737C)),
                const SizedBox(width: 6),
                Text(label,
                    style: const TextStyle(
                        color: Color(0xFF69737C), fontSize: 11)),
              ]),
              const SizedBox(height: 8),
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Color(0xFF15181C),
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
}

class _MapPreviewPainter extends CustomPainter {
  _MapPreviewPainter({this.dark = false});
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..color = dark ? const Color(0xFF4F5A62) : const Color(0xFFE6ECE8);
    canvas.drawRect(Offset.zero & size, background);
    final road = Paint()
      ..color = dark ? Colors.white.withValues(alpha: 0.13) : Colors.white
      ..strokeWidth = dark ? 2 : 5;
    for (var i = 0; i < 4; i++) {
      final y = size.height * (0.18 + i * 0.23);
      canvas.drawLine(
          Offset(0, y), Offset(size.width, y + (i.isEven ? 8 : -8)), road);
    }
    for (var i = 0; i < 5; i++) {
      final x = size.width * (0.1 + i * 0.2);
      canvas.drawLine(
          Offset(x, 0), Offset(x + (i.isEven ? 10 : -10), size.height), road);
    }
  }

  @override
  bool shouldRepaint(covariant _MapPreviewPainter oldDelegate) =>
      oldDelegate.dark != dark;
}
