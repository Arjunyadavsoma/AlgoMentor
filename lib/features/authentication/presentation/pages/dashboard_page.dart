import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:myapp/features/dsa/screens/explain_screen.dart';
import 'package:myapp/features/dsa/screens/solve_screen.dart';
import 'package:myapp/shared/widgets/app_drawer.dart';
import '../providers/auth_provider.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  Map<String, dynamic>? todayQuestion;
  String? todayTopic;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  /// ✅ Load a single deterministic random question from JSON
  Future<void> _loadQuestion() async {
    final String jsonString =
        await rootBundle.loadString('assets/data/dsa_questions.json');
    final Map<String, dynamic> data = jsonDecode(jsonString);

    // Flatten all questions from all topics
    final List<Map<String, dynamic>> allQuestions = [];
    for (var topic in data["topics"]) {
      for (var q in topic["questions"]) {
        allQuestions.add({
          ...q,
          "topic": topic["name"], // ✅ Attach topic name
        });
      }
    }

    // Get today's date for consistent question
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    int index = today.hashCode % allQuestions.length;

    setState(() {
      todayQuestion = allQuestions[index];
      todayTopic = allQuestions[index]["topic"];
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ✅ Auth Info
                authState.when(
                  data: (user) {
                    if (user == null) return const Text('No user found');

                    return Column(
                      children: [
                        Text(
                          'Hello, ${user.displayName ?? user.email}!',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Email: ${user.email}',
                          style: const TextStyle(
                              fontSize: 14, color: Colors.grey),
                        ),

                        const SizedBox(height: 16),

                        /// ✅ 🔥 STREAK COUNTER
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.id) // ✅ your UserEntity has .id
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const SizedBox();
                            }

                            final data = snapshot.data!.data() as Map<String, dynamic>?;
                            final streak = data?['streakCount'] ?? 0;

                            return Card(
                              color: Colors.orange[50],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.local_fire_department,
                                        color: Colors.orange, size: 28),
                                    const SizedBox(width: 8),
                                    Text(
                                      "🔥 $streak Day Streak",
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (error, _) => Text('Error: $error'),
                ),

                const SizedBox(height: 24),

                // ✅ Daily Question Section
                if (todayQuestion == null)
                  const CircularProgressIndicator()
                else
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            todayQuestion!['question'],
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Topic: $todayTopic • Difficulty: ${todayQuestion!['difficulty']}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "💡 Hint: ${todayQuestion!['hint']}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ✅ Solve Button → SolveScreen
                          ElevatedButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text("Solve"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlueAccent,
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            onPressed: () {
                              final user = ref.read(authStateProvider).value;
                              if (user == null) return;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SolveScreen(
                                    question: todayQuestion!['question'],
                                    questionId: todayQuestion!['id'],
                                    userId: user.id,
                                    topic: todayTopic ?? "General",
                                    difficulty: todayQuestion!['difficulty'],
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 10),

                          // ✅ Solution Button → ExplainScreen
                          OutlinedButton.icon(
                            icon: const Icon(Icons.lightbulb),
                            label: const Text("Solution / Explain"),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ExplainScreen(
                                    questionData: todayQuestion!,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // ✅ AI Chat Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.chat),
                  label: const Text("Chat with AI"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    context.push('/chatbot');
                  },
                ),

                const SizedBox(height: 16),

                // ✅ DSA Practice Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.school),
                  label: const Text("DSA Practice"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlueAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    context.push('/dsa');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
