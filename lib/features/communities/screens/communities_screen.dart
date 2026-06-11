import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../../shared/widgets/rounded_card.dart';

class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});
  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  List<Map<String, dynamic>>? _items;
  String? _error;
  final Set<int> _busy = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final body = await ApiClient.instance.get(ApiConstants.communities);
      if (body is! List) throw const FormatException('Invalid communities data.');
      if (mounted) setState(() => _items = body.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList());
    } catch (error) {
      if (mounted) setState(() => _error = ApiClient.errorMessage(error));
    }
  }

  Future<void> _toggle(Map<String, dynamic> community) async {
    final id = int.tryParse(community['id']?.toString() ?? '');
    if (id == null || _busy.contains(id) || community['is_creator'] == true) return;
    final joined = community['is_member'] == true;
    setState(() => _busy.add(id));
    try {
      if (joined) {
        await ApiClient.instance.delete(ApiConstants.leaveCommunity(id));
      } else {
        await ApiClient.instance.post(ApiConstants.joinCommunity(id));
      }
      setState(() {
        community['is_member'] = !joined;
        final count = int.tryParse(community['members_count']?.toString() ?? '') ?? 0;
        community['members_count'] = joined ? (count - 1).clamp(0, count) : count + 1;
      });
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.errorMessage(error))));
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  Future<void> _create() async {
    final name = TextEditingController();
    final description = TextEditingController();
    final shouldCreate = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Create community'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Community name')),
        const SizedBox(height: 12),
        TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create'))],
    ));
    if (shouldCreate != true || name.text.trim().isEmpty) return;
    try {
      await ApiClient.instance.post(ApiConstants.communities, data: {'name': name.text.trim(), 'description': description.text.trim()});
      await _load();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.errorMessage(error))));
    } finally {
      name.dispose(); description.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items == null && _error == null) return const LoadingState(label: 'Loading communities...');
    if (_items == null) return ErrorState(message: _error!, onRetry: _load);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        children: [
          Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: _create, icon: const Icon(Icons.add_rounded), label: const Text('Create'))),
          const SizedBox(height: 12),
          if (_items!.isEmpty)
            const EmptyState(icon: Icons.groups_rounded, title: 'No communities yet', message: 'Create the first group and invite people to build greener habits together.')
          else
            ..._items!.map((community) {
              final id = int.tryParse(community['id']?.toString() ?? '') ?? 0;
              final joined = community['is_member'] == true;
              final creator = community['is_creator'] == true;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RoundedCard(
                  onTap: () => context.go('/communities/${community['id']}'),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const CircleAvatar(backgroundColor: AppColors.mint, child: Icon(Icons.groups_rounded, color: AppColors.greenDark)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(community['name']?.toString() ?? 'Community', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                      if (creator) const Chip(label: Text('Owner')),
                    ]),
                    const SizedBox(height: 10),
                    Text(community['description']?.toString() ?? 'A sustainability community.', style: const TextStyle(color: AppColors.muted, height: 1.4)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Text('${community['members_count'] ?? 0} members - ${community['goals_count'] ?? 0} goals', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                      const Spacer(),
                      if (!creator) OutlinedButton(onPressed: _busy.contains(id) ? null : () => _toggle(community), child: Text(joined ? 'Leave' : 'Join')),
                    ]),
                  ]),
                ),
              );
            }),
        ],
      ),
    );
  }
}
