import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'ecotrack_logo.dart';
import 'rounded_card.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Stack(
        children: [
          const Positioned(
            top: -90,
            right: -70,
            child: _Glow(size: 260, color: Color(0x5529C889)),
          ),
          const Positioned(
            bottom: 40,
            left: -120,
            child: _Glow(size: 300, color: Color(0x332E7B86)),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 34),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const EcoTrackLogo(light: true),
                      const SizedBox(height: 34),
                      RoundedCard(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
                        child: child,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Small choices. Measurable impact.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white60,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthHeader extends StatelessWidget {
  const AuthHeader({required this.title, required this.subtitle, super.key});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: AppColors.mint,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.eco_rounded, color: AppColors.green, size: 32),
        ),
        const SizedBox(height: 18),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 7),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, height: 1.45),
        ),
      ],
    );
  }
}

class AuthMessage extends StatelessWidget {
  const AuthMessage({required this.message, this.isSuccess = false, super.key});

  final String message;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final color = isSuccess ? AppColors.greenDark : AppColors.danger;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        message,
        style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
