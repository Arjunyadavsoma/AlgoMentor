import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/features/dsa/screens/dsa_question_tile.dart';
import '../providers/dsa_providers.dart';

class DSAListScreen extends ConsumerWidget {
  const DSAListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(dsaQuestionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("DSA Question Bank")),
      body: questionsAsync.when(
        data: (questions) {
          return ListView.builder(
            itemCount: questions.length,
            itemBuilder: (context, index) {
              return DSAQuestionTile(question: questions[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }
}
