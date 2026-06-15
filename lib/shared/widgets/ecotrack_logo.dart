import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class EcoTrackLogo extends StatelessWidget {
  const EcoTrackLogo({
    this.light = false,
    this.compact = false,
    super.key,
  });

  final bool light;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 46.0 : 62.0;
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(compact ? 13 : 18),
          child: Image.asset(
            'assets/images/ecotrack-logo.png',
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(compact ? 13 : 18),
              ),
              child: Icon(
                Icons.eco_rounded,
                color: Colors.white,
                size: compact ? 26 : 34,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'EcoTrack',
              style: TextStyle(
                color: light ? Colors.white : colors.onSurface,
                fontSize: compact ? 19 : 23,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            Text(
              'Carbon Tracking',
              style: TextStyle(
                color: light ? Colors.white70 : colors.onSurfaceVariant,
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
