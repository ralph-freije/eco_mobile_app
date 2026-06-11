import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../../shared/widgets/rounded_card.dart';
import '../../../shared/widgets/user_avatar.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<Map<String, dynamic>>? _items;
  String? _error;
  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final body = await ApiClient.instance.get(ApiConstants.privateConversations);
      if (body is! List) throw const FormatException('Invalid conversations data.');
      if (mounted) setState(() => _items = body.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList());
    } catch (error) {
      if (mounted) setState(() => _error = ApiClient.errorMessage(error));
    }
  }

  Future<void> _startNewConversation() async {
    try {
      final body = await ApiClient.instance.get(ApiConstants.mutualUsers);
      if (body is! List || !mounted) return;
      final users = body
          .whereType<Map>()
          .map((user) => Map<String, dynamic>.from(user))
          .toList();
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New conversation',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                const Text(
                  'You can message mutual followers who accept private messages.',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 14),
                if (users.isEmpty)
                  const EmptyState(
                    icon: Icons.people_outline_rounded,
                    title: 'No mutual connections yet',
                    message: 'Follow each other before starting a private chat.',
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: UserAvatar(
                            name: user['name']?.toString() ?? 'User',
                            imageUrl: user['profile_picture']?.toString(),
                            isActive: user['online_status_hidden'] == true
                                ? null
                                : user['is_active'] == true,
                          ),
                          title: Text(user['name']?.toString() ?? 'User'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            _openConversation(user);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.errorMessage(error))),
        );
      }
    }
  }

  Future<void> _openConversation(Map<String, dynamic> user) async {
    try {
      final body = await ApiClient.instance.post(
        ApiConstants.startConversation(user['id']),
      );
      if (body is Map && body['conversation'] is Map && mounted) {
        final conversation =
            Map<String, dynamic>.from(body['conversation'] as Map);
        final name = Uri.encodeQueryComponent(
          user['name']?.toString() ?? 'Conversation',
        );
        context.go('/messages/${conversation['id']}?name=$name');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.errorMessage(error))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items == null && _error == null) return const LoadingState(label: 'Loading conversations...');
    if (_items == null) return ErrorState(message: _error!, onRetry: _load);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _startNewConversation,
              icon: const Icon(Icons.add_comment_rounded),
              label: const Text('New chat'),
            ),
          ),
          const SizedBox(height: 12),
          if (_items!.isEmpty)
            const EmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'No conversations yet',
              message: 'Private conversations become available with mutual followers.',
            ),
          ..._items!.map((conversation) {
          final user = conversation['other_user'] is Map ? Map<String, dynamic>.from(conversation['other_user'] as Map) : <String, dynamic>{};
          final last = conversation['last_message'] is Map ? Map<String, dynamic>.from(conversation['last_message'] as Map) : <String, dynamic>{};
          // Conversation summaries do not expose last-message read status.
          // Read ticks are therefore shown only inside the chat thread.
          final unread = int.tryParse(conversation['unread_count']?.toString() ?? '') ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: RoundedCard(
              padding: const EdgeInsets.all(15),
              onTap: () => context.go(
                '/messages/${conversation['id']}?name=${Uri.encodeQueryComponent(user['name']?.toString() ?? 'Conversation')}',
              ),
              child: Row(children: [
                UserAvatar(
                  name: user['name']?.toString() ?? 'User',
                  imageUrl: user['profile_picture']?.toString(),
                  isActive: user['online_status_hidden'] == true
                      ? null
                      : user['is_active'] == true,
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user['name']?.toString() ?? 'Conversation', style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    last.isEmpty
                        ? (user['is_active'] == true
                            ? 'Active now'
                            : 'No messages yet')
                        : '${last['is_mine'] == true ? 'You: ' : ''}${last['message'] ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ])),
                if (unread > 0) CircleAvatar(radius: 13, backgroundColor: AppColors.green, child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11))),
              ]),
            ),
          );
        }),
        ],
      ),
    );
  }
}
