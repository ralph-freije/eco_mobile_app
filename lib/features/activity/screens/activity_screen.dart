import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/rounded_card.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  static const _options = <String, List<String>>{
    'transport': [
      'Electric Car (Tesla Model 3)',
      'Hybrid Car (Toyota Prius)',
      'Petrol Car (Sedan)',
      'Petrol Car (SUV)',
      'Public Bus',
      'Train',
      'Bicycle',
    ],
    'diet': ['Beef', 'Chicken', 'Vegetarian Meal', 'Vegan Meal'],
    'energy': ['Electricity', 'Solar', 'Gas'],
    'shopping': ['Clothing', 'Electronics', 'Groceries'],
  };

  final _formKey = GlobalKey<FormState>();
  final _typeController = TextEditingController();
  final _amountController = TextEditingController();
  String _category = 'transport';
  bool _saving = false;

  @override
  void dispose() {
    _typeController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String get _typeLabel => switch (_category) {
        'transport' => 'Vehicle type',
        'diet' => 'Food or meal type',
        'energy' => 'Energy type',
        _ => 'Item type',
      };

  String get _amountLabel => switch (_category) {
        'transport' => 'Distance (km)',
        'diet' => 'Quantity',
        'energy' => 'Usage (kWh)',
        _ => 'Amount',
      };

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final amount = double.parse(_amountController.text.trim());
    final type = _typeController.text.trim();
    final data = switch (_category) {
      'transport' => {'distance': amount, 'vehicle': type},
      'diet' => {'type': type, 'quantity': amount},
      'energy' => {'type': type, 'usage': amount},
      _ => {'type': type, 'amount': amount},
    };
    try {
      final body = await ApiClient.instance.post(
        ApiConstants.activity,
        data: {'category': _category, 'data': data},
      );
      if (!mounted) return;
      final carbon = body is Map ? body['carbon'] : null;
      _typeController.clear();
      _amountController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            carbon == null
                ? 'Activity saved.'
                : 'Activity saved: $carbon kg CO2e.',
          ),
          action: SnackBarAction(
            label: 'History',
            onPressed: () => context.go('/history'),
          ),
        ),
      );
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.errorMessage(error))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      children: [
        Text('Log an activity', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        const Text('Choose a category and record the same core details used by EcoTrack web.', style: TextStyle(color: AppColors.muted, height: 1.4)),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['transport', 'diet', 'energy', 'shopping'].map((category) {
            return ChoiceChip(
              label: Text('${category[0].toUpperCase()}${category.substring(1)}'),
              selected: _category == category,
              onSelected: (_) => setState(() {
                _category = category;
                _typeController.clear();
                _amountController.clear();
              }),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        RoundedCard(
          child: Form(
            key: _formKey,
            child: Column(children: [
              TextFormField(
                controller: _typeController,
                decoration: InputDecoration(labelText: _typeLabel, prefixIcon: const Icon(Icons.edit_road_rounded)),
                validator: (value) => value == null || value.trim().isEmpty ? 'Enter $_typeLabel.' : null,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: (_options[_category] ?? const <String>[])
                      .map(
                        (option) => ActionChip(
                          label: Text(option),
                          onPressed: () => setState(
                            () => _typeController.text = option,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: _amountLabel, prefixIcon: const Icon(Icons.numbers_rounded)),
                validator: (value) {
                  final number = double.tryParse(value?.trim() ?? '');
                  return number == null || number <= 0 ? 'Enter a value greater than zero.' : null;
                },
              ),
              const SizedBox(height: 20),
              PrimaryButton(label: 'Save activity', isLoading: _saving, onPressed: _save, icon: Icons.check_rounded),
            ]),
          ),
        ),
      ],
    );
  }
}
