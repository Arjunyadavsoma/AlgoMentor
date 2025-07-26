import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:myapp/features/authentication/chatbot/data/chatbot_service.dart';

class FeedbackScreen extends StatefulWidget {
  final String aiResponse;
  final String question;  // ✅ So AI has context about which DSA problem we’re discussing

  const FeedbackScreen({
    super.key,
    required this.aiResponse,
    required this.question,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final ChatbotService _chatbotService = ChatbotService();
  final TextEditingController _messageController = TextEditingController();
  bool isSending = false;

  /// ✅ Chat History (User & AI messages)
  final List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    // Add the AI’s initial feedback as the first “AI” message
    _messages.add({"role": "assistant", "content": widget.aiResponse});
  }

  /// 📡 Send follow-up question to AI
  Future<void> _sendMessage() async {
    final userMessage = _messageController.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "content": userMessage});
      isSending = true;
      _messageController.clear();
    });

    try {
      final aiReply = await _chatbotService.sendMessage("""
We are discussing this DSA question: "${widget.question}".

Here is my follow-up question about your feedback: $userMessage
""");

      setState(() {
        _messages.add({"role": "assistant", "content": aiReply});
        isSending = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({"role": "assistant", "content": "❌ Error: $e"});
        isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Feedback & Chat")),
      body: Column(
        children: [
          // 📝 Chat history
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["role"] == "user";

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isUser
                        ? Text(
                            msg["content"]!,
                            style: const TextStyle(fontSize: 16),
                          )
                        : MarkdownBody(
                            data: msg["content"]!,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(fontSize: 16, height: 1.4),
                              h1: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                              code: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                  color: Colors.deepOrange),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),

          // 🔘 Input box
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  // ✍️ Text Field
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: "Ask AI for clarification...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 📤 Send Button
                  IconButton(
                    icon: isSending
                        ? const CircularProgressIndicator()
                        : const Icon(Icons.send, color: Colors.blue),
                    onPressed: isSending ? null : _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
