import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/sync_cubit.dart';

class SyncBanner extends StatelessWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncCubit, SyncState>(builder: (context, s) {
      String? text;
      Color color = Colors.grey.shade700;
      IconData icon = Icons.sync;
      if (!s.online) {
        text = s.pending > 0
            ? 'Offline · ${s.pending} change(s) will sync automatically'
            : 'Offline · changes are saved on this device';
        color = Colors.orange.shade800;
        icon = Icons.cloud_off;
      } else if (s.syncing) {
        text = 'Syncing…';
        color = Theme.of(context).colorScheme.primary;
      } else if (s.error != null) {
        text = 'Sync problem: ${s.error}';
        color = Colors.red.shade700;
        icon = Icons.error_outline;
      } else if (s.pending > 0) {
        text = '${s.pending} change(s) waiting to sync';
      }
      if (text == null) return const SizedBox.shrink();
      return Material(
        color: Colors.white,
        child: Container(
          decoration: BoxDecoration(
            border:
                Border(top: BorderSide(color: color.withValues(alpha: 0.15))),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          child: Row(children: [
            s.syncing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(icon, size: 16, color: color),
            const SizedBox(width: 9),
            Expanded(
                child: Text(text,
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600))),
          ]),
        ),
      );
    });
  }
}
