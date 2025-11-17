import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_help/screens/conversation_screen.dart';

void main() {
  testWidgets('ConversationScreen renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(
        home: ConversationScreen(
      chatId: 'test_chat_id',
      chatPartnerName: 'Test Partner',
    )));

    // Verify that ConversationScreen is rendered.
    expect(find.byType(ConversationScreen), findsOneWidget);
  });
}
