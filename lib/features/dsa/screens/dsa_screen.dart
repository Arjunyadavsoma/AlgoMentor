import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/features/dsa/service/dsa_question_service.dart';
import 'package:myapp/shared/widgets/app_drawer.dart';

class DSAScreen extends StatefulWidget {
  const DSAScreen({super.key});

  @override
  State<DSAScreen> createState() => _DSAScreenState();
}

class _DSAScreenState extends State<DSAScreen> {
  final DSAQuestionService _questionService = DSAQuestionService();
  final User? currentUser = FirebaseAuth.instance.currentUser; // ✅ Get logged-in user
  bool isLoading = true;
  List<Map<String, dynamic>> topics = [];

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final fetchedTopics = await _questionService.getQuestions();
      setState(() {
        topics = fetchedTopics;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error loading questions: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📘 DSA Practice")),
      drawer: const AppDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : topics.isEmpty
              ? const Center(child: Text("⚠️ No questions available."))
              : ListView.builder(
                  itemCount: topics.length,
                  itemBuilder: (context, index) {
                    final topic = topics[index];
                    final List<dynamic> questions = topic['questions'];

                    return ExpansionTile(
                      title: Text(
                        topic['name'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      children: questions.map((q) {
                        return _buildQuestionCard(q, topic['name'], context);
                      }).toList(),
                    );
                  },
                ),
    );
  }

  /// ✅ Builds a Question Card with Solve, Explain, and Hint Toggle
  Widget _buildQuestionCard(Map<String, dynamic> q, String topicName, BuildContext context) {
  bool showHint = false; // Local state for hint toggle

  return StatefulBuilder(
    builder: (BuildContext context, StateSetter setState) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📄 Question Text
              Text(
                q['question'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              // 🎯 Difficulty Badge
              Text(
                "Difficulty: ${q['difficulty']}",
                style: TextStyle(
                  fontSize: 14,
                  color: q['difficulty'] == "Easy"
                      ? Colors.green
                      : q['difficulty'] == "Medium"
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
              const SizedBox(height: 12),

              // ✅ Use Wrap to prevent overflow
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.code),
                      label: const Text("Solve"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () {
                        if (FirebaseAuth.instance.currentUser == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("⚠️ You must log in first.")),
                          );
                          return;
                        }

                        context.push('/solve', extra: {
                          'questionId': q['id'],
                          'question': q['question'],
                          'difficulty': q['difficulty'],
                          'topic': topicName,
                          'userId': FirebaseAuth.instance.currentUser!.uid,
                        });
                      },
                    ),
                    ElevatedButton.icon(
  icon: const Icon(Icons.lightbulb),
  label: const Text("Explain"),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
  ),
  onPressed: () {
    context.push('/explain', extra: {
      'question': q['question'],
      'hint': q['hint'],
      'topic': topicName,
      'difficulty': q['difficulty'],
      'id': q['id'],
    });
  },
),

                    TextButton(
                      onPressed: () {
                        setState(() {
                          showHint = !showHint;
                        });
                      },
                      child: Text(showHint ? "Hide Hint" : "Show Hint"),
                    ),
                  ],
                ),
              ),

              // 💡 Hint Box
              if (showHint) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.yellow[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "💡 Hint: ${q['hint']}",
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

}
