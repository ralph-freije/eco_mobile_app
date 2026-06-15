import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/state/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../../shared/widgets/rounded_card.dart';
import '../../../shared/widgets/user_avatar.dart';

class CommunityDetailScreen extends StatefulWidget {
  const CommunityDetailScreen({required this.communityId, super.key});

  final String communityId;

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  final _messageController = TextEditingController();
  Map<String, dynamic>? _community;
  List<Map<String, dynamic>>? _messages;
  String? _error;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    final currentUserId =
        context.read<AuthController>().user?.id.toString();
    try {
      final body = await ApiClient.instance.get(
        ApiConstants.community(widget.communityId),
      );
      if (body is! Map) throw const FormatException('Invalid community data.');
      final community = Map<String, dynamic>.from(body);
      final members = community['members'] is List
          ? community['members'] as List
          : const [];
      final isMember = members.any((raw) {
        if (raw is! Map) return false;
        return raw['id']?.toString() == currentUserId;
      });
      List<Map<String, dynamic>>? messages;
      if (isMember) {
        final messagesBody = await ApiClient.instance.get(
          ApiConstants.communityMessages(widget.communityId),
        );
        if (messagesBody is List) {
          messages = messagesBody
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          try {
            await ApiClient.instance.post(
              ApiConstants.communityMessagesRead(widget.communityId),
            );
          } catch (_) {
            // Community content remains usable if read syncing fails.
          }
        }
      }
      if (mounted) {
        setState(() {
          _community = community;
          _messages = messages;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = ApiClient.errorMessage(error));
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final body = await ApiClient.instance.post(
        ApiConstants.communityMessages(widget.communityId),
        data: {'message': text},
      );
      if (body is Map && body['chat_message'] is Map && mounted) {
        setState(() {
          _messages ??= [];
          _messages!.add(
            Map<String, dynamic>.from(body['chat_message'] as Map),
          );
          _messageController.clear();
        });
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

  Future<void> _addGoal() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add community goal'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Goal description'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add goal'),
          ),
        ],
      ),
    );
    final goal = controller.text.trim();
    controller.dispose();
    if (confirmed != true || goal.isEmpty) return;
    try {
      await ApiClient.instance.post(
        ApiConstants.communityGoals(widget.communityId),
        data: {'goal_description': goal},
      );
      await _load();
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
    final colors = Theme.of(context).colorScheme;
    if (_community == null && _error == null) {
      return const LoadingState(label: 'Loading community...');
    }
    if (_community == null) return ErrorState(message: _error!, onRetry: _load);
    final members = _community!['members'] is List
        ? List<dynamic>.from(_community!['members'] as List)
        : <dynamic>[];
    final goals = _community!['goals'] is List
        ? List<dynamic>.from(_community!['goals'] as List)
        : <dynamic>[];
    final creator = _community!['creator'] is Map
        ? Map<String, dynamic>.from(_community!['creator'] as Map)
        : <String, dynamic>{};
    final currentUserId = context.watch<AuthController>().user?.id.toString();
    final isCreator =
        _community!['created_by']?.toString() == currentUserId;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        children: [
          RoundedCard(
            color: AppColors.navy,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _community!['name']?.toString() ?? 'Community',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 7),
                Text(
                  _community!['description']?.toString() ??
                      'An EcoTrack community.',
                  style: const TextStyle(color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 12),
                Text(
                  'Created by ${creator['name'] ?? 'EcoTrack member'}',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text('Goals', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              if (isCreator)
                TextButton.icon(
                  onPressed: _addGoal,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (goals.isEmpty)
            const RoundedCard(
              child: EmptyState(
                icon: Icons.flag_outlined,
                title: 'No goals yet',
                message: 'Community goals will appear here.',
              ),
            )
          else
            ...goals.whereType<Map>().map(
                  (goal) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: RoundedCard(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.flag_rounded,
                            color: AppColors.greenDark,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              goal['goal_description']?.toString() ?? 'Goal',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          const SizedBox(height: 18),
          Text('Members', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 9),
          SizedBox(
            height: 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: members.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final member = members[index] is Map
                    ? Map<String, dynamic>.from(members[index] as Map)
                    : <String, dynamic>{};
                return SizedBox(
                  width: 66,
                  child: Column(
                    children: [
                      UserAvatar(
                        name: member['name']?.toString() ?? 'User',
                        imageUrl: member['profile_picture']?.toString(),
                        isActive: member['is_active'] == true,
                        radius: 24,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        member['name']?.toString() ?? 'User',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Text('Community chat', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 9),
          if (_messages == null)
            const RoundedCard(
              child: Text(
                'Join this community from the communities list to access chat.',
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
            )
          else ...[
            RoundedCard(
              child: Column(
                children: [
                  if (_messages!.isEmpty)
                    const EmptyState(
                      icon: Icons.forum_outlined,
                      title: 'No messages yet',
                      message: 'Start a useful sustainability discussion.',
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _messages!.length,
                        itemBuilder: (context, index) {
                          final message = _messages![index];
                          final user = message['user'] is Map
                              ? Map<String, dynamic>.from(message['user'] as Map)
                              : <String, dynamic>{};
                          final mine = user['id']?.toString() == currentUserId;
                          final readByOthers =
                              message['is_read_by_others'] == true;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              mainAxisAlignment: mine
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!mine) ...[
                                  UserAvatar(
                                    name: user['name']?.toString() ?? 'User',
                                    isActive: user['is_active'] == true,
                                    radius: 16,
                                  ),
                                  const SizedBox(width: 7),
                                ],
                                Flexible(
                                  child: Container(
                                    constraints:
                                        const BoxConstraints(maxWidth: 260),
                                    padding: const EdgeInsets.fromLTRB(
                                      14,
                                      10,
                                      14,
                                      8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: mine
                                          ? AppColors.green
                                          : colors.surfaceContainerHigh,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(17),
                                        topRight: const Radius.circular(17),
                                        bottomLeft:
                                            Radius.circular(mine ? 17 : 4),
                                        bottomRight:
                                            Radius.circular(mine ? 4 : 17),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: mine
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      children: [
                                        if (!mine)
                                          Text(
                                            user['name']?.toString() ?? 'User',
                                            style: const TextStyle(
                                              color: AppColors.greenDark,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        Text(
                                          message['message']?.toString() ?? '',
                                          style: TextStyle(
                                            color: mine
                                                ? Colors.white
                                                : colors.onSurface,
                                            height: 1.35,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              message['created_at']
                                                      ?.toString() ??
                                                  '',
                                              style: TextStyle(
                                                color: mine
                                                    ? Colors.white70
                                                    : colors.onSurfaceVariant,
                                                fontSize: 8,
                                              ),
                                            ),
                                            if (mine) ...[
                                              const SizedBox(width: 5),
                                              Icon(
                                                Icons.done_all_rounded,
                                                size: 15,
                                                color: readByOthers
                                                    ? const Color(0xFFA9F0D1)
                                                    : Colors.white70,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: const InputDecoration(
                            hintText: 'Write to the community...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _sending ? null : _sendMessage,
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
