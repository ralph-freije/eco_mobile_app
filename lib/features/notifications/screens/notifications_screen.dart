import 'package:flutter/material.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../../shared/widgets/rounded_card.dart';
import '../../../shared/widgets/user_avatar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _filters = <String, String>{
    'all': 'All',
    'unread': 'Unread',
    'social': 'Social',
    'message': 'Messages',
    'community': 'Communities',
    'achievement': 'Achievements',
  };
  List<Map<String, dynamic>>? _items;
  String? _error;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final body = await ApiClient.instance.get(
        ApiConstants.notifications,
        queryParameters: {'filter': _filter},
      );
      final rawItems = body is Map ? body['data'] : null;
      if (rawItems is! List) throw const FormatException('Invalid notifications data.');
      if (mounted) setState(() => _items = rawItems.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList());
    } catch (error) {
      if (mounted) setState(() => _error = ApiClient.errorMessage(error));
    }
  }

  Future<void> _markRead(Map<String, dynamic> item) async {
    if (item['is_read'] == true) return;
    try {
      await ApiClient.instance.post(ApiConstants.notificationRead(item['id']));
      setState(() => item['is_read'] = true);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.errorMessage(error))));
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    try {
      await ApiClient.instance.delete(ApiConstants.notification(item['id']));
      setState(() => _items!.remove(item));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.errorMessage(error))));
    }
  }

  Future<void> _markAllRead() async {
    try {
      await ApiClient.instance.post(ApiConstants.notificationReadAll);
      setState(() {
        for (final item in _items ?? <Map<String, dynamic>>[]) {
          item['is_read'] = true;
        }
      });
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.errorMessage(error))));
    }
  }

  Future<void> _deleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all notifications?'),
        content: const Text('This removes every notification from your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiClient.instance.delete(ApiConstants.notificationDeleteAll);
      if (mounted) setState(() => _items = []);
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
    if (_items == null && _error == null) return const LoadingState(label: 'Loading notifications...');
    if (_items == null) return ErrorState(message: _error!, onRetry: _load);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        children: [
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.entries
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(entry.value),
                              selected: _filter == entry.key,
                              onSelected: (selected) {
                                if (!selected) return;
                                setState(() {
                                  _filter = entry.key;
                                  _items = null;
                                });
                                _load();
                              },
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'read') _markAllRead();
                if (value == 'delete') _deleteAll();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'read', child: Text('Mark all read')),
                PopupMenuItem(value: 'delete', child: Text('Delete all')),
              ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_items!.isEmpty)
            const EmptyState(icon: Icons.notifications_none_rounded, title: 'You are all caught up', message: 'Goal, social, and community updates will appear here.')
          else
            ..._items!.map((item) {
              final actor = item['actor'] is Map ? Map<String, dynamic>.from(item['actor'] as Map) : null;
              final isRead = item['is_read'] == true;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: RoundedCard(
                  color: isRead ? Colors.white : AppColors.mint,
                  padding: const EdgeInsets.all(15),
                  onTap: () => _markRead(item),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    UserAvatar(name: actor?['name']?.toString() ?? 'EcoTrack', imageUrl: actor?['profile_picture']?.toString(), radius: 22),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(item['title']?.toString() ?? 'Notification', style: const TextStyle(fontWeight: FontWeight.w800))),
                        if (!isRead) const CircleAvatar(radius: 4, backgroundColor: AppColors.green),
                      ]),
                      const SizedBox(height: 4),
                      Text(item['message']?.toString() ?? '', style: const TextStyle(color: AppColors.muted, height: 1.35)),
                      const SizedBox(height: 7),
                      Text(item['created_at_human']?.toString() ?? item['created_at']?.toString() ?? '', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                    ])),
                    IconButton(onPressed: () => _delete(item), icon: const Icon(Icons.delete_outline_rounded, size: 20), color: AppColors.muted),
                  ]),
                ),
              );
            }),
        ],
      ),
    );
  }
}
