import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/message_model.dart';
import 'widgets/chat_bubble.dart';

class SessionDetailScreen extends StatelessWidget {
  final String sessionId;
  final String sessionTitle;

  const SessionDetailScreen({
    super.key,
    required this.sessionId,
    required this.sessionTitle,
  });

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final String userId = "test_user"; // ✅ later: FirebaseAuth.currentUser!.uid

    return Scaffold(
      appBar: AppBar(title: Text(sessionTitle)),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('users')
            .doc(userId)
            .collection('sessions')
            .doc(sessionId)
            .collection('messages')
            .orderBy('timestamp')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final messages = snapshot.data!.docs.map((doc) {
            return MessageModel(
              text: doc['text'],
              isUser: doc['isUser'],
              timestamp: (doc['timestamp'] as Timestamp).toDate(),
            );
          }).toList();

          if (messages.isEmpty) {
            return const Center(child: Text("No messages in this session."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              return ChatBubble(message: messages[index]);
            },
          );
        },
      ),
    );
  }
}
