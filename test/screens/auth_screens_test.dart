import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_help/firebase_options.dart';
import 'package:omni_help/screens/auth_screens.dart';

import '../main_test.dart';

void main() {
  // Initialiser Firebase pour tous les tests de ce fichier.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  });

  group('Auth Screens', () {
    testWidgets('AuthChoiceScreen renders correctly and shows all buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: AuthChoiceScreen()));

      // Verify that AuthChoiceScreen is rendered.
      expect(find.byType(AuthChoiceScreen), findsOneWidget);

      // Verify content
      expect(find.text('Rejoignez la communauté'), findsOneWidget);
      expect(
        find.widgetWithText(ElevatedButton, 'J\'ai déjà un compte'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(OutlinedButton, 'Créer mon compte'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(ElevatedButton, 'Se connecter avec Google'),
        findsOneWidget,
      );
    });

    testWidgets(
      'LoginScreen renders correctly with email and password fields',
      (WidgetTester tester) async {
        await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

        // Verify that LoginScreen is rendered.
        expect(find.byType(LoginScreen), findsOneWidget);

        // Verify content
        expect(find.text('Adresse E-mail'), findsOneWidget);
        expect(find.text('Mot de passe'), findsOneWidget);
        expect(
          find.widgetWithText(ElevatedButton, 'Se connecter'),
          findsOneWidget,
        );
      },
    );

    testWidgets('RegistrationScreen renders correctly with all fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: RegistrationScreen()));

      // Verify that RegistrationScreen is rendered.
      expect(find.byType(RegistrationScreen), findsOneWidget);

      // Verify content
      expect(find.text('Nom d\'utilisateur'), findsOneWidget);
      expect(find.text('Adresse E-mail'), findsOneWidget);
      expect(find.text('Mot de passe (6 caractères minimum)'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
      expect(
        find.text('J\'accepte les Conditions d\'utilisation'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(ElevatedButton, 'S\'inscrire'),
        findsOneWidget,
      );
    });
  });
}
