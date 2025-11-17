import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_help/screens/project_form_screen.dart';

void main() {
  testWidgets('ProjectFormScreen renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(home: ProjectFormScreen()));

    // Verify that ProjectFormScreen is rendered.
    expect(find.byType(ProjectFormScreen), findsOneWidget);
  });
}
