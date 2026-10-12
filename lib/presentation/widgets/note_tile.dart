import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities.dart';
import 'status_chip.dart';
import 'stored_photo.dart';

final noteDateFormat = DateFormat('d MMM, h:mm a');

class NoteTile extends StatelessWidget {
  const NoteTile(
      {super.key,
      required this.note,
      required this.onTap,
      this.showSite = true});
  final FieldNote note;
  final VoidCallback onTap;
  final bool showSite;

  @override
  Widget build(BuildContext context) {
    final path = note.photoPath;
    final gradients = <List<Color>>[
      const [Color(0xFF5B6670), Color(0xFF262C33)],
      const [Color(0xFFD3C5A8), Color(0xFF8F8266)],
      const [Color(0xFF86999E), Color(0xFF3C4B5C)],
      const [Color(0xFF9DAA82), Color(0xFF56633F)],
    ];
    final gradient = gradients[note.id.hashCode.abs() % gradients.length];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: path != null
                      ? StoredPhoto(
                          path: path,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image))
                      : DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(Icons.photo_outlined,
                              color: Colors.white70, size: 26),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFF15181C),
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    if (showSite) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined,
                              size: 13, color: Color(0xFF69737C)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(note.siteName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Color(0xFF15181C),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ),
                          if (note.customerName.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(note.customerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Color(0xFFA5ADB4), fontSize: 12)),
                            ),
                          ],
                        ],
                      ),
                    ],
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        StatusChip(note.status),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _relativeDate(note.dateTime),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Color(0xFFA5ADB4), fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  size: 20, color: Color(0xFFA5ADB4)),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeDate(DateTime value) {
    final date = value.toLocal();
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return DateFormat('Today, h:mm a').format(date);
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return DateFormat('Yesterday, h:mm a').format(date);
    }
    return noteDateFormat.format(date);
  }
}
