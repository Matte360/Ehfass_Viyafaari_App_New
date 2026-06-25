import 'package:flutter/material.dart';

import 'compact_app_icon_button.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({
    super.key,
    required this.countStream,
    required this.tooltip,
    required this.onPressed,
    this.icon = Icons.notifications_rounded,
  });

  final Stream<int> countStream;
  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: countStream,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return CompactAppIconButton(
          icon: icon,
          tooltip: tooltip,
          onPressed: onPressed,
          badgeCount: count,
        );
      },
    );
  }
}
