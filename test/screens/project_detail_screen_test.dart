import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:omni_help/screens/project_detail_screen.dart';

// --- Configuration Mockito ---
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
// 🚨 CORRECTION : Chemin Relatif le plus simple et direct.
// Ce fichier doit se trouver dans le même dossier que le fichier de test.
import 'project_detail_screen_test.mocks.dart';

// Crée la "doublure" (mock) de la classe Firestore
@GenerateMocks([QueryDocumentSnapshot])
void main() {
  // Déclaration tardive du Mock
  // Le type MockQueryDocumentSnapshot est importé du fichier .mocks.dart
  late MockQueryDocumentSnapshot mockProjectSnapshot;

  // Données factices que l'écran de détail lira
  final Map<String, dynamic> projectData = {
    // 💡 IMPORTANT : Ajoutez ici toutes les clés que ProjectDetailScreen.dart lit.
    'title': 'Projet Test Mockito',
    'description': 'Description du projet pour le test.',
    'ownerId': 'user123',
    'budget': 5000,
  };

  setUp(() {
    // 1. Initialise le mock avant chaque test
    mockProjectSnapshot = MockQueryDocumentSnapshot();

    // 2. Définir le comportement : Quand .data() est appelé, il doit retourner nos données factices
    when(mockProjectSnapshot.data()).thenReturn(projectData);

    // 3. Définir les autres propriétés minimales requises
    when(mockProjectSnapshot.id).thenReturn('project_id_test');
    when(mockProjectSnapshot.exists).thenReturn(true);
  });

  testWidgets('ProjectDetailScreen renders correctly with Mockito Snapshot', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        // 🚨 CORRECTION : On passe l'objet Mockito forcé au type attendu par l'écran
        home: ProjectDetailScreen(
          project: mockProjectSnapshot as QueryDocumentSnapshot<Object?>,
        ),
      ),
    );

    // Vérifie que l'écran ProjectDetailScreen est rendu.
    expect(find.byType(ProjectDetailScreen), findsOneWidget);

    // Vérifie que le titre factice est affiché dans le widget
    expect(find.text('Projet Test Mockito'), findsOneWidget);
  });
}
