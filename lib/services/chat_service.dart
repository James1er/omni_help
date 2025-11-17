import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send message
  Future<void> sendMessage(String receiverId, String message) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      final String currentUserId = currentUser.uid;
      final String currentUserEmail = currentUser.email!;

      List<String> ids = [currentUserId, receiverId];
      ids.sort();
      String chatRoomId = ids.join('_');

      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .add({
        'senderId': currentUserId,
        'senderEmail': currentUserEmail,
        'receiverId': receiverId,
        'message': message,
        'timestamp': Timestamp.now(),
      });
    }
  }

  // Get messages
  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join('_');

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
