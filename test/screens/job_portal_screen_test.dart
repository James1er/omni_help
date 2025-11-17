import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_help/screens/job_portal_screen.dart';

void main() {
  testWidgets('JobPortalScreen renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(home: JobPortalScreen()));

    // Verify that JobPortalScreen is rendered.
    expect(find.byType(JobPortalScreen), findsOneWidget);
  });
}
