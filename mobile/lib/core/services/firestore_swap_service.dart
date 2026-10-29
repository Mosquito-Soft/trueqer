import 'package:cloud_firestore/cloud_firestore.dart';

/// Client-side Firestore Swap Service for direct mobile demo integration.
/// Handles proposal creation, real-time state machine transitions, and swap streams.
class FirestoreSwapService {
  final FirebaseFirestore _firestore;

  FirestoreSwapService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _swapsRef =>
      _firestore.collection('swaps');

  /// Creates a new swap proposal with PENDING status.
  Future<String> createProposal({
    required String requesterId,
    required String receiverId,
    required Map<String, dynamic> offeredSkill,
    required Map<String, dynamic> requestedSkill,
    required String initialMessage,
  }) async {
    final swapDoc = _swapsRef.doc();

    await _firestore.runTransaction((transaction) async {
      transaction.set(swapDoc, {
        'swapId': swapDoc.id,
        'requesterId': requesterId,
        'receiverId': receiverId,
        'participants': [requesterId, receiverId],
        'offeredSkill': offeredSkill,
        'requestedSkill': requestedSkill,
        'status': 'PENDING',
        'scheduledAt': null,
        'completedAt': null,
        'meetingLocation': null,
        'cancellationReason': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Add initial context message in subcollection
      final messageDoc = swapDoc.collection('messages').doc();
      transaction.set(messageDoc, {
        'messageId': messageDoc.id,
        'senderId': requesterId,
        'messageType': 'TEXT',
        'content': initialMessage,
        'widgetPayload': null,
        'isSystem': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    return swapDoc.id;
  }

  /// Transitions the swap status (Double Opt-In, Scheduling, Cancellation).
  Future<void> updateStatus({
    required String swapId,
    required String action, // ACCEPT, REJECT, SCHEDULE, CANCEL, COMPLETE
    DateTime? scheduledAt,
    String? meetingLocation,
    String? cancellationReason,
  }) async {
    final docRef = _swapsRef.doc(swapId);

    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    switch (action) {
      case 'ACCEPT':
        updates['status'] = 'MATCHED';
        break;
      case 'REJECT':
        updates['status'] = 'REJECTED';
        break;
      case 'SCHEDULE':
        updates['status'] = 'SCHEDULED';
        if (scheduledAt != null) {
          updates['scheduledAt'] = Timestamp.fromDate(scheduledAt);
        }
        if (meetingLocation != null) {
          updates['meetingLocation'] = meetingLocation;
        }
        break;
      case 'CANCEL':
        updates['status'] = 'CANCELLED';
        if (cancellationReason != null) {
          updates['cancellationReason'] = cancellationReason;
        }
        break;
      case 'COMPLETE':
        updates['status'] = 'COMPLETED';
        updates['completedAt'] = FieldValue.serverTimestamp();
        break;
      default:
        throw ArgumentError('Invalid swap action: $action');
    }

    await docRef.update(updates);
  }

  /// Real-time stream of all swaps where the user is a participant.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamMySwaps(String userId) {
    return _swapsRef
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  /// Real-time stream of a single swap document.
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamSwap(String swapId) {
    return _swapsRef.doc(swapId).snapshots();
  }
}
