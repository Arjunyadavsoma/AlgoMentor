import 'dart:io';
import 'package:flutter/material.dart';
import 'package:myapp/features/chatting/cached_file_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatBubble extends StatefulWidget {
final String senderId;
final String currentUserId;
final String? text;
final String? fileUrl;
final File? localFile;
// ✅ Only for sender’s own preview
  final QueryDocumentSnapshot? message; // 🔥 New: Full Firestore doc

  const ChatBubble({
    super.key,
    required this.senderId,
    required this.currentUserId,
    this.text,
    this.fileUrl,
    this.localFile,
    this.message, // ✅ Now accepted
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  File? _cachedFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFileIfNeeded();
  }

  Future<void> _loadFileIfNeeded() async {
    // 🟢 Don’t download my own uploads; they already show from localFile
    if (widget.senderId == widget.currentUserId || widget.fileUrl == null) return;

    setState(() => _isLoading = true);
    try {
      final file = await CachedFileManager.instance.fetchFile(widget.fileUrl!);
      setState(() {
        _cachedFile = file;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ File download error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMe = widget.senderId == widget.currentUserId;

    final replyTo = widget.message?['replyTo'];
    final status = widget.message?['status'] ?? 'sent'; // ✅ future: sent → uploading → delivered

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isMe ? Colors.green[200] : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
          bottomRight: isMe ? Radius.zero : const Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔁 SHOW REPLY BUBBLE IF MESSAGE IS A REPLY
          if (replyTo != null)
            Container(
              padding: const EdgeInsets.all(6),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                replyTo['text'] ?? (replyTo['fileUrl'] != null ? "📎 File" : ""),
                style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black54),
                overflow: TextOverflow.ellipsis,
              ),
            ),

          /// 📝 TEXT MESSAGE
          if (widget.text != null && widget.text!.isNotEmpty)
            Text(widget.text!, style: const TextStyle(fontSize: 16)),

          /// 📎 FILE MESSAGE
          if (widget.fileUrl != null) ...[
            const SizedBox(height: 6),
            _buildFilePreview(isMe),
          ],

          /// 🔥 STATUS ICON (optional for my own messages)
          if (isMe)
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  status == 'uploading'
                      ? Icons.cloud_upload
                      : Icons.check, // ✅ can expand to double-check for seen
                  size: 14,
                  color: status == 'uploading' ? Colors.orange : Colors.grey[700],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilePreview(bool isMe) {
    // ✅ 1️⃣ Show my own local preview instead of downloading again
    if (isMe && widget.localFile != null) {
      return _localPreview(widget.localFile!);
    }

    // ✅ 2️⃣ Show loader if downloading
    if (_isLoading) {
      return const SizedBox(
        height: 120,
        width: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // ✅ 3️⃣ Show cached file if ready
    if (_cachedFile != null) {
      return _localPreview(_cachedFile!);
    }

    // ✅ 4️⃣ Fallback placeholder if not downloaded yet
    return Container(
      height: 120,
      width: 180,
      color: Colors.grey[300],
      child: const Center(child: Icon(Icons.insert_drive_file, size: 40)),
    );
  }

  Widget _localPreview(File file) {
  final status = widget.message?['status'] ?? 'sent';

  return Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          file,
          height: 120,
          width: 180,
          fit: BoxFit.cover,
        ),
      ),
      if (status == 'uploading')   // ✅ show loader on top of image
        Positioned.fill(
          child: Container(
            color: Colors.black38,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        ),
    ],
  );
}

}
