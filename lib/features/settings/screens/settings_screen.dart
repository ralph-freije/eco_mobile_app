import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/state/auth_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../../shared/widgets/rounded_card.dart';
import '../../../shared/widgets/user_avatar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic>? _user;
  Map<String, dynamic> _profile = {};
  String? _error;
  bool _saving = false;

  static const _preferences = <String, String>{
    'weekly_report': 'Weekly report',
    'sustainability_alerts': 'Sustainability alerts',
    'community_notifications': 'Community notifications',
    'message_notifications': 'Message notifications',
    'achievement_notifications': 'Achievement notifications',
    'goal_reminders': 'Goal reminders',
    'public_profile': 'Public profile',
    'show_activity_stats': 'Show activity statistics',
    'show_online_status': 'Show online status',
    'show_email': 'Show email on profile',
    'allow_private_messages': 'Allow private messages',
    'allow_community_invites': 'Allow community invites',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final body = await ApiClient.instance.get(ApiConstants.profile);
      if (body is! Map || body['user'] is! Map) throw const FormatException('Invalid profile data.');
      final user = Map<String, dynamic>.from(body['user'] as Map);
      final profile = user['profile'] is Map ? Map<String, dynamic>.from(user['profile'] as Map) : <String, dynamic>{};
      if (mounted) setState(() { _user = user; _profile = profile; });
    } catch (error) {
      if (mounted) setState(() => _error = ApiClient.errorMessage(error));
    }
  }

  Future<void> _setPreference(String key, bool value) async {
    final previous = _profile[key] == true;
    setState(() { _profile[key] = value; _saving = true; });
    try {
      await ApiClient.instance.put(ApiConstants.profile, data: {key: value});
    } catch (error) {
      if (mounted) {
        setState(() => _profile[key] = previous);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.errorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    await context.read<AuthController>().logout();
  }

  Future<void> _pickAvatar() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1200,
    );
    if (image == null) return;
    setState(() => _saving = true);
    try {
      final bytes = await image.readAsBytes();
      final formData = FormData.fromMap({
        'avatar': MultipartFile.fromBytes(bytes, filename: image.name),
      });
      final body = await ApiClient.instance.postMultipart(
        ApiConstants.profileAvatar,
        data: formData,
      );
      if (body is Map && body['avatar'] != null && mounted) {
        setState(() => _profile['profile_picture'] = body['avatar']);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.errorMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null && _error == null) return const LoadingState(label: 'Loading settings...');
    if (_user == null) return ErrorState(message: _error!, onRetry: _load);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      children: [
        RoundedCard(
          color: AppColors.navy,
          child: Row(children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                UserAvatar(name: _user!['name']?.toString() ?? 'EcoTrack user', imageUrl: _profile['profile_picture']?.toString(), radius: 30),
                Positioned(
                  right: -6,
                  bottom: -6,
                  child: IconButton.filled(
                    onPressed: _saving ? null : _pickAvatar,
                    iconSize: 16,
                    constraints: const BoxConstraints.tightFor(
                      width: 30,
                      height: 30,
                    ),
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.camera_alt_rounded),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_user!['name']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(_user!['email']?.toString() ?? '', style: const TextStyle(color: Colors.white70)),
              if ((_profile['location']?.toString() ?? '').isNotEmpty) Text(_profile['location'].toString(), style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ])),
            if (_saving) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          ]),
        ),
        const SizedBox(height: 20),
        Text('Preferences', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        RoundedCard(
          padding: EdgeInsets.zero,
          child: Column(children: _preferences.entries.map((entry) => SwitchListTile(
            title: Text(entry.value),
            value: _profile[entry.key] == null ? true : _profile[entry.key] == true,
            onChanged: _saving ? null : (value) => _setPreference(entry.key, value),
          )).toList()),
        ),
        const SizedBox(height: 20),
        Text('Explore', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        RoundedCard(
          padding: EdgeInsets.zero,
          child: Column(children: [
            ListTile(leading: const Icon(Icons.groups_rounded), title: const Text('Communities'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => context.push('/communities')),
            ListTile(leading: const Icon(Icons.people_alt_rounded), title: const Text('People'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => context.push('/people')),
            ListTile(leading: const Icon(Icons.notifications_none_rounded), title: const Text('Notifications'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => context.push('/notifications')),
          ]),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: _logout,
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, padding: const EdgeInsets.symmetric(vertical: 16)),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}
