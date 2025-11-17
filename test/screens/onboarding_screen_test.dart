import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_help/screens/onboarding_screen.dart';

void main() {
  testWidgets('OnboardingScreen renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(home: OnboardingScreen()));

    // Verify that OnboardingScreen is rendered.
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
}
