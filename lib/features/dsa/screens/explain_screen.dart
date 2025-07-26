import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:myapp/features/authentication/chatbot/data/chatbot_service.dart';
import 'package:myapp/shared/widgets/app_drawer.dart';

class ExplainScreen extends StatefulWidget {
  final Map<String, dynamic> questionData;

  const ExplainScreen({super.key, required this.questionData});

  @override
  State<ExplainScreen> createState() => _ExplainScreenState();
}

class _ExplainScreenState extends State<ExplainScreen> {
  final ChatbotService _chatbotService = ChatbotService();
  String? explanation;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getExplanation();
  }

  Future<void> _getExplanation() async {
    try {
      final String aiResponse = await _chatbotService.sendMessage(
          "Explain this DSA question step by step with reasoning, examples, and concepts: ${widget.questionData['question']} (Topic: ${widget.questionData['topic']}).");

      setState(() {
        explanation = aiResponse;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        explanation = "❌ Error getting explanation: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Explanation")),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 📦 Show Question Title
                  Text(
                    widget.questionData['question'],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // ✅ Optional hint
                  if (widget.questionData['hint'] != null)
                    Text("💡 Hint: ${widget.questionData['hint']}",
                        style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 12),

                  // 📖 Markdown Explanation Box
                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: MarkdownBody(
                          data: explanation ?? "No explanation found.",
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(fontSize: 16, height: 1.5),
                            h1: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                            h2: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                            code: TextStyle(
                                backgroundColor: Colors.grey[200],
                                fontFamily: 'monospace',
                                fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 🔙 Back Button
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_back),
                      label: const Text("Back to DSA"),
                      style: ElevatedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
