import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/project_detail_screen.dart';
import '../screens/chat_screen.dart';

class ProjectCard extends StatefulWidget {
  final QueryDocumentSnapshot project;
  final bool showAdminActions;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showModeratorActions;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const ProjectCard({
    super.key,
    required this.project,
    this.showAdminActions = false,
    this.onEdit,
    this.onDelete,
    this.showModeratorActions = false,
    this.onApprove,
    this.onReject,
  });

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> {
  bool _isFavorited = false;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _checkIfFavorited();
  }

  Future<void> _checkIfFavorited() async {
    if (_currentUser == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser.uid)
        .collection('favorites')
        .doc(widget.project.id)
        .get();
    if (mounted) {
      setState(() {
        _isFavorited = doc.exists;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_currentUser == null) return;
    final favoriteRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser.uid)
        .collection('favorites')
        .doc(widget.project.id);

    if (_isFavorited) {
      await favoriteRef.delete();
    } else {
      await favoriteRef.set({'favoritedAt': FieldValue.serverTimestamp()});
    }
    if (mounted) {
      setState(() {
        _isFavorited = !_isFavorited;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectData = widget.project.data() as Map<String, dynamic>;

    // Helper to safely get values from the map
    T? getValue<T>(String key, [T? defaultValue]) {
      return projectData.containsKey(key)
          ? projectData[key] as T?
          : defaultValue;
    }

    final mainImageUrl = getValue<String>('mainImageUrl');
    final title = getValue<String>('title', 'Titre non disponible');
    final ownerName = getValue<String>('ownerName', 'Porteur inconnu');
    final ownerId = getValue<String>('ownerId');
    final ownerEmail = getValue<String>('ownerEmail');
    final status = getValue<String>('status');
    final rejectionReason = getValue<String>('rejectionReason');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: (mainImageUrl != null && mainImageUrl.isNotEmpty)
                  ? Image.network(
                      mainImageUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 150,
                          color: Colors.lightBlue.shade100,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 150,
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Container(
                      height: 150,
                      color: Colors.lightBlue.shade100,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.blue,
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isFavorited ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorited ? Colors.red : Colors.grey,
                  ),
                  onPressed: _toggleFavorite,
                  tooltip: 'Ajouter aux favoris',
                ),
                if (widget.showAdminActions)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') widget.onEdit?.call();
                      if (value == 'delete') widget.onDelete?.call();
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Text('Modifier'),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Text('Supprimer'),
                          ),
                        ],
                  ),
              ],
            ),
            Text('Par: $ownerName', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            if (status != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (status == 'Rejeté')
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Projet Rejeté',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (rejectionReason != null &&
                                rejectionReason.isNotEmpty)
                              Text('Motif: $rejectionReason'),
                          ],
                        ),
                      )
                    else if (status == 'En attente de validation')
                      Text(
                        'Statut: $status',
                        style: const TextStyle(color: Colors.orange),
                      ),
                  ],
                ),
              ),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8.0, // Espace horizontal entre les boutons
              runSpacing: 4.0, // Espace vertical si les boutons passent à la ligne
              children: <Widget>[
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            ProjectDetailScreen(project: widget.project),
                      ),
                    );
                  },
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('Explorer le projet'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (ownerId != null && ownerEmail != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            receiverId: ownerId,
                            receiverEmail: ownerEmail,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Impossible de contacter le porteur du projet.'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.message, size: 18),
                  label: const Text('Joindre le porteur'),
                ),
              ],
            ),
            if (widget.showModeratorActions)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: TextButton.icon(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        label: const Text(
                          'Valider',
                          style: TextStyle(color: Colors.green),
                        ),
                        onPressed: widget.onApprove,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: TextButton.icon(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        label: const Text(
                          'Rejeter',
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: widget.onReject,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
