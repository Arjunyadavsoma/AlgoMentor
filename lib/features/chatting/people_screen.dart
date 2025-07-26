import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/features/chatting/chat_service.dart';
import 'package:myapp/features/chatting/one_to_one_chat_screen.dart';
import 'package:myapp/features/chatting/new_chat_screen.dart';
import 'package:myapp/shared/widgets/app_drawer.dart';

class PeopleScreen extends StatefulWidget {
  final String currentUserId;

  const PeopleScreen({super.key, required this.currentUserId});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final ChatService _chatService = ChatService();

  /// 🔄 Dummy refresh function
  Future<void> _refreshChats() async {
    /// Since we’re using StreamBuilder, Firestore already live updates
    /// But we can add a short delay to show the refresh indicator
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {}); // Forces rebuild (not always necessary but safe)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats"),
        centerTitle: true,
        backgroundColor: Colors.lightBlueAccent,
      ),
      drawer: AppDrawer(),

      /// ✅ FAB to start a NEW CHAT
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.lightBlueAccent,
        child: const Icon(Icons.add, size: 28),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NewChatScreen(currentUserId: widget.currentUserId),
            ),
          );
        },
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshChats, // ✅ Swipe-down refresh
          child: StreamBuilder<QuerySnapshot>(
            /// ✅ Live chat list sorted by last message time
            stream: FirebaseFirestore.instance
                .collection('chats')
                .where('participants', arrayContains: widget.currentUserId)
                .orderBy('lastMessageTime', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No chats yet. Start a new one!"));
              }

              final chats = snapshot.data!.docs;

              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(), // ✅ Needed for pull-to-refresh
                itemCount: chats.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final chat = chats[index];
                  return _buildChatTile(chat);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  /// ✅ Build each chat tile (like WhatsApp)
  Widget _buildChatTile(DocumentSnapshot chatDoc) {
    final chatData = chatDoc.data() as Map<String, dynamic>;
    final List participants = chatData['participants'] ?? [];

    // ✅ Get the other user's ID
    final otherUserId =
        participants.firstWhere((id) => id != widget.currentUserId);

    return FutureBuilder<DocumentSnapshot>(
      /// ✅ Fetch other user's info
      future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return const ListTile(title: Text("Loading..."));
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
        final userName = userData['name'] ?? "Unknown User";
        final userPic = userData['profilePic'] ?? '';

        // ✅ Get unread count for current user
        final unreadMap = chatData['unread'] ?? {};
        final unreadCount = (unreadMap[widget.currentUserId] ?? 0) as int;

        return ListTile(
          leading: CircleAvatar(
            radius: 25,
            backgroundImage: userPic.isNotEmpty ? NetworkImage(userPic) : null,
            child: userPic.isEmpty ? const Icon(Icons.person, size: 28) : null,
          ),
          title: Text(
            userName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),

          /// ✅ Last message snippet
          subtitle: Text(
            chatData['lastMessage'] ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[700]),
          ),

          /// ✅ WhatsApp-style unread badge
          trailing: unreadCount > 0
              ? CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.red,
                  child: Text(
                    unreadCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                )
              : null,

          /// ✅ On tap → open chat + reset unread
          onTap: () {
            // Reset unread count for the current user
            FirebaseFirestore.instance
                .collection('chats')
                .doc(chatDoc.id)
                .update({
              'unread.${widget.currentUserId}': 0,
            });

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OneToOneChatScreen(
                  chatId: chatDoc.id,
                  currentUserId: widget.currentUserId,
                  otherUserId: otherUserId,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
