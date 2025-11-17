import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import pour le type de données
import 'package:omni_help/screens/conversation_screen.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Pour l'utilisateur connecté

class ProjectDetailScreen extends StatefulWidget {
  // ✅ CORRECTION: Accepter un DocumentSnapshot complet
  final QueryDocumentSnapshot project;
  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  // --- NOUVEAU: Contrôleur pour le champ de commentaire ---
  final TextEditingController _commentController = TextEditingController();
  // NOUVEAU: Référence à l'utilisateur actuel
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isPostingComment = false;

  @override
  void initState() {
    super.initState();
    // On incrémente le compteur de vues en arrière-plan dès que l'écran est chargé.
    _incrementViewCount();
  }

  // --- NOUVEAU: Méthode pour incrémenter le compteur de vues ---
  Future<void> _incrementViewCount() async {
    try {
      // Utilise FieldValue.increment(1) pour augmenter la valeur de manière atomique.
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.project.id)
          .update({'views': FieldValue.increment(1)});
    } catch (e) {
      // Gérer l'erreur si nécessaire, mais ne pas bloquer l'utilisateur.
      debugPrint("Erreur lors de l'incrémentation des vues: $e");
    }
  }

  // --- NOUVEAU: Méthode pour poster un commentaire ---
  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) {
      return; // Ne rien faire si le commentaire est vide
    }
    if (_currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous devez être connecté pour commenter.'),
          ),
        );
      }
      return;
    }

    setState(() => _isPostingComment = true);

    try {
      // Ajoute un nouveau document dans la sous-collection 'comments' du projet
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.project.id)
          .collection('comments')
          .add({
            'text': _commentController.text.trim(),
            'authorName': _currentUser.displayName ?? _currentUser.email,
            'authorId': _currentUser.uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
      _commentController.clear(); // Vider le champ après l'envoi
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'envoi du commentaire: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPostingComment = false);
      }
    }
  }

  // --- NOUVEAU: Méthode pour contacter le porteur (par email ou chat) ---
  Future<void> _contactOwner() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez vous connecter pour contacter le porteur.'),
        ),
      );
      return;
    }

    final data = widget.project.data() as Map<String, dynamic>;
    final ownerId = data['ownerId'];
    final ownerName = data['ownerName'] ?? 'Porteur inconnu';

    if (_currentUser.uid == ownerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous ne pouvez pas vous contacter vous-même.'),
        ),
      );
      return;
    }

    // Créer un ID de chat unique et cohérent
    final ids = [_currentUser.uid, ownerId];
    ids.sort(); // Trier pour que l'ID soit toujours le même
    final chatId = ids.join('_');

    // Créer le document de chat s'il n'existe pas
    final chatDoc = FirebaseFirestore.instance.collection('chats').doc(chatId);
    await chatDoc.set({
      'participants': ids,
      'participantNames': {
        _currentUser.uid: _currentUser.displayName,
        ownerId: ownerName,
      },
    }, SetOptions(merge: true));

    // Naviguer vers l'écran de conversation
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ConversationScreen(chatId: chatId, chatPartnerName: ownerName),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // ... (le reste du code de _ProjectDetailScreenState reste identique)
  // Assurez-vous d'avoir un bouton qui appelle _contactOwner()

  @override
  Widget build(BuildContext context) {
    // Extraire les données pour un accès plus facile
    final data = widget.project.data() as Map<String, dynamic>;
    final String title = data['title'] ?? 'Titre non disponible';
    final String description = data['description'] ?? 'Pas de description.';
    final String ownerName = data['ownerName'] ?? 'Porteur inconnu';
    final String ownerId = data['ownerId'] ?? 'N/A';
    final String? imageUrl = data['mainImageUrl'];

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        children: [
          // ✅ CORRECTION: Afficher l'image principale si elle existe
          if (imageUrl != null)
            Image.network(
              imageUrl,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Par $ownerName',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                ),
                const Divider(height: 30),

                // --- NOUVEAU: Affichage du compteur de vues avec un StreamBuilder ---
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('projects')
                      .doc(widget.project.id)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink(); // Ne rien afficher si pas de données
                    }
                    final projectData =
                        snapshot.data!.data() as Map<String, dynamic>?;
                    final views = projectData?['views'] ?? 0;
                    return Row(
                      children: [
                        const Icon(
                          Icons.visibility,
                          color: Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$views vues',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(description, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 20),
                // Bouton pour contacter le porteur
                if (_currentUser != null && _currentUser.uid != ownerId)
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _contactOwner,
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Contacter le Porteur'),
                    ),
                  ),
                const Divider(height: 40),

                // --- NOUVEAU: Section des commentaires ---
                Text(
                  'Commentaires',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // --- Champ pour poster un commentaire ---
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          labelText: 'Ajouter un commentaire...',
                          border: OutlineInputBorder(),
                        ),
                        enabled: !_isPostingComment,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _isPostingComment
                        ? const CircularProgressIndicator()
                        : IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: _postComment,
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- Liste des commentaires ---
                StreamBuilder<QuerySnapshot>(
                  // On écoute la sous-collection 'comments'
                  stream: FirebaseFirestore.instance
                      .collection('projects')
                      .doc(widget.project.id)
                      .collection('comments')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text('Soyez le premier à commenter !'),
                      );
                    }

                    final comments = snapshot.data!.docs;
                    return ListView.builder(
                      shrinkWrap: true, // Important dans un ListView parent
                      physics:
                          const NeverScrollableScrollPhysics(), // Pour éviter le double scroll
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return ListTile(
                          title: Text(
                            comment['authorName'] ?? 'Anonyme',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(comment['text'] ?? ''),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
