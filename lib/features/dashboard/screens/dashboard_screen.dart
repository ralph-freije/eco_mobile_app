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
import '../widgets/dashboard_charts.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final body = await ApiClient.instance.get(ApiConstants.dashboard);
      if (body is! Map) throw const FormatException('Invalid dashboard data.');
      if (mounted) setState(() => _data = Map<String, dynamic>.from(body));
    } catch (error) {
      if (mounted) setState(() => _error = ApiClient.errorMessage(error));
    }
  }

  double _number(Object? value) => double.tryParse(value?.toString() ?? '') ?? 0;

  @override
  Widget build(BuildContext context) {
    if (_data == null && _error == null) {
      return const LoadingState(label: 'Loading your impact...');
    }
    if (_data == null) return ErrorState(message: _error!, onRetry: _load);

    final totals = _data!['total_carbon'] is Map
        ? Map<String, dynamic>.from(_data!['total_carbon'] as Map)
        : <String, dynamic>{};
    final categories = _data!['categories'] is Map
        ? Map<String, dynamic>.from(_data!['categories'] as Map)
        : <String, dynamic>{};
    final activities = _data!['recent_activities'] is List
        ? List<dynamic>.from(_data!['recent_activities'] as List)
        : <dynamic>[];
    final goals = _data!['goals'] is List
        ? List<dynamic>.from(_data!['goals'] as List)
        : <dynamic>[];
    final trend = _data!['trend'] is List
        ? (_data!['trend'] as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
        : <Map<String, dynamic>>[];
    final userName = context.watch<AuthController>().user?.name.split(' ').first ?? 'there';

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.navy, AppColors.navyLight],
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('YOUR IMPACT', style: TextStyle(color: Color(0xFF76DDB0), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                const SizedBox(height: 9),
                Text('Hello, $userName', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
                const SizedBox(height: 7),
                const Text('Keep building a clearer picture of your carbon footprint.', style: TextStyle(color: Colors.white70, height: 1.45)),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => context.go('/activity'),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Log activity'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('Carbon overview', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _MetricCard(label: 'Today', value: _number(totals['today']), color: AppColors.green)),
            const SizedBox(width: 12),
            Expanded(child: _MetricCard(label: 'This month', value: _number(totals['month']), color: const Color(0xFF347C86))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _MetricCard(label: 'This week', value: _number(totals['week']), color: const Color(0xFFC18A2D))),
            const SizedBox(width: 12),
            Expanded(child: _MetricCard(label: 'All time', value: _number(totals['all']), color: AppColors.navyLight)),
          ]),
          const SizedBox(height: 22),
          CarbonTrendChart(trend: trend),
          const SizedBox(height: 14),
          CategoryDonutChart(categories: categories),
          const SizedBox(height: 22),
          Text('Quick access', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _QuickChip('History', Icons.history_rounded, () => context.push('/history')),
              _QuickChip('Communities', Icons.groups_rounded, () => context.push('/communities')),
              _QuickChip('People', Icons.people_alt_rounded, () => context.push('/people')),
              _QuickChip('Notifications', Icons.notifications_rounded, () => context.push('/notifications')),
            ],
          ),
          const SizedBox(height: 22),
          Text('Recent activity', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          if (activities.isEmpty)
            const RoundedCard(child: EmptyState(icon: Icons.eco_outlined, title: 'No activity yet', message: 'Log your first activity to start tracking your impact.'))
          else
            ...activities.whereType<Map>().map((raw) {
              final item = Map<String, dynamic>.from(raw);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: RoundedCard(
                  padding: const EdgeInsets.all(16),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(backgroundColor: AppColors.mint, child: Icon(Icons.eco_rounded, color: AppColors.greenDark)),
                    title: Text(item['category']?.toString() ?? 'Activity'),
                    subtitle: Text(item['created_at']?.toString() ?? ''),
                    trailing: Text('${_number(item['carbon_value']).toStringAsFixed(2)} kg', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              );
            }),
          if (goals.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Personal goals', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            ...goals.whereType<Map>().map((raw) {
              final goal = Map<String, dynamic>.from(raw);
              final progress = _number(goal['progress']).clamp(0, 100) / 100;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: RoundedCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(goal['title']?.toString() ?? 'Goal', style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: progress, minHeight: 8, borderRadius: BorderRadius.circular(8)),
                    const SizedBox(height: 7),
                    Text('${(progress * 100).round()}% complete', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ]),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;
  @override
  Widget build(BuildContext context) => RoundedCard(
        padding: const EdgeInsets.all(17),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.auto_graph_rounded, color: color),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value.toStringAsFixed(2), style: Theme.of(context).textTheme.headlineSmall),
          const Text('kg CO2e', style: TextStyle(color: AppColors.muted, fontSize: 11)),
        ]),
      );
}

class _QuickChip extends StatelessWidget {
  const _QuickChip(this.label, this.icon, this.onTap);
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ActionChip(avatar: Icon(icon, size: 18), label: Text(label), onPressed: onTap);
}
