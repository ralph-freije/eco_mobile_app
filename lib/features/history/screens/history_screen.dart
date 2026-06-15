import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../../shared/widgets/rounded_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
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
      final body = await ApiClient.instance.get(ApiConstants.activity);
      if (body is! List) throw const FormatException('Invalid activity history.');
      if (mounted) setState(() => _items = body.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList());
    } catch (error) {
      if (mounted) setState(() => _error = ApiClient.errorMessage(error));
    }
  }

  String _category(Map<String, dynamic> item) {
    final raw = item['category'];
    return raw is Map ? raw['name']?.toString().toLowerCase() ?? 'activity' : raw?.toString().toLowerCase() ?? 'activity';
  }

  String _date(Object? value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed == null ? value?.toString() ?? '' : DateFormat('MMM d, y').format(parsed.toLocal());
  }

  void _showDetails(Map<String, dynamic> item) {
    final colors = Theme.of(context).colorScheme;
    final category = _category(item);
    final data = item['activity_data'] is Map
        ? Map<String, dynamic>.from(item['activity_data'] as Map)
        : <String, dynamic>{};
    final carbon =
        double.tryParse(item['carbon_value']?.toString() ?? '') ?? 0;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${category[0].toUpperCase()}${category.substring(1)} activity',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 5),
              Text(
                _date(item['created_at']),
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  '${carbon.toStringAsFixed(2)} kg CO2e',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                ),
              ),
              if (data.isNotEmpty) ...[
                const SizedBox(height: 18),
                ...data.entries
                    .where((entry) => entry.value != null)
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                entry.key.replaceAll('_', ' '),
                                style: const TextStyle(
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Flexible(
                              child: Text(
                                entry.value.toString(),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_items == null && _error == null) return const LoadingState(label: 'Loading activity history...');
    if (_items == null) return ErrorState(message: _error!, onRetry: _load);
    final filtered = _filter == 'all' ? _items! : _items!.where((item) => _category(item) == _filter).toList();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: ['all', 'transport', 'diet', 'energy', 'shopping'].map((category) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(label: Text(category == 'all' ? 'All' : '${category[0].toUpperCase()}${category.substring(1)}'), selected: _filter == category, onSelected: (_) => setState(() => _filter = category)),
            )).toList()),
          ),
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            const EmptyState(icon: Icons.history_rounded, title: 'No activities found', message: 'Activities you log will appear here.')
          else
            ...filtered.map((item) {
              final category = _category(item);
              final data = item['activity_data'] is Map ? Map<String, dynamic>.from(item['activity_data'] as Map) : <String, dynamic>{};
              final detail = data['vehicle'] ?? data['type'] ?? data['tracking_type'] ?? 'Recorded activity';
              final carbon = double.tryParse(item['carbon_value']?.toString() ?? '') ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: RoundedCard(
                  onTap: () => _showDetails(item),
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    const CircleAvatar(backgroundColor: AppColors.mint, child: Icon(Icons.eco_rounded, color: AppColors.greenDark)),
                    const SizedBox(width: 13),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${category[0].toUpperCase()}${category.substring(1)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text('$detail - ${_date(item['created_at'])}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    ])),
                    Text('${carbon.toStringAsFixed(2)} kg', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ]),
                ),
              );
            }),
        ],
      ),
    );
  }
}
