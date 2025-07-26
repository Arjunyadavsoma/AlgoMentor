import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/features/authentication/chatbot/presentation/ChatHistoryScreen.dart';
import 'package:myapp/shared/widgets/app_drawer.dart';
import '../data/chatbot_service.dart';
import '../domain/message_model.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/message_input.dart';
import 'widgets/typing_indicator.dart';

class ChatbotScreen extends StatefulWidget {
  final String? sessionId;

  const ChatbotScreen({super.key, this.sessionId});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final ChatbotService _chatService = ChatbotService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<MessageModel> _messages = [];
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  String? _currentSessionId;
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? "test_user";

  /// ✅ NEW: AI streaming buffer
  final ValueNotifier<String> aiBuffer = ValueNotifier("");

  @override
  void initState() {
    super.initState();
    if (widget.sessionId != null) {
      _loadSession(widget.sessionId!);
    }
  }

  Future<void> _loadSession(String sessionId) async {
    _currentSessionId = sessionId;

    final messagesSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('sessions')
        .doc(sessionId)
        .collection('messages')
        .orderBy('timestamp')
        .get();

    setState(() {
      _messages.clear();
      _messages.addAll(messagesSnapshot.docs.map((doc) {
        return MessageModel(
          text: doc['text'],
          isUser: doc['isUser'],
          timestamp: (doc['timestamp'] as Timestamp).toDate(),
        );
      }));
    });
  }

  Future<void> _sendMessage(String text) async {
    // ✅ Add user's message immediately
    setState(() {
      _messages.add(MessageModel(text: text, isUser: true, timestamp: DateTime.now()));
      // ✅ Placeholder for AI message
      _messages.add(MessageModel(text: "", isUser: false, timestamp: DateTime.now()));
      _isLoading = true;
    });
    _scrollToBottom();

    if (_currentSessionId == null) {
      final sessionRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .add({
        'title': text,
        'timestamp': DateTime.now(),
      });
      _currentSessionId = sessionRef.id;
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('sessions')
        .doc(_currentSessionId)
        .collection('messages')
        .add({
      'text': text,
      'isUser': true,
      'timestamp': DateTime.now(),
    });

    try {
      final chatHistory = [
        {"role": "system", "content": "You are a helpful AI assistant."},
        for (var m in _messages.where((m) => m.text.isNotEmpty))
          {"role": m.isUser ? "user" : "assistant", "content": m.text},
        {"role": "user", "content": text}
      ];

      aiBuffer.value = ""; // reset buffer

      // ✅ Stream AI response in real time
      await _chatService.sendMessageStream(chatHistory, (chunk) {
        aiBuffer.value += chunk;
      });

      // ✅ When stream ends, finalize AI message
      final updatedMessage = MessageModel(
        text: aiBuffer.value,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages[_messages.length - 1] = updatedMessage;
      });

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .doc(_currentSessionId)
          .collection('messages')
          .add({
        'text': aiBuffer.value,
        'isUser': false,
        'timestamp': DateTime.now(),
      });
    } catch (e) {
      setState(() {
        _messages.add(MessageModel(text: "⚠️ Error: $e", isUser: false, timestamp: DateTime.now()));
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startNewChat() {
    setState(() {
      _messages.clear();
      _currentSessionId = null;
      aiBuffer.value = "";
    });
  }

  /// ✅ Welcome widget when chat is empty
  Widget _buildWelcomeWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.smart_toy, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 16),
            const Text(
              "Hi! I'm your AI Assistant 🤖",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "I can help you with coding, answer questions,\nexplain concepts, and more!",
              style: TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text("💡 Try asking:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _exampleChip("Explain recursion"),
            _exampleChip("What's Flutter used for?"),
            _exampleChip("Help me write a resume"),
          ],
        ),
      ),
    );
  }

  Widget _exampleChip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onTap: () => _sendMessage(text),
        child: Chip(
          label: Text(text),
          backgroundColor: Colors.blue[50],
          labelStyle: const TextStyle(color: Colors.blue),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("AI Chatbot 🤖", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: "Chat History",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_comment),
            tooltip: "Start New Chat",
            onPressed: _startNewChat,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcomeWidget()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];

                      // ✅ Use ValueListenableBuilder ONLY for the streaming AI bubble
                      if (!msg.isUser && index == _messages.length - 1) {
                        return ValueListenableBuilder<String>(
                          valueListenable: aiBuffer,
                          builder: (_, value, __) {
                            return ChatBubble(
                              message: MessageModel(
                                text: value.isNotEmpty ? value : msg.text,
                                isUser: false,
                                timestamp: msg.timestamp,
                              ),
                            );
                          },
                        );
                      }

                      return ChatBubble(message: msg);
                    },
                  ),
          ),
          if (_isLoading) const TypingIndicator(),
          MessageInput(onSend: _sendMessage),
        ],
      ),
    );
  }
}
