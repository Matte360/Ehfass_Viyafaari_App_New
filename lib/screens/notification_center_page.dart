import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/business.dart';
import '../services/marketplace_service.dart';
import 'chat_list_page.dart';
import 'client_orders_page.dart';
import 'quotation_requests_page.dart';

class NotificationCenterPage extends StatelessWidget {
  const NotificationCenterPage({
    super.key,
    required this.currentUser,
    required this.isDhivehi,
    this.business,
  });

  final AppUser currentUser;
  final bool isDhivehi;
  final Business? business;

  bool get _businessMode => business != null;

  String text(String english, String dhivehi) {
    return isDhivehi ? dhivehi : english;
  }

  TextStyle style({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return TextStyle(
      fontFamily: isDhivehi ? 'Faruma' : null,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isDhivehi ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            text('Notifications', 'ނޮޓިފިކޭޝަން'),
            style: style(fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => MarketplaceService.instance
                  .markAllNotificationsRead(currentUser.uid),
              icon: const Icon(Icons.done_all_rounded),
              label: Text(text('Read all', 'ހުރިހާ ކިޔާ'), style: style()),
            ),
          ],
        ),
        body: StreamBuilder<List<AppNotification>>(
          stream: MarketplaceService.instance
              .watchNotificationsForUser(currentUser.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }

            final notifications = snapshot.data ?? const <AppNotification>[];
            if (notifications.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(26),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notifications_none_rounded, size: 76),
                      const SizedBox(height: 12),
                      Text(
                        text(
                          'No notifications yet.',
                          'އަދި ނޮޓިފިކޭޝަނެއް ނެތް.',
                        ),
                        textAlign: TextAlign.center,
                        style: style(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _notificationTile(
                context,
                notifications[index],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _notificationTile(BuildContext context, AppNotification notification) {
    return Card(
      color: notification.read
          ? null
          : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(_iconFor(notification.type)),
        ),
        title: Text(
          notification.title.isEmpty
              ? text('Notification', 'ނޮޓިފިކޭޝަން')
              : notification.title,
          style: style(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          notification.body,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: style(height: 1.35),
        ),
        trailing: notification.read
            ? null
            : Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () async {
          await MarketplaceService.instance.markNotificationRead(notification);
          if (!context.mounted) return;
          _openRelatedPage(context, notification);
        },
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'chat_message':
        return Icons.chat_rounded;
      case 'quote_new':
      case 'quote_status':
        return Icons.request_quote_rounded;
      case 'review_new':
        return Icons.star_rounded;
      case 'order_new':
      case 'order_status':
        return Icons.receipt_long_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  void _openRelatedPage(BuildContext context, AppNotification notification) {
    if (notification.type == 'chat_message') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatListPage(
            currentUser: currentUser,
            business: business,
            isDhivehi: isDhivehi,
          ),
        ),
      );
      return;
    }

    if (_businessMode && notification.type.startsWith('quote')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuotationRequestsPage(
            business: business!,
            isDhivehi: isDhivehi,
          ),
        ),
      );
      return;
    }

    if (!_businessMode) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClientOrdersPage(
            client: currentUser,
            isDhivehi: isDhivehi,
          ),
        ),
      );
    }
  }
}
