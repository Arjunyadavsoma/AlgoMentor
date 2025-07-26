import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatbotService {
  final String apiKey = "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"; 

  /// Regular message send (for testing or fallback)
  Future<String> sendMessage(String userMessage) async {
    final url = Uri.parse("https://api.groq.com/openai/v1/chat/completions");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: jsonEncode({
        "model": "llama3-70b-8192",
        "messages": [
          {"role": "system", "content": "You are a helpful AI assistant."},
          {"role": "user", "content": userMessage}
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception("Groq API Error: ${response.body}");
    }
  }

  /// ✅ NEW: Simulated streaming - sends chunks via callback
  Future<void> sendMessageStream(
    List<Map<String, String>> chatHistory,
    Function(String chunk) onChunk,
  ) async {
    final url = Uri.parse("https://api.groq.com/openai/v1/chat/completions");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: jsonEncode({
        "model": "llama3-70b-8192",
        "messages": chatHistory,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final fullText = data['choices'][0]['message']['content'];

      // Simulate streaming by sending one word at a time
      final words = fullText.split(' ');
      for (var word in words) {
        await Future.delayed(const Duration(milliseconds: 50)); // typing speed
        onChunk('$word ');
      }
    } else {
      throw Exception("Groq API Error: ${response.body}");
    }
  }
}
