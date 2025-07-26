import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:swipe_to/swipe_to.dart';
import 'package:myapp/features/chatting/chat_service.dart';

class OneToOneChatScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String otherUserId;

  const OneToOneChatScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.otherUserId,
  });

  @override
  State<OneToOneChatScreen> createState() => _OneToOneChatScreenState();
}

class _OneToOneChatScreenState extends State<OneToOneChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final ValueNotifier<bool> _isUploading = ValueNotifier(false);
  final ValueNotifier<double> _uploadProgress = ValueNotifier(0);

  File? _selectedFile;
  Map<String, dynamic>? _replyMessage;
  String? otherUserName;

  @override
  void initState() {
    super.initState();
    _resetUnreadCount();
    _fetchOtherUserName();
  }

  Future<void> _resetUnreadCount() async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .update({'unread.${widget.currentUserId}': 0});
  }

  Future<void> _fetchOtherUserName() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.otherUserId)
        .get();

    if (userDoc.exists) {
      setState(() {
        otherUserName = userDoc['name'] ?? "Unknown";
      });
    }
  }

  Future<void> _pickImage() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() => _selectedFile = File(result.files.single.path!));
    }
  }

  void _sendMessage() async {
    if (_selectedFile == null && _controller.text.trim().isEmpty) return;

    _isUploading.value = true;
    _uploadProgress.value = 0;

    await _chatService.sendMessage(
      chatId: widget.chatId,
      senderId: widget.currentUserId,
      text: _controller.text.isNotEmpty ? _controller.text : null,
      file: _selectedFile,
      replyTo: _replyMessage,
      onProgress: (progress) => _uploadProgress.value = progress,
      onComplete: () {
        _controller.clear();
        _selectedFile = null;
        _replyMessage = null;
        _isUploading.value = false;

        /// ✅ Scroll after sending
        Future.delayed(const Duration(milliseconds: 150), _scrollToBottom);
      },
      onError: () {
        _isUploading.value = false;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("❌ Upload failed")));
      },
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _isUploading.dispose();
    _uploadProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent,
        title: Text(
          otherUserName ?? "Chat",
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          /// 📩 Messages Section
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No messages yet"));
                }

                final messages = snapshot.data!.docs;

                /// ✅ Force scroll after messages load
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  reverse: false, // ✅ newest messages stay at bottom
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msgData = messages[index].data() as Map<String, dynamic>;
                    final bool isMe = msgData['senderId'] == widget.currentUserId;

                    return SwipeTo(
                      onRightSwipe: (_) {
                        setState(() {
                          _replyMessage = {
                            "senderId": msgData['senderId'],
                            "text": msgData['text'] ?? "",
                            "fileUrl": msgData['fileUrl']
                          };
                        });
                        HapticFeedback.lightImpact();
                      },
                      child: ChatBubble(
                        msgData: msgData,
                        isMe: isMe,
                        otherUserName: otherUserName,
                      ),
                    );
                  },
                );
              },
            ),
          ),

          /// 📌 Reply Bar & Image Preview
          if (_replyMessage != null)
            WhatsAppReplyBar(
              replyMessage: _replyMessage!,
              onCancel: () => setState(() => _replyMessage = null),
            ),
          if (_selectedFile != null)
            ImagePreview(
              selectedFile: _selectedFile,
              onCancel: () => setState(() => _selectedFile = null),
            ),

          /// 💬 Message Input Bar
          SafeArea(child: _buildMessageInputBar()),
        ],
      ),
    );
  }

  Widget _buildMessageInputBar() {
    return ValueListenableBuilder(
      valueListenable: _isUploading,
      builder: (context, bool isUploading, _) {
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file, color: Colors.lightBlueAccent),
                onPressed: isUploading ? null : _pickImage,
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
              ValueListenableBuilder(
                valueListenable: _uploadProgress,
                builder: (context, double progress, _) {
                  return IconButton(
                    icon: isUploading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              value: progress / 100,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.lightBlueAccent),
                    onPressed: isUploading ? null : _sendMessage,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ✅ Chat bubble widget
class ChatBubble extends StatelessWidget {
  final Map<String, dynamic> msgData;
  final bool isMe;
  final String? otherUserName;

  const ChatBubble({
    super.key,
    required this.msgData,
    required this.isMe,
    required this.otherUserName,
  });

  @override
  Widget build(BuildContext context) {
    final String messageText = msgData['text'] ?? '';
    final Timestamp? timestamp = msgData['timestamp'];
    final String timeString =
        timestamp != null ? DateFormat('hh:mm a').format(timestamp.toDate()) : '';

    final Map<String, dynamic>? reply = msgData['replyTo'];

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? Colors.green.shade300 : Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            /// ✅ Show username (if not me)
            if (!isMe && otherUserName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  otherUserName!,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.blueGrey),
                ),
              ),

            /// ✅ Show replied-to message
            if (reply != null)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(width: 4, height: 40, color: Colors.green),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        reply['text']?.isNotEmpty == true
                            ? reply['text']
                            : "📷 Photo",
                        style: const TextStyle(
                            fontStyle: FontStyle.italic, color: Colors.black54),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            /// ✅ Image message
            if (msgData['fileUrl'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Image.network(
                  msgData['fileUrl'],
                  width: 200,
                  errorBuilder: (_, __, ___) =>
                      const Text("❌ Image failed to load"),
                ),
              ),

            /// ✅ Message text
            if (messageText.isNotEmpty)
              Text(
                messageText,
                style: TextStyle(
                  fontSize: 16,
                  color: isMe ? Colors.white : Colors.black87,
                ),
              ),

            /// ✅ Time
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                timeString,
                style: TextStyle(
                  fontSize: 10,
                  color: isMe ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

/// ✅ WhatsApp-style reply bar
class WhatsAppReplyBar extends StatelessWidget {
  final Map<String, dynamic> replyMessage;
  final VoidCallback onCancel;

  const WhatsAppReplyBar({
    super.key,
    required this.replyMessage,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPhoto = replyMessage['fileUrl'] != null;
    final String replyText =
        replyMessage['text'] ?? (isPhoto ? "📷 Photo" : "");

    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Container(width: 4, height: 48, color: Colors.green),
          const SizedBox(width: 8),
          if (isPhoto)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                replyMessage['fileUrl'],
                height: 40,
                width: 40,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              replyText,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(icon: const Icon(Icons.close), onPressed: onCancel),
        ],
      ),
    );
  }
}

/// ✅ Image preview bar for attachments
class ImagePreview extends StatelessWidget {
  final File? selectedFile;
  final VoidCallback onCancel;

  const ImagePreview({super.key, required this.selectedFile, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(8),
      color: Colors.grey[300],
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(selectedFile!, height: 80),
          ),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close), onPressed: onCancel),
        ],
      ),
    );
  }
}
