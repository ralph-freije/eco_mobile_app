import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/rounded_card.dart';

class CarbonTrendChart extends StatelessWidget {
  const CarbonTrendChart({required this.trend, super.key});

  final List<Map<String, dynamic>> trend;

  double _number(Object? value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;

  @override
  Widget build(BuildContext context) {
    final values = trend.map((item) => _number(item['carbon'])).toList();
    final hasData = values.any((value) => value > 0);
    final maxValue = values.fold<double>(
      0,
      (current, value) => math.max(current, value).toDouble(),
    );
    final yInterval = maxValue <= 0
        ? 1.0
        : maxValue <= 4
            ? 1.0
            : maxValue / 4;

    return RoundedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '7-day carbon trend',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Daily emissions in kg CO2e',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: AppColors.greenDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: SizedBox(
              height: 210,
              child: hasData
                  ? LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: math.max(0, trend.length - 1).toDouble(),
                      minY: 0,
                      maxY: maxValue <= 0 ? 1 : maxValue * 1.25,
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        horizontalInterval: yInterval,
                        getDrawingHorizontalLine: (value) => const FlLine(
                          color: AppColors.border,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: yInterval,
                            reservedSize: 42,
                            getTitlesWidget: (value, meta) => Padding(
                              padding: const EdgeInsets.only(right: 7),
                              child: Text(
                                value >= 100
                                    ? value.toStringAsFixed(0)
                                    : value.toStringAsFixed(
                                        value < 10 && value % 1 != 0 ? 1 : 0,
                                      ),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final index = value.round();
                              if (index < 0 || index >= trend.length) {
                                return const SizedBox.shrink();
                              }
                              final label = trend[index]['date']
                                      ?.toString()
                                      .split(' ')
                                      .last ??
                                  '';
                              return Padding(
                                padding: const EdgeInsets.only(top: 9),
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (spot) => AppColors.navy,
                          getTooltipItems: (spots) => spots
                              .map(
                                (spot) => LineTooltipItem(
                                  '${spot.y.toStringAsFixed(2)} kg',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            trend.length,
                            (index) => FlSpot(
                              index.toDouble(),
                              _number(trend[index]['carbon']),
                            ),
                          ),
                          isCurved: true,
                          color: AppColors.green,
                          barWidth: 4,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.green.withValues(alpha: 0.28),
                                AppColors.green.withValues(alpha: 0.02),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    )
                  : const _ChartEmpty(
                      icon: Icons.show_chart_rounded,
                      message: 'Log activities to reveal your weekly trend.',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryDonutChart extends StatelessWidget {
  const CategoryDonutChart({required this.categories, super.key});

  final Map<String, dynamic> categories;

  static const _colors = [
    AppColors.green,
    Color(0xFF347C86),
    Color(0xFFF2B84B),
    Color(0xFF8D78C7),
  ];

  double _number(Object? value) =>
      double.tryParse(value?.toString() ?? '') ?? 0;

  @override
  Widget build(BuildContext context) {
    final entries = ['transport', 'diet', 'energy', 'shopping']
        .map((name) => MapEntry(name, _number(categories[name])))
        .toList();
    final total = entries.fold<double>(0, (sum, item) => sum + item.value);

    return RoundedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly category mix',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          const Text(
            'Where your footprint comes from',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 18),
          if (total <= 0)
            const SizedBox(
              height: 190,
              child: _ChartEmpty(
                icon: Icons.donut_large_rounded,
                message: 'Category totals will appear after your first log.',
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final chart = SizedBox(
                  width: 138,
                  height: 154,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          centerSpaceRadius: 47,
                          sectionsSpace: 3,
                          sections: List.generate(entries.length, (index) {
                            final entry = entries[index];
                            return PieChartSectionData(
                              value: entry.value,
                              color: _colors[index],
                              radius: 25,
                              showTitle: false,
                            );
                          }),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            total.toStringAsFixed(1),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: AppColors.navy),
                          ),
                          const Text(
                            'kg CO2e',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
                final legend = Column(
                    children: List.generate(entries.length, (index) {
                      final entry = entries[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _colors[index],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _capitalize(entry.key),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              entry.value.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  );
                if (constraints.maxWidth < 310) {
                  return Column(
                    children: [
                      chart,
                      const SizedBox(height: 8),
                      legend,
                    ],
                  );
                }
                return Row(
                  children: [
                    chart,
                    const SizedBox(width: 14),
                    Expanded(child: legend),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  String _capitalize(String value) =>
      '${value[0].toUpperCase()}${value.substring(1)}';
}

class _ChartEmpty extends StatelessWidget {
  const _ChartEmpty({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.green, size: 38),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, height: 1.35),
          ),
        ],
      ),
    );
  }
}
