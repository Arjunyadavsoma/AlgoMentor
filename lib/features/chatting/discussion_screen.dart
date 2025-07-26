import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:myapp/shared/widgets/app_drawer.dart';
import 'package:swipe_to/swipe_to.dart';
import 'package:myapp/features/chatting/chat_service.dart';

class DiscussionScreen extends StatefulWidget {
  final String chatId;
  final String userId;

  const DiscussionScreen({
    super.key,
    required this.chatId,
    required this.userId,
  });

  @override
  State<DiscussionScreen> createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  File? _selectedFile;
  bool _isUploading = false;
  double _uploadProgress = 0;
  Map<String, dynamic>? _replyMessage;

  /// 📌 Pick an image from device
  Future<void> _pickImage() async {
    try {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.path != null) {
        setState(() => _selectedFile = File(result.files.single.path!));
      }
    } catch (e) {
      debugPrint("⚠️ File picker error: $e");
    }
  }

  /// 📌 Send message (text or image)
  void _sendMessage() async {
    if (_selectedFile == null && _controller.text.isEmpty) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    await _chatService.sendMessage(
      chatId: widget.chatId,
      senderId: widget.userId,
      text: _controller.text.isEmpty ? null : _controller.text,
      file: _selectedFile,
      replyTo: _replyMessage,
      onProgress: (progress) => setState(() => _uploadProgress = progress),
      onComplete: () {
        setState(() {
          _selectedFile = null;
          _isUploading = false;
          _uploadProgress = 0;
          _controller.clear();
          _replyMessage = null;
        });
      },
      onError: () {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("❌ Upload failed")));
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(title: const Text('Discussion')),
      drawer: AppDrawer(),
      body: Column(
        children: [
          /// 🔥 Messages List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(widget.chatId),
              builder: (context, snapshot) {
                /// ✅ Catch runtime errors instead of red screen
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "⚠️ Error: ${snapshot.error}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                /// ✅ Auto-scroll to bottom on new messages
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == widget.userId;

                    return SwipeTo(
                      onRightSwipe: (_) {
                        setState(() {
                          _replyMessage = {
                            "senderId": msg['senderId'],
                            "text": msg['text'] ?? "",
                            "fileUrl": msg['fileUrl'],
                          };
                        });
                        HapticFeedback.lightImpact();
                      },
                      child: Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: _buildChatBubble(msg, isMe),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          /// 🔁 Reply bar
          if (_replyMessage != null) _buildReplyBar(),

          /// 🖼 Image preview
          if (_selectedFile != null) _buildImagePreview(),

          /// ⌨️ Message input
          SafeArea(child: _buildMessageInputBar()),
        ],
      ),
    );
  }

 Widget _buildChatBubble(QueryDocumentSnapshot msg, bool isMe) {
  final data = msg.data() as Map<String, dynamic>? ?? {};
  final senderId = data['senderId'] ?? '';
  final ts = data['timestamp'];
  String timeText = (ts is Timestamp)
      ? DateFormat('hh:mm a').format(ts.toDate())
      : '';

  final replyData = data['replyTo'] is Map ? data['replyTo'] as Map : null;

  return FutureBuilder<DocumentSnapshot>(
    future: FirebaseFirestore.instance.collection('users').doc(senderId).get(),
    builder: (context, snapshot) {
      String senderName = "Unknown";
      if (snapshot.hasData && snapshot.data!.exists) {
        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        senderName = userData?['name'] ?? "Unknown";
      }

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? Colors.green.shade300 : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 3,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ✅ Sender Name (only for others)
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  senderName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ),

            /// 🔁 Reply preview
            if (replyData != null)
              Container(
                padding: const EdgeInsets.all(6),
                margin: const EdgeInsets.only(bottom: 5),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  replyData['text'] ?? (replyData['fileUrl'] != null ? "📷 Photo" : ""),
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                ),
              ),

            /// 📷 Image or 📝 Text
            if (data['fileUrl'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  data['fileUrl'],
                  height: 180,
                  width: 220,
                  fit: BoxFit.cover,
                ),
              ),
            if (data['text'] != null && data['text'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  data['text'],
                  style: TextStyle(
                    fontSize: 16,
                    color: isMe ? Colors.white : Colors.black87,
                  ),
                ),
              ),

            /// ⏰ Timestamp
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                timeText,
                style: TextStyle(
                  fontSize: 10,
                  color: isMe ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}


  /// 🔁 Reply bar widget
  Widget _buildReplyBar() {
    return Container(
      color: Colors.grey[300],
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _replyMessage!['text'] ??
                  (_replyMessage!['fileUrl'] != null ? "📷 Photo" : ""),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => _replyMessage = null),
          ),
        ],
      ),
    );
  }

  /// 🖼 Image preview before sending
  Widget _buildImagePreview() {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(8),
      color: Colors.grey[300],
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(_selectedFile!, height: 80),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => _selectedFile = null),
          ),
        ],
      ),
    );
  }

  /// ⌨️ Input bar
  Widget _buildMessageInputBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.green),
            onPressed: _isUploading ? null : _pickImage,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Type a message...",
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: _isUploading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      value: _uploadProgress / 100,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.send, color: Colors.green),
            onPressed: _isUploading ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}
