import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'conversation_screen.dart'; // Assurez-vous que ce fichier existe

class ConversationsListScreen extends StatelessWidget {
  const ConversationsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Conversations')),
        body: const Center(
          child: Text('Veuillez vous connecter pour voir vos messages.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Conversations')),
      body: StreamBuilder<QuerySnapshot>(
        // On écoute les chats où l'utilisateur actuel est un participant
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUser.uid)
            .orderBy('lastMessageTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Une erreur est survenue.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Aucune conversation pour le moment.'),
            );
          }

          final conversations = snapshot.data!.docs;

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final doc = conversations[index];
              final data = doc.data() as Map<String, dynamic>;

              // Trouver l'autre participant
              final List<dynamic> participants = data['participants'];
              final otherUserId = participants.firstWhere(
                (id) => id != currentUser.uid,
                orElse: () => null,
              );
              final participantNames =
                  data['participantNames'] as Map<String, dynamic>? ?? {};
              final otherUserName =
                  participantNames[otherUserId] ?? 'Utilisateur';

              final lastMessage =
                  data['lastMessage'] as String? ?? 'Pas encore de message.';

              return ListTile(
                leading: CircleAvatar(
                  child: Text(otherUserName.substring(0, 1).toUpperCase()),
                ),
                title: Text(
                  otherUserName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(lastMessage, overflow: TextOverflow.ellipsis),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ConversationScreen(
                        chatId: doc.id,
                        chatPartnerName: otherUserName,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
