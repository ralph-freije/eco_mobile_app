import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class LoadingState extends StatelessWidget {
  const LoadingState({this.label = 'Loading...', super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.green),
            const SizedBox(height: 14),
            Text(label, style: const TextStyle(color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
