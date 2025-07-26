import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ Mark a question as solved and update progress summary
  Future<void> markQuestionSolved(String userId, String questionId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      // ✅ 1. Mark question as solved in subcollection
      await userRef.collection('progress').doc(questionId).set({
        'solved': true,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // ✅ 2. Update summary fields in main user document
      await userRef.set({
        'solvedCount': FieldValue.increment(1),
        'solvedQuestions': FieldValue.arrayUnion([questionId]),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception("❌ Failed to mark question solved: $e");
    }
  }

  /// ✅ Unmark a question (remove from progress)
  Future<void> unmarkQuestion(String userId, String questionId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      // ✅ 1. Delete question from progress subcollection
      await userRef.collection('progress').doc(questionId).delete();

      // ✅ 2. Update summary fields
      await userRef.set({
        'solvedCount': FieldValue.increment(-1),
        'solvedQuestions': FieldValue.arrayRemove([questionId]),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception("❌ Failed to unmark question: $e");
    }
  }

  /// ✅ Fetch all solved questions + summary for a user
  Future<Map<String, dynamic>> getUserProgress(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final progressSnapshot = await userDoc.reference.collection('progress').get();

      return {
        'solvedCount': userDoc.data()?['solvedCount'] ?? 0,
        'solvedQuestions': List<String>.from(userDoc.data()?['solvedQuestions'] ?? []),
        'progressMap': {
          for (var doc in progressSnapshot.docs) doc.id: doc['solved'] as bool,
        }
      };
    } catch (e) {
      throw Exception("❌ Failed to fetch user progress: $e");
    }
  }

  /// ✅ Alias for backward compatibility (returns summary + progress map)
  Future<Map<String, dynamic>> getProgress(String userId) async {
    return await getUserProgress(userId);
  }

  /// ✅ Stream real-time progress updates
  Stream<Map<String, bool>> streamUserProgress(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('progress')
        .snapshots()
        .map((snapshot) {
      return {
        for (var doc in snapshot.docs) doc.id: doc['solved'] as bool,
      };
    });
  }
}
