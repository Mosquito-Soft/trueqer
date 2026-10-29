import 'package:cloud_firestore/cloud_firestore.dart';

/// User profile and peer discovery service connecting directly to Firestore.
class FirestoreUserService {
  final FirebaseFirestore _firestore;

  FirestoreUserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  /// Saves or updates the user profile document in /users/{userId}.
  Future<void> saveUserProfile({
    required String userId,
    required String displayName,
    String? bio,
    String? avatarUrl,
    String? zoneName,
    Map<String, double>? fuzzyLocation,
    String? h3Index,
    List<Map<String, dynamic>> offeredSkills = const [],
    List<Map<String, dynamic>> desiredSkills = const [],
  }) async {
    await _usersRef.doc(userId).set({
      'userId': userId,
      'displayName': displayName,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'zoneName': zoneName ?? 'Community Area',
      'fuzzyLocation': fuzzyLocation,
      'h3Index': h3Index,
      'isAvailable': true,
      'averageRating': 0.0,
      'totalSwaps': 0,
      'totalReviews': 0,
      'punctualityScore': 0.0,
      'offeredSkills': offeredSkills,
      'desiredSkills': desiredSkills,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Streams the profile of a single user.
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUserProfile(String userId) {
    return _usersRef.doc(userId).snapshots();
  }

  /// Streams available users for peer discovery / swap browsing.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAvailableUsers() {
    return _usersRef
        .where('isAvailable', isEqualTo: true)
        .limit(30)
        .snapshots();
  }
}
