import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_help/screens/moderation_screen.dart';

void main() {
  testWidgets('ModerationScreen renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(home: ModerationScreen()));

    // Verify that ModerationScreen is rendered.
    expect(find.byType(ModerationScreen), findsOneWidget);
  });
}
