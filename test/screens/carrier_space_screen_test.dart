import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_help/firebase_options.dart';
import 'package:omni_help/screens/carrier_space_screen.dart';
import '../main_test.dart'; // Import pour setupFirebaseCoreMocks

void main() {
  // --- NOUVEAU: Initialisation de Firebase pour les tests de ce fichier ---
  setUpAll(() async {
    // Assure que le binding de test est prêt.
    TestWidgetsFlutterBinding.ensureInitialized();
    // Simule les appels natifs de Firebase Core.
    setupFirebaseCoreMocks();
    // Initialise l'application Firebase dans l'environnement de test.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  });

  testWidgets('CarrierSpaceScreen renders correctly', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: CarrierSpaceScreen()));

    // Verify that CarrierSpaceScreen is rendered.
    expect(find.byType(CarrierSpaceScreen), findsOneWidget);
  });
}
