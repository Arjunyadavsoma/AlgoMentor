import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/features/dsa/service/progress_service.dart';
import 'package:myapp/shared/widgets/app_drawer.dart';

class ProgressTrackerScreen extends ConsumerStatefulWidget {
  final String userId;

  const ProgressTrackerScreen({super.key, required this.userId});

  @override
  ConsumerState<ProgressTrackerScreen> createState() => _ProgressTrackerScreenState();
}

class _ProgressTrackerScreenState extends ConsumerState<ProgressTrackerScreen> {
  final ProgressService _progressService = ProgressService();
  bool isLoading = true;
  Map<String, dynamic> progressData = {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final data = await _progressService.getProgress(widget.userId);
      setState(() {
        progressData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to load progress: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📊 Progress Tracker")),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : progressData.isEmpty
                ? const Center(
                    child: Text(
                      "🚀 Start solving questions to track your progress!",
                      style: TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Your Progress",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ✅ Progress Overview
                      Card(
                        color: Colors.blue[50],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Questions Solved",
                                      style: TextStyle(fontSize: 16)),
                                  Text(
                                    "${progressData['solvedCount'] ?? 0}",
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(Icons.check_circle,
                                  color: Colors.green, size: 40),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ✅ Solved Questions List
                      const Text(
                        "✅ Solved Questions",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      Expanded(
                        child: ListView.builder(
                          itemCount: (progressData['solvedQuestions']?.length ?? 0),
                          itemBuilder: (context, index) {
                            final question =
                                progressData['solvedQuestions'][index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: const Icon(Icons.done, color: Colors.green),
                                title: Text(question),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
