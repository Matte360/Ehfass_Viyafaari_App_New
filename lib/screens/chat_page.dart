import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/business.dart';
import '../models/catalog_item.dart';
import '../models/chat_message.dart';
import '../models/chat_thread.dart';
import '../services/marketplace_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.currentUser,
    required this.isDhivehi,
    this.business,
    this.item,
    this.thread,
  });

  final AppUser currentUser;
  final bool isDhivehi;
  final Business? business;
  final CatalogItem? item;
  final ChatThread? thread;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  ChatThread? _thread;
  String? _threadId;
  bool _loading = true;
  bool _sending = false;

  String text(String english, String dhivehi) {
    return widget.isDhivehi ? dhivehi : english;
  }

  TextStyle style({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return TextStyle(
      fontFamily: widget.isDhivehi ? 'Faruma' : null,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  @override
  void initState() {
    super.initState();
    _prepareThread();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _prepareThread() async {
    try {
      if (widget.thread != null) {
        _thread = widget.thread;
        _threadId = widget.thread!.id;
        await MarketplaceService.instance.markChatRead(
          thread: widget.thread!,
          reader: widget.currentUser,
        );
      } else {
        final business = widget.business;
        if (business == null) {
          throw StateError('Business is missing.');
        }
        final threadId = await MarketplaceService.instance.ensureChatThread(
          client: widget.currentUser,
          business: business,
          item: widget.item,
        );
        final thread = await MarketplaceService.instance.getChatThread(threadId);
        if (thread == null) throw StateError('Could not open chat.');
        _thread = thread;
        _threadId = threadId;
        await MarketplaceService.instance.markChatRead(
          thread: thread,
          reader: widget.currentUser,
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              error.toString().replaceFirst('Bad state: ', ''),
              style: style(color: Colors.white),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final thread = _thread;
    final message = _messageController.text.trim();
    if (thread == null || message.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await MarketplaceService.instance.sendChatMessage(
        thread: thread,
        sender: widget.currentUser,
        message: message,
      );
      _messageController.clear();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            error.toString().replaceFirst('Bad state: ', ''),
            style: style(color: Colors.white),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _thread == null
        ? widget.business?.businessName ?? text('Chat', 'ޗެޓް')
        : widget.currentUser.uid == _thread!.clientId
            ? _thread!.businessName
            : _thread!.clientName;

    return Directionality(
      textDirection:
          widget.isDhivehi ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style(fontWeight: FontWeight.bold),
              ),
              if (_thread?.itemName.isNotEmpty == true)
                Text(
                  _thread!.itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style(fontSize: 12),
                ),
            ],
          ),
        ),
        body: _loading || _threadId == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: StreamBuilder<List<ChatMessage>>(
                      stream: MarketplaceService.instance
                          .watchChatMessages(_threadId!),
                      builder: (context, snapshot) {
                        final messages = snapshot.data ?? const <ChatMessage>[];
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text(snapshot.error.toString()));
                        }
                        if (messages.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(26),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.chat_bubble_outline_rounded,
                                      size: 64),
                                  const SizedBox(height: 10),
                                  Text(
                                    text(
                                      'No messages yet. Start the chat now.',
                                      'އަދި މެސެޖެއް ނެތް. ޗެޓް ފަށާ.',
                                    ),
                                    textAlign: TextAlign.center,
                                    style: style(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final mine = message.senderId == widget.currentUser.uid;
                            return Align(
                              alignment: mine
                                  ? AlignmentDirectional.centerEnd
                                  : AlignmentDirectional.centerStart,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 5),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 9,
                                ),
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.74,
                                ),
                                decoration: BoxDecoration(
                                  color: mine
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.senderName,
                                      style: style(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: mine
                                            ? Theme.of(context).colorScheme.onPrimary
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      message.message,
                                      style: style(
                                        fontSize: 15,
                                        height: 1.35,
                                        color: mine
                                            ? Theme.of(context).colorScheme.onPrimary
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              minLines: 1,
                              maxLines: 4,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _send(),
                              decoration: InputDecoration(
                                hintText: text(
                                  'Write message...',
                                  'މެސެޖް ލިޔޭ...',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _sending ? null : _send,
                            child: _sending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
