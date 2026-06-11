import 'package:flutter/material.dart';

import 'app.dart';
import 'core/state/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authController = AuthController();
  await authController.initialize();
  runApp(EcoTrackApp(authController: authController));
}
