import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  /// ✅ Send text, image/file, or reply
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    String? text,
    File? file,
    Map<String, dynamic>? replyTo,
    required Function(double) onProgress,
    required Function onComplete,
    required Function onError,
  }) async {
    try {
      // 🔹 1️⃣ Add placeholder message to Firestore
      final msgRef = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': senderId,
        'text': text,
        'fileUrl': null,      // Will update after upload
        'localPath': file?.path, // ✅ NEW: Store local path for sender
        'replyTo': replyTo,
        'status': 'sent',
        'seenBy': [],
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 🔹 2️⃣ Update chat metadata immediately
      await _updateChatMeta(chatId, senderId, text, file);

      // 🔹 3️⃣ If there’s a file → upload in background
      if (file != null) {
        _uploadFileInBackground(file, msgRef, onProgress);
      }

      onComplete();
    } catch (e) {
      print('❌ Error sending message: $e');
      onError();
    }
  }

  /// ✅ Background file upload (non-blocking)
  Future<void> _uploadFileInBackground(
    File file,
    DocumentReference msgRef,
    Function(double) onProgress,
  ) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final bytes = await file.readAsBytes();

      // 🔄 Simulate chunk progress (for UI updates)
      const chunkSize = 256 * 1024;
      int uploadedBytes = 0;
      for (int i = 0; i < bytes.length; i += chunkSize) {
        final end = (i + chunkSize > bytes.length) ? bytes.length : i + chunkSize;
        Uint8List chunk = bytes.sublist(i, end);

        await Future.delayed(const Duration(milliseconds: 50)); // fake delay
        uploadedBytes += chunk.length;
        onProgress((uploadedBytes / bytes.length) * 100);
      }

      // ✅ Upload file to Supabase
      await _supabase.storage.from('chat-files').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final uploadedFileUrl =
          _supabase.storage.from('chat-files').getPublicUrl(fileName);

      // ✅ Update Firestore message with real URL
      await msgRef.update({'fileUrl': uploadedFileUrl});
    } catch (e) {
      print('❌ File upload failed: $e');
    }
  }

  /// ✅ Update chat metadata (last message, unread counts)
  Future<void> _updateChatMeta(
      String chatId, String senderId, String? text, File? file) async {
    final chatDoc = _firestore.collection('chats').doc(chatId);
    final snapshot = await chatDoc.get();

    if (!snapshot.exists) return;

    final data = snapshot.data() as Map<String, dynamic>;
    List participants = List<String>.from(data['participants']);
    Map<String, dynamic> unreadMap = Map<String, dynamic>.from(data['unread'] ?? {});

    // ✅ Increment unread for everyone except sender
    for (String participant in participants) {
      if (participant != senderId) {
        unreadMap[participant] = (unreadMap[participant] ?? 0) + 1;
      }
    }

    await chatDoc.update({
      'lastMessage': text ?? (file != null ? '📷 Image' : ''),
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unread': unreadMap,
    });
  }

  /// ✅ Stream messages
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /// ✅ Mark as delivered
  Future<void> markMessagesAsDelivered(String chatId, String userId) async {
    final unreadMessages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('status', isEqualTo: 'sent')
        .get();

    for (var msg in unreadMessages.docs) {
      if (msg['senderId'] != userId) {
        msg.reference.update({'status': 'delivered'});
      }
    }
  }

  /// ✅ Mark as seen & reset unread
  Future<void> markMessagesAsSeen(String chatId, String userId) async {
    final deliveredMessages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('status', isEqualTo: 'delivered')
        .get();

    for (var msg in deliveredMessages.docs) {
      if (msg['senderId'] != userId) {
        msg.reference.update({
          'status': 'seen',
          'seenBy': FieldValue.arrayUnion([userId]),
        });
      }
    }

    await _firestore.collection('chats').doc(chatId).update({
      'unread.$userId': 0,
    });
  }

  /// ✅ Create or get chat
  Future<String> createOrGetChat(String currentUserId, String otherUserId) async {
    try {
      final query = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId)
          .get();

      for (var doc in query.docs) {
        final participants = List<String>.from(doc['participants']);
        if (participants.contains(otherUserId)) {
          return doc.id;
        }
      }

      final newChatRef = await _firestore.collection('chats').add({
        'participants': [currentUserId, otherUserId],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unread': {
          currentUserId: 0,
          otherUserId: 0,
        },
      });

      return newChatRef.id;
    } catch (e) {
      print('❌ Error creating/getting chat: $e');
      rethrow;
    }
  }

  /// ✅ Get all user chats
  Stream<QuerySnapshot> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }
}
