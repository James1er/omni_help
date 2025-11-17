import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Modèle de donnée pour un message
class ChatMessage {
  final String senderId;
  final String senderName;
  final String text;
  final Timestamp timestamp;

  ChatMessage({
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> data) {
    return ChatMessage(
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Utilisateur Inconnu',
      text: data['text'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}

// Widget pour afficher un seul message
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const MessageBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = isMe ? theme.primaryColor : Colors.grey[300];
    final textColor = isMe ? Colors.white : Colors.black87;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        // Le nom de l'expéditeur n'est affiché que si ce n'est pas moi
        if (!isMe)
          Padding(
            padding: const EdgeInsets.only(left: 12.0, bottom: 2.0),
            child: Text(
              message.senderName,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),

        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: Radius.circular(isMe ? 12 : 0),
              bottomRight: Radius.circular(isMe ? 0 : 12),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Text(message.text, style: TextStyle(color: textColor)),
        ),
      ],
    );
  }
}

// Écran principal de la conversation
class ConversationScreen extends StatefulWidget {
  final String chatId;
  final String chatPartnerName;

  const ConversationScreen({
    super.key,
    required this.chatId,
    required this.chatPartnerName,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();

  User? get currentUser => _auth.currentUser;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Fonction d'envoi de message
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || currentUser == null) {
      return;
    }

    // Réinitialiser le champ de texte immédiatement
    _messageController.clear();

    // Assurez-vous que la vue défile jusqu'en bas après l'envoi
    _scrollToBottom();

    try {
      // 1. Définir le chemin vers la sous-collection 'messages'
      final messagesCollection = _firestore
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages');

      // 2. Créer l'objet message
      final messageData = {
        'text': text,
        'senderId': currentUser!.uid,
        'senderName': currentUser!.displayName ?? 'Utilisateur',
        'timestamp':
            FieldValue.serverTimestamp(), // Firestore gère le timestamp
      };

      // 3. Ajouter le message
      await messagesCollection.add(messageData);

      // 4. Mettre à jour le document parent 'chat' avec les métadonnées
      await _firestore.collection('chats').doc(widget.chatId).set({
        'lastMessage': text,
        'lastMessageSenderId': currentUser!.uid,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        // On s'assure que les noms des participants sont bien présents
        'participantNames.${currentUser!.uid}':
            currentUser!.displayName ?? 'Utilisateur',
        // Conserver l'ID du projet/partenaires pour l'affichage dans la liste
        'participants': [
          currentUser!.uid,
          widget.chatId.split('_')[1],
        ], // Simple simulation des participants
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Erreur lors de l\'envoi du message : $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Erreur: Message non envoyé. Vérifiez votre connexion.',
            ),
          ),
        );
      }
    }
  }

  // Fait défiler la liste vers le bas
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Veuillez vous connecter pour chatter.")),
      );
    }

    // Le StreamBuilder écoute les changements de la sous-collection 'messages'
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatPartnerName), // Nom du partenaire ou du projet
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Requête : messages pour cet ID de chat, triés par timestamp
              stream: _firestore
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy(
                    'timestamp', // Les plus anciens en premier
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Commencez la conversation !'),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erreur de chargement des messages: ${snapshot.error}',
                    ),
                  );
                }

                // Récupérer la liste des messages
                final List<QueryDocumentSnapshot> docs = snapshot.data!.docs;
                final List<ChatMessage> messages = docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return ChatMessage.fromMap(data);
                }).toList();

                // On s'assure de défiler jusqu'en bas après le premier chargement
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToBottom(),
                );

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 15),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    // Vérifier si le message vient de l'utilisateur actuel
                    final isMe = message.senderId == currentUser!.uid;

                    return MessageBubble(message: message, isMe: isMe);
                  },
                );
              },
            ),
          ),

          // Champ de saisie de message
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Écrire un message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  mini: true,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
