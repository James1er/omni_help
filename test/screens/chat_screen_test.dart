import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:omni_help/screens/chat_screen.dart';
import 'package:omni_help/services/chat_service.dart';

import 'chat_screen_test.mocks.dart';

@GenerateMocks([ChatService])
void main() {
  late MockChatService mockChatService;

  setUp(() {
    mockChatService = MockChatService();
  });

  testWidgets('ChatScreen UI Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(
      home: ChatScreen(
        receiverEmail: 'test@example.com',
        receiverId: '123',
        chatService: mockChatService,
      ),
    ));

    // Verify that the app bar title is correct.
    expect(find.text('test@example.com'), findsOneWidget);

    // Verify that the message input field and send button are present.
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);
  });

  testWidgets('Sending a message calls ChatService', (WidgetTester tester) async {
    // Stub the sendMessage method
    when(mockChatService.sendMessage(any, any)).thenAnswer((_) async => {});

    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(
      home: ChatScreen(
        receiverEmail: 'test@example.com',
        receiverId: '123',
        chatService: mockChatService,
      ),
    ));

    // Enter a message in the text field.
    await tester.enterText(find.byType(TextField), 'Hello!');
    await tester.pump();

    // Tap the send button.
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    // Verify that the sendMessage method was called.
    verify(mockChatService.sendMessage('123', 'Hello!')).called(1);
  });
}