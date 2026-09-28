import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:guardian_shield_app/main.dart';
import 'package:guardian_shield_app/services/emergency_orchestrator.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => EmergencyOrchestrator()),
        ],
        child: const GuardianShieldApp(isConfigured: false),
      ),
    );

    // Verify that the app title or onboarding screen content is present.
    // Since isConfigured is false, it should show LegalConsentScreen.
    expect(find.text('Safety & Privacy Setup'), findsOneWidget);
  });
}
