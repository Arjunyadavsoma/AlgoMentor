import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dsa_question_model.dart';
import '../repository/dsa_repository.dart';

final dsaRepositoryProvider = Provider((ref) => DSARepository());

final dsaQuestionsProvider = FutureProvider<List<DSAQuestion>>((ref) async {
  return ref.read(dsaRepositoryProvider).fetchQuestions();
});
