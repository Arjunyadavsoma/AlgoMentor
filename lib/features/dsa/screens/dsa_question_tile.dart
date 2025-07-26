import 'package:flutter/material.dart';
import '../models/dsa_question_model.dart';

class DSAQuestionTile extends StatelessWidget {
  final DSAQuestion question;

  const DSAQuestionTile({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListTile(
        title: Text(question.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${question.category} • ${question.difficulty}"),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.pushNamed(context, '/dsa_question', arguments: question);
        },
      ),
    );
  }
}
