import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/business.dart';
import '../models/chat_thread.dart';
import '../services/marketplace_service.dart';
import 'chat_page.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({
    super.key,
    required this.currentUser,
    required this.isDhivehi,
    this.business,
    this.showAppBar = true,
  });

  final AppUser currentUser;
  final bool isDhivehi;
  final Business? business;
  final bool showAppBar;

  bool get _businessMode => business != null;

  String text(String english, String dhivehi) {
    return isDhivehi ? dhivehi : english;
  }

  TextStyle style({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: isDhivehi ? 'Faruma' : null,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final stream = _businessMode
        ? MarketplaceService.instance.watchChatsForBusiness(business!.id)
        : MarketplaceService.instance.watchChatsForClient(currentUser.uid);

    return Directionality(
      textDirection: isDhivehi ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: showAppBar
            ? AppBar(
                title: Text(
                  text('Messages', 'މެސެޖްތައް'),
                  style: style(fontWeight: FontWeight.bold),
                ),
              )
            : null,
        body: StreamBuilder<List<ChatThread>>(
          stream: stream,
          builder: (context, snapshot) {
            final threads = snapshot.data ?? const <ChatThread>[];
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            if (threads.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(26),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.mark_chat_unread_outlined, size: 68),
                      const SizedBox(height: 12),
                      Text(
                        text(
                          'No chat messages yet.',
                          'އަދި ޗެޓް މެސެޖެއް ނެތް.',
                        ),
                        textAlign: TextAlign.center,
                        style: style(fontSize: 17),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: threads.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final thread = threads[index];
                final unread = _businessMode
                    ? thread.unreadForBusiness
                    : thread.unreadForClient;
                final title = _businessMode
                    ? thread.clientName
                    : thread.businessName;

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(
                        unread
                            ? Icons.mark_chat_unread_rounded
                            : Icons.chat_bubble_rounded,
                      ),
                    ),
                    title: Text(
                      title.isEmpty ? text('Unknown', 'ނޭނގޭ') : title,
                      style: style(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(
                      [
                        if (thread.itemName.isNotEmpty) thread.itemName,
                        if (thread.lastMessage.isNotEmpty) thread.lastMessage,
                      ].join('\n'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: style(),
                    ),
                    isThreeLine: thread.itemName.isNotEmpty,
                    trailing: unread
                        ? Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            currentUser: currentUser,
                            isDhivehi: isDhivehi,
                            thread: thread,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
