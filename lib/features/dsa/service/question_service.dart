import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ Fetch all DSA questions from Firestore
  Future<List<Map<String, dynamic>>> fetchQuestions() async {
    try {
      final snapshot = await _firestore.collection('dsa_questions').get();

      if (snapshot.docs.isEmpty) return [];

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      throw Exception("❌ Failed to fetch questions: $e");
    }
  }
}
