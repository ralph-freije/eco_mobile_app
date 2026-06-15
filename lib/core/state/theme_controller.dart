import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this._preferences);

  static const _preferenceKey = 'theme_mode';

  final SharedPreferences _preferences;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> initialize() async {
    _themeMode = switch (_preferences.getString(_preferenceKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _preferences.setString(_preferenceKey, mode.name);
  }

  Future<void> toggleBrightness(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return setThemeMode(
      brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }
}
