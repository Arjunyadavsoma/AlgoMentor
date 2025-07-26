import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dsa_question_model.dart';

class DSARepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<DSAQuestion>> fetchQuestions() async {
    final snapshot = await _firestore.collection('dsa_questions').get();
    return snapshot.docs
        .map((doc) => DSAQuestion.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> markQuestionSolved(String userId, String questionId, int score) async {
    final userRef = _firestore.collection('user_progress').doc(userId);

    await userRef.set({
      'solved_questions': FieldValue.arrayUnion([questionId]),
      'scores.$questionId': score,
      'last_active': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }
}
