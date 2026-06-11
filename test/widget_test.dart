import 'package:eco_sustainability_mobile/app.dart';
import 'package:eco_sustainability_mobile/core/state/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows login when unauthenticated', (tester) async {
    await tester.pumpWidget(EcoTrackApp(authController: AuthController()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
