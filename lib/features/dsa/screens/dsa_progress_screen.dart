import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/features/dsa/service/progress_service.dart';
import '../models/dsa_question_model.dart';

class DSAProgressScreen extends ConsumerWidget {
  final List<DSAQuestion> questions;
  final String userId;

  const DSAProgressScreen({
    super.key,
    required this.questions,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProgressService progressService = ProgressService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("📊 Your DSA Progress"),
      ),
      body: StreamBuilder<Map<String, bool>>(
        stream: progressService.streamUserProgress(userId), // ✅ Real-time
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final solvedStatus = snapshot.data!;
          final int solvedCount =
              solvedStatus.values.where((status) => status).length;
          final double progress = questions.isEmpty
              ? 0
              : solvedCount / questions.length;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Progress Summary
                Text(
                  "Progress: $solvedCount / ${questions.length}",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // ✅ Progress Bar
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: Colors.grey[300],
                  color: Colors.green,
                ),
                const SizedBox(height: 20),

                // ✅ Questions List with Solved Status
                Expanded(
                  child: ListView.builder(
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final question = questions[index];
                      final isSolved = solvedStatus[question.id] ?? false;

                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(question.title,
                              style: const TextStyle(fontSize: 16)),
                          subtitle: Text("Difficulty: ${question.difficulty}",
                              style: const TextStyle(fontSize: 14)),
                          trailing: Icon(
                            isSolved ? Icons.check_circle : Icons.pending,
                            color: isSolved ? Colors.green : Colors.orange,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
