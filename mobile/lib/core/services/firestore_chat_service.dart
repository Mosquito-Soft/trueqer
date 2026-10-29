import 'package:cloud_firestore/cloud_firestore.dart';

/// Real-time chat service for swaps using Firestore subcollections.
class FirestoreChatService {
  final FirebaseFirestore _firestore;

  FirestoreChatService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _messagesRef(String swapId) =>
      _firestore.collection('swaps').doc(swapId).collection('messages');

  /// Sends a guided message within a swap.
  /// Enforces client guardrail of 300 characters max.
  Future<void> sendMessage({
    required String swapId,
    required String senderId,
    required String content,
    String messageType = 'TEXT', // TEXT | QUICK_REPLY | ACTION_WIDGET
    Map<String, dynamic>? widgetPayload,
  }) async {
    final cleanContent = content.trim();
    if (cleanContent.isEmpty) {
      throw ArgumentError('Message content cannot be empty.');
    }
    if (cleanContent.length > 300) {
      throw ArgumentError('Message exceeds maximum limit of 300 characters.');
    }

    final messageDoc = _messagesRef(swapId).doc();

    await messageDoc.set({
      'messageId': messageDoc.id,
      'senderId': senderId,
      'messageType': messageType,
      'content': cleanContent,
      'widgetPayload': widgetPayload,
      'isSystem': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Bump parent swap updatedAt timestamp
    await _firestore.collection('swaps').doc(swapId).update({
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Real-time stream of messages for a given swap.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamMessages(String swapId) {
    return _messagesRef(swapId)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }
}
