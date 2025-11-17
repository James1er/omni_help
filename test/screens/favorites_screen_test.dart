import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_help/screens/favorites_screen.dart';

void main() {
  testWidgets('FavoritesScreen renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(home: FavoritesScreen()));

    // Verify that FavoritesScreen is rendered.
    expect(find.byType(FavoritesScreen), findsOneWidget);
  });
}
