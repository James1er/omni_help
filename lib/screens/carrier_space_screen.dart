import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../widgets/project_card.dart'; // Pour réutiliser la carte de projet
import 'project_form_screen.dart'; // Pour la modification

class CarrierSpaceScreen extends StatefulWidget {
  const CarrierSpaceScreen({super.key});

  @override
  State<CarrierSpaceScreen> createState() => _CarrierSpaceScreenState();
}

class _CarrierSpaceScreenState extends State<CarrierSpaceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Demande à l'utilisateur d'entrer l'UID à promouvoir, puis appelle la Cloud Function
  Future<void> _promoteUserToAdmin() async {
    final TextEditingController controller = TextEditingController();
    // It's important to dispose the controller when it's no longer needed.
    // We'll use a finally block to ensure it's always disposed.
    try {
      // Capture context-dependent objects before async gaps.
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      final bool? ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Promouvoir un utilisateur'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'UID de l\'utilisateur',
              hintText: 'Saisissez l\'UID Firebase de l\'utilisateur',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => navigator.pop(true),
              child: const Text('Promouvoir'),
            ),
          ],
        ),
      );

      // After an async gap, we must check if the widget is still mounted.
      if (ok != true || !mounted) return;

      final uid = controller.text.trim();
      if (uid.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('UID vide — opération annulée.')),
        );
        return;
      }

      try {
        final result = await _functions.httpsCallable('setAdminRole').call({
          'uid': uid,
        });
        final message = (result.data is Map && result.data['message'] != null)
            ? result.data['message'].toString()
            : 'Opération terminée.';
        if (mounted) {
          scaffoldMessenger.showSnackBar(SnackBar(content: Text(message)));
        }
      } on FirebaseFunctionsException catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Erreur Cloud Function: ${e.message}')),
          );
        }
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(SnackBar(content: Text('Erreur: $e')));
        }
      }
    } finally {
      controller.dispose();
    }
  }

  // Supprime un projet + fichiers associés en sécurité
  Future<void> _deleteProject(
    QueryDocumentSnapshot<Map<String, dynamic>> project,
  ) async {
    // It's a good practice to capture the context-dependent objects before an async gap.
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
          'Voulez-vous vraiment supprimer ce projet ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => navigator.pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => navigator.pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final data = project.data();

      // Helper to safely delete a file from a URL
      Future<void> deleteFileFromUrl(dynamic urlValue) async {
        if (urlValue is String && urlValue.isNotEmpty) {
          try {
            await _storage.refFromURL(urlValue).delete();
          } catch (e) {
            // Log error for debugging, but don't block project deletion
            debugPrint('Failed to delete file at $urlValue: $e');
          }
        }
      }

      // --- DÉBUT DE LA LOGIQUE DE SUPPRESSION COMPLÉTÉE ---
      // 1. Supprimer le fichier média associé (en supposant que l'URL est stockée dans 'mediaUrl')
      await deleteFileFromUrl(data['mediaUrl']);

      // 2. Supprimer le document de Firestore
      await _firestore.collection('projects').doc(project.id).delete();

      // 3. Afficher le message de succès
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Projet et médias associés supprimés avec succès.'),
          ),
        );
      }
      // --- FIN DE LA LOGIQUE DE SUPPRESSION COMPLÉTÉE ---
    } catch (e) {
      // Afficher l'erreur si la suppression de Firestore échoue
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression du projet : $e'),
          ),
        );
      }
    }
  }

  // Ouvre l'écran de modification en passant le document à éditer
  void _editProject(QueryDocumentSnapshot<Map<String, dynamic>> project) {
    Navigator.of(context).push(
      MaterialPageRoute(
        // Le widget 'ProjectFormScreen' doit accepter un 'projectToEdit' de type QueryDocumentSnapshot
        builder: (context) => ProjectFormScreen(projectToEdit: project),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mon Espace Porteur')),
        body: const Center(
          child: Text('Veuillez vous connecter pour voir vos projets.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Espace Porteur'),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: _promoteUserToAdmin,
            tooltip: 'Promouvoir un utilisateur Admin',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('projects')
            .where('ownerId', isEqualTo: currentUser.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Une erreur est survenue.'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('Vous n\'avez encore soumis aucun projet.'),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final project = docs[index];
              return ProjectCard(
                // On passe les données complètes à la carte
                project: project,
                showAdminActions: true,
                onEdit: () => _editProject(project),
                onDelete: () => _deleteProject(project),
              );
            },
          );
        },
      ),
    );
  }
}
