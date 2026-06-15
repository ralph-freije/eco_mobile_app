import 'package:eco_sustainability_mobile/app.dart';
import 'package:eco_sustainability_mobile/core/state/auth_controller.dart';
import 'package:eco_sustainability_mobile/core/state/theme_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows login when unauthenticated', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final themeController = ThemeController(
      await SharedPreferences.getInstance(),
    );

    await tester.pumpWidget(
      EcoTrackApp(
        authController: AuthController(),
        themeController: themeController,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
