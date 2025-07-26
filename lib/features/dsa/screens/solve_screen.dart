import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/features/authentication/chatbot/data/chatbot_service.dart';
import 'package:myapp/features/dsa/screens/FeedbackScreen.dart';

class SolveScreen extends StatefulWidget {
  final String question;
  final String questionId;
  final String userId;
  final String topic;        // ✅ Store topic in Firestore
  final String difficulty;   // ✅ Store difficulty in Firestore

  const SolveScreen({
    super.key,
    required this.question,
    required this.questionId,
    required this.userId,
    required this.topic,
    required this.difficulty,
  });

  @override
  State<SolveScreen> createState() => _SolveScreenState();
}

class _SolveScreenState extends State<SolveScreen> {
  final ChatbotService _chatbotService = ChatbotService();
  final TextEditingController _codeController = TextEditingController();
  bool isLoading = false;

  /// ✅ Function to send code to AI, save everything in Firestore,
  /// and navigate to the FeedbackScreen.
  Future<void> _submitSolution() async {
    final userCode = _codeController.text.trim();
    if (userCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please write a solution before submitting!")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // ✅ 1. Ask AI for feedback on the user solution
      final aiResponse = await _chatbotService.sendMessage("""
You are an expert DSA mentor.

Here is a student's solution for the problem: "${widget.question}".

---
$userCode
---

👉 Rate this code from 1 to 10.
👉 Explain why you gave that rating.
👉 List all pros and cons (readability, time complexity, space complexity, coding style, edge cases).
👉 Suggest 1–2 improvements.
Format your response in **Markdown**.
""");

      // ✅ 2. Save EVERYTHING to Firestore under user's solved questions
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('solvedQuestions')
          .doc(widget.questionId)
          .set({
        'questionId': widget.questionId,
        'question': widget.question,
        'topic': widget.topic,
        'difficulty': widget.difficulty,
        'solution': userCode,
        'aiFeedback': aiResponse,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() => isLoading = false);

      // ✅ 3. Navigate to feedback screen to show AI response
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FeedbackScreen(
            aiResponse: aiResponse,
            question: widget.question,
          ),
        ),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error saving solution: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Solve DSA Question")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📝 Show question
              Text(
                widget.question,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // ✍️ Code input area (Expanded so user can write long code)
              Expanded(
                child: TextField(
                  controller: _codeController,
                  maxLines: null,
                  expands: true,
                  keyboardType: TextInputType.multiline,
                  decoration: InputDecoration(
                    hintText: "✍️ Write your solution here...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 🚀 Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Submit Solution"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: isLoading ? null : _submitSolution,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
