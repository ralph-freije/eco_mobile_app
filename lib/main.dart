import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/state/auth_controller.dart';
import 'core/state/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authController = AuthController();
  final themeController = ThemeController(
    await SharedPreferences.getInstance(),
  );
  await Future.wait([
    authController.initialize(),
    themeController.initialize(),
  ]);
  runApp(
    EcoTrackApp(
      authController: authController,
      themeController: themeController,
    ),
  );
}
