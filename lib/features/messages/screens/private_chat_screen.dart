import 'package:flutter/material.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../../shared/widgets/user_avatar.dart';

class PrivateChatScreen extends StatefulWidget {
  const PrivateChatScreen({
    required this.conversationId,
    required this.title,
    super.key,
  });

  final String conversationId;
  final String title;

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>>? _messages;
  String? _error;
  bool _sending = false;

  Map<String, dynamic>? get _otherUser {
    for (final message in _messages ?? <Map<String, dynamic>>[]) {
      if (message['is_mine'] == true || message['user'] is! Map) {
        continue;
      }
      return Map<String, dynamic>.from(message['user'] as Map);
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final body = await ApiClient.instance.get(
        ApiConstants.privateMessages(widget.conversationId),
      );
      if (body is! List) throw const FormatException('Invalid chat data.');
      final messages = body
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      try {
        await ApiClient.instance.post(
          ApiConstants.privateMessagesRead(widget.conversationId),
        );
      } catch (_) {
        // Message content remains usable if read-receipt syncing fails.
      }
      if (mounted) {
        setState(() => _messages = messages);
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
      }
    } catch (error) {
      if (mounted) setState(() => _error = ApiClient.errorMessage(error));
    }
  }

  Future<void> _send() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final body = await ApiClient.instance.post(
        ApiConstants.privateMessages(widget.conversationId),
        data: {'message': message},
      );
      if (body is Map && body['chat_message'] is Map && mounted) {
        setState(() {
          _messages ??= [];
          _messages!.add(
            Map<String, dynamic>.from(body['chat_message'] as Map),
          );
          _messageController.clear();
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.errorMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToEnd() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final otherUser = _otherUser;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              UserAvatar(
                name: widget.title,
                imageUrl: otherUser?['profile_picture']?.toString(),
                isActive: otherUser == null ||
                        otherUser['online_status_hidden'] == true
                    ? null
                    : otherUser['is_active'] == true,
                radius: 20,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (otherUser != null &&
                        otherUser['online_status_hidden'] != true)
                      Text(
                        otherUser['is_active'] == true
                            ? 'Active now'
                            : otherUser['last_seen_at'] != null
                                ? 'Last seen ${otherUser['last_seen_at']}'
                                : 'Offline',
                        style: TextStyle(
                          color: otherUser['is_active'] == true
                              ? AppColors.greenDark
                              : AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildMessages()),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: 'Write a message...',
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  icon: _sending
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
    );
  }

  Widget _buildMessages() {
    final colors = Theme.of(context).colorScheme;
    if (_messages == null && _error == null) {
      return const LoadingState(label: 'Loading conversation...');
    }
    if (_messages == null) return ErrorState(message: _error!, onRetry: _load);
    if (_messages!.isEmpty) {
      return const EmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'Start the conversation',
        message: 'Send a message to your mutual connection.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        itemCount: _messages!.length,
        itemBuilder: (context, index) {
          final message = _messages![index];
          final mine = message['is_mine'] == true;
          final read = message['is_read'] == true;
          final user = message['user'] is Map
              ? Map<String, dynamic>.from(message['user'] as Map)
              : <String, dynamic>{};
          return Row(
            mainAxisAlignment:
                mine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!mine) ...[
                UserAvatar(
                  name: user['name']?.toString() ?? 'User',
                  imageUrl: user['profile_picture']?.toString(),
                  isActive: user['online_status_hidden'] == true
                      ? null
                      : user['is_active'] == true,
                  radius: 16,
                ),
                const SizedBox(width: 7),
              ],
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 286),
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.fromLTRB(15, 11, 15, 8),
                  decoration: BoxDecoration(
                    color: mine ? AppColors.green : colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(mine ? 18 : 4),
                      bottomRight: Radius.circular(mine ? 4 : 18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                  if (!mine)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        user['name']?.toString() ?? 'User',
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  Text(
                    message['message']?.toString() ?? '',
                    style: TextStyle(
                      color: mine ? Colors.white : colors.onSurface,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message['created_at']?.toString() ?? '',
                        style: TextStyle(
                          color: mine ? Colors.white70 : colors.onSurfaceVariant,
                          fontSize: 9,
                        ),
                      ),
                      if (mine) ...[
                        const SizedBox(width: 5),
                        Icon(
                          read ? Icons.done_all_rounded : Icons.done_rounded,
                          size: 15,
                          color: read ? const Color(0xFFA9F0D1) : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
