import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});
  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>>? _users;
  String? _error;
  Timer? _debounce;
  final Set<int> _busy = {};

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _debounce?.cancel(); _searchController.dispose(); super.dispose(); }

  Future<void> _load([String query = '']) async {
    setState(() => _error = null);
    try {
      final body = await ApiClient.instance.get(ApiConstants.usersSearch, queryParameters: {'q': query});
      if (body is! List) throw const FormatException('Invalid people data.');
      if (mounted) setState(() => _users = body.whereType<Map>().map((user) => Map<String, dynamic>.from(user)).toList());
    } catch (error) {
      if (mounted) setState(() => _error = ApiClient.errorMessage(error));
    }
  }

  void _search(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _load(value.trim()));
  }

  Future<void> _toggleFollow(Map<String, dynamic> user) async {
    final id = int.tryParse(user['id']?.toString() ?? '');
    if (id == null || _busy.contains(id)) return;
    final following = user['is_following'] == true;
    setState(() => _busy.add(id));
    try {
      if (following) {
        await ApiClient.instance.delete(ApiConstants.unfollowUser(id));
      } else {
        await ApiClient.instance.post(ApiConstants.followUser(id));
      }
      setState(() => user['is_following'] = !following);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.errorMessage(error))));
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  Future<void> _showProfile(int id) async {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.68,
        minChildSize: 0.42,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: FutureBuilder<dynamic>(
            future: ApiClient.instance.get(ApiConstants.socialProfile(id)),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const LoadingState(label: 'Loading profile...');
              }
              if (snapshot.hasError || snapshot.data is! Map) {
                final message = snapshot.hasError
                    ? ApiClient.errorMessage(snapshot.error!)
                    : 'Profile details are unavailable.';
                final isPrivate = message.toLowerCase().contains('private');
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 52),
                    Icon(
                      isPrivate ? Icons.lock_rounded : Icons.person_off_rounded,
                      size: 52,
                      color: AppColors.greenDark,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isPrivate ? 'Private profile' : 'Profile unavailable',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isPrivate
                          ? 'This member has chosen to keep their EcoTrack profile private.'
                          : message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        height: 1.45,
                      ),
                    ),
                  ],
                );
              }
              final body = Map<String, dynamic>.from(snapshot.data as Map);
              final user = body['user'] is Map
                  ? Map<String, dynamic>.from(body['user'] as Map)
                  : <String, dynamic>{};
              final achievements = body['achievements'] is Map
                  ? Map<String, dynamic>.from(body['achievements'] as Map)
                  : <String, dynamic>{};
              final ownId = context.read<AuthController>().user?.id;
              final isOwn = ownId == id;
              final mutual = user['is_mutual'] == true;
              final statusHidden = user['online_status_hidden'] == true;
              final active = user['is_active'] == true;
              return ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: UserAvatar(
                      name: user['name']?.toString() ?? 'User',
                      imageUrl: user['profile_picture']?.toString(),
                      isActive: statusHidden ? null : active,
                      radius: 44,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user['name']?.toString() ?? 'User',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if ((user['email']?.toString() ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      user['email'].toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                  const SizedBox(height: 7),
                  Text(
                    isOwn
                        ? 'This is your profile'
                        : statusHidden
                            ? (mutual ? 'Mutual connection' : 'EcoTrack member')
                            : active
                                ? 'Active now'
                                : user['last_seen_at'] != null
                                    ? 'Last seen ${user['last_seen_at']}'
                                    : 'Offline',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: active ? AppColors.greenDark : AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _ProfileStat(
                          value: user['followers_count']?.toString() ?? '0',
                          label: 'Followers',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ProfileStat(
                          value: user['following_count']?.toString() ?? '0',
                          label: 'Following',
                        ),
                      ),
                    ],
                  ),
                  if (achievements.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ProfileStat(
                            value: achievements['activities_count']?.toString() ?? '0',
                            label: 'Activities',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ProfileStat(
                            value: achievements['total_carbon_tracked']?.toString() ?? '0',
                            label: 'kg tracked',
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (!isOwn && mutual) ...[
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _startConversation(user);
                      },
                      icon: const Icon(Icons.chat_bubble_rounded),
                      label: const Text('Message'),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _startConversation(Map<String, dynamic> user) async {
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
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: TextField(controller: _searchController, onChanged: _search, decoration: const InputDecoration(hintText: 'Search people by name or email', prefixIcon: Icon(Icons.search_rounded))),
      ),
      Expanded(child: _buildContent()),
    ]);
  }

  Widget _buildContent() {
    if (_users == null && _error == null) return const LoadingState(label: 'Finding people...');
    if (_users == null) return ErrorState(message: _error!, onRetry: () => _load(_searchController.text.trim()));
    final ownUser = context.watch<AuthController>().user;
    return RefreshIndicator(
      onRefresh: () => _load(_searchController.text.trim()),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        children: [
          if (ownUser != null) ...[
            RoundedCard(
              onTap: () => _showProfile(ownUser.id),
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  UserAvatar(
                    name: ownUser.name,
                    imageUrl: ownUser.profile['profile_picture']?.toString(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ownUser.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Me - This is your profile',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (_users!.isEmpty)
            const EmptyState(
              icon: Icons.person_search_rounded,
              title: 'No people found',
              message: 'Try a different name or email address.',
            ),
          ..._users!.map((user) {
          final id = int.tryParse(user['id']?.toString() ?? '') ?? 0;
          final following = user['is_following'] == true;
          final mutual = user['is_mutual'] == true;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: RoundedCard(
              onTap: () => _showProfile(id),
              padding: const EdgeInsets.all(15),
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
                  Text(user['name']?.toString() ?? 'User', style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(
                    mutual
                        ? 'Mutual connection'
                        : user['is_following_me'] == true
                            ? 'Follows you'
                            : '${user['followers_count'] ?? 0} followers',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ])),
                OutlinedButton(
                  onPressed: _busy.contains(id) ? null : () => _toggleFollow(user),
                  child: Text(mutual ? 'Mutual' : following ? 'Following' : 'Follow'),
                ),
              ]),
            ),
          );
        }),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
