import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/theme_controller.dart';

class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<ThemeController>().themeMode;
    return SegmentedButton<ThemeMode>(
      showSelectedIcon: false,
      expandedInsets: EdgeInsets.zero,
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
      ),
      segments: const [
        ButtonSegment(
          value: ThemeMode.system,
          icon: Icon(Icons.brightness_auto_rounded),
          label: Text('System'),
        ),
        ButtonSegment(
          value: ThemeMode.light,
          icon: Icon(Icons.light_mode_rounded),
          label: Text('Light'),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          icon: Icon(Icons.dark_mode_rounded),
          label: Text('Dark'),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (selection) {
        context.read<ThemeController>().setThemeMode(selection.first);
      },
    );
  }
}
