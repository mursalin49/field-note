import 'package:flutter/material.dart';

import '../../domain/entities.dart';

Color statusColor(NoteStatus s) => switch (s) {
      NoteStatus.draft => const Color(0xFF4B5563),
      NoteStatus.inProgress => const Color(0xFF1D5FD1),
      NoteStatus.completed => const Color(0xFF0E7A4F),
    };

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final NoteStatus status;

  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(status.label,
              style: TextStyle(
                  color: c, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
