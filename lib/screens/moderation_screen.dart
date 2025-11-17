import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/project_card.dart';

class ModerationScreen extends StatefulWidget {
  const ModerationScreen({super.key});

  @override
  State<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends State<ModerationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // NOUVEAU: Gérer la logique de rejet avec une boîte de dialogue
  Future<void> _handleReject(String projectId) async {
    final reasonController = TextEditingController();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Motif du rejet'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Raison du rejet',
            hintText: 'Ex: Informations manquantes...',
          ),
          autofocus: true,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmer le rejet'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (reasonController.text.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Le motif du rejet est obligatoire.')),
          );
        }
        return;
      }
      await _updateProjectStatus(
        projectId,
        'Rejeté',
        reason: reasonController.text.trim(),
      );
    }
  }

  Future<void> _updateProjectStatus(
    String projectId,
    String newStatus, {
    String? reason,
  }) async {
    String statusMessage;
    final Map<String, dynamic> updateData = {'status': newStatus};

    if (newStatus == 'Validé') {
      statusMessage = 'Projet validé avec succès.';
      updateData['rejectionReason'] = FieldValue.delete();
    } else if (newStatus == 'Rejeté') {
      statusMessage = 'Projet rejeté.';
      updateData['rejectionReason'] = reason;
    } else {
      return; // Statut inconnu
    }

    try {
      await _firestore.collection('projects').doc(projectId).update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(statusMessage)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modération des Projets')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('projects')
            .where('status', isEqualTo: 'En attente de validation')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Une erreur est survenue: ${snapshot.error}'),
            );
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('Aucun projet en attente de validation.'),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final project = docs[index];
              return ProjectCard(
                project: project,
                // On affiche des actions spécifiques pour la modération
                showModeratorActions: true,
                onApprove: () => _updateProjectStatus(project.id, 'Validé'),
                onReject: () => _handleReject(project.id),
              );
            },
          );
        },
      ),
    );
  }
}
