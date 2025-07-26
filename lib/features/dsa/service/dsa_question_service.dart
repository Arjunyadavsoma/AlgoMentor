import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class DSAQuestionService {
  Future<List<Map<String, dynamic>>> getQuestions() async {
    try {
      // ✅ Load JSON file
      final String response = await rootBundle.loadString('assets/data/dsa_questions.json');
      final Map<String, dynamic> data = json.decode(response);

      // ✅ Extract "topics" list
      List<Map<String, dynamic>> topics = List<Map<String, dynamic>>.from(data['topics']);

      return topics;
    } catch (e) {
      throw Exception("❌ Failed to load questions: $e");
    }
  }
}
