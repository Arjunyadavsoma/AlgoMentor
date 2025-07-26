import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/dsa_question_model.dart';

class DSAQuestionScreen extends StatelessWidget {
  final DSAQuestion question;

  const DSAQuestionScreen({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(question.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📝 Question Description
            Text(
              question.description,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),

            // 💡 Hint Box
            ExpansionTile(
              title: const Text("💡 Show Hint", style: TextStyle(fontSize: 16)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(question.hint, style: const TextStyle(color: Colors.grey)),
                )
              ],
            ),
            const SizedBox(height: 12),

            // 📌 Example Section
            if (question.example.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "📌 Example:\n${question.example}",
                  style: const TextStyle(fontSize: 16),
                ),
              ),

            const Spacer(),

            // 🎯 Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // ✅ Solve Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.code),
                  label: const Text("Solve"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () {
                    context.push('/solve', extra: question);
                  },
                ),

                // ✅ Explain Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.lightbulb),
                  label: const Text("Explain"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () {
                    context.push('/explain', extra: question);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
