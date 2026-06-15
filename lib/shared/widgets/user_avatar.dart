import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    required this.name,
    this.imageUrl,
    this.radius = 24,
    this.isActive,
    super.key,
  });

  final String name;
  final String? imageUrl;
  final double radius;
  final bool? isActive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    final url = imageUrl?.trim();
    final fallback = Container(
      width: radius * 2,
      height: radius * 2,
      color: colors.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? 'E' : initials,
        style: TextStyle(
          color: colors.onPrimaryContainer,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.62,
        ),
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipOval(
          child: url != null && url.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: url,
                  width: radius * 2,
                  height: radius * 2,
                  fit: BoxFit.cover,
                  placeholder: (context, imageUrl) => fallback,
                  errorWidget: (context, imageUrl, error) => fallback,
                )
              : fallback,
        ),
        if (isActive != null)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: radius * 0.48,
              height: radius * 0.48,
              decoration: BoxDecoration(
                color: isActive! ? AppColors.green : const Color(0xFF9AA8A7),
                shape: BoxShape.circle,
                border: Border.all(color: colors.surface, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
