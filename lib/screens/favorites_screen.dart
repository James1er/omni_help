import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/project_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    // Si l'utilisateur n'est pas connecté, on affiche un message.
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mes Favoris')),
        body: const Center(
          child: Text('Veuillez vous connecter pour voir vos favoris.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mes Favoris')),
      // NOUVEAU: Utilisation de StreamBuilder pour les mises à jour en temps réel.
      body: StreamBuilder<QuerySnapshot>(
        // 1. On écoute la liste des IDs de projets favoris.
        stream: _firestore
            .collection('users')
            .doc(_currentUser.uid)
            .collection('favorites')
            .snapshots(),
        builder: (context, favoritesSnapshot) {
          if (favoritesSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (favoritesSnapshot.hasError) {
            return Center(
              child: Text(
                'Une erreur est survenue: ${favoritesSnapshot.error}',
              ),
            );
          }

          final favoriteIds =
              favoritesSnapshot.data?.docs.map((doc) => doc.id).toList() ?? [];

          if (favoriteIds.isEmpty) {
            return const Center(
              child: Text('Vous n\'avez encore aucun projet en favori.'),
            );
          }

          // 2. On utilise les IDs pour écouter les documents des projets correspondants.
          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('projects')
                .where(FieldPath.documentId, whereIn: favoriteIds)
                .snapshots(),
            builder: (context, projectsSnapshot) {
              if (projectsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final favoriteProjects = projectsSnapshot.data?.docs ?? [];

              return ListView.builder(
                itemCount: favoriteProjects.length,
                itemBuilder: (context, index) {
                  return ProjectCard(project: favoriteProjects[index]);
                },
              );
            },
          );
        },
      ),
    );
  }
}
