import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/features/chatting/chat_service.dart';
import 'package:myapp/features/chatting/one_to_one_chat_screen.dart';

class StartNewChatScreen extends StatefulWidget {
  final String currentUserId;

  const StartNewChatScreen({super.key, required this.currentUserId});

  @override
  State<StartNewChatScreen> createState() => _StartNewChatScreenState();
}

class _StartNewChatScreenState extends State<StartNewChatScreen> {
  final ChatService _chatService = ChatService();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Start New Chat"),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildUsersList()),
        ],
      ),
    );
  }

  /// ✅ Search Bar for filtering users
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search users...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (val) {
          setState(() => _searchQuery = val.toLowerCase());
        },
      ),
    );
  }

  /// ✅ Fetch all users except current one
  Widget _buildUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No users found"));
        }

        /// ✅ Filter users by search query & exclude current user
        final users = snapshot.data!.docs.where((doc) {
          final name = (doc['name'] ?? '').toString().toLowerCase();
          return doc.id != widget.currentUserId && name.contains(_searchQuery);
        }).toList();

        if (users.isEmpty) {
          return const Center(child: Text("No matching users"));
        }

        return ListView.separated(
          itemCount: users.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final user = users[index];
            return _buildUserTile(user);
          },
        );
      },
    );
  }

  /// ✅ User tile for starting a chat
  Widget _buildUserTile(QueryDocumentSnapshot user) {
    final userName = user['name'] ?? "Unknown";
    final userEmail = user['email'] ?? "";
    final userProfilePic = user['profilePic'] ?? '';

    return ListTile(
      leading: CircleAvatar(
        radius: 25,
        backgroundImage: userProfilePic.isNotEmpty ? NetworkImage(userProfilePic) : null,
        child: userProfilePic.isEmpty ? const Icon(Icons.person, size: 28) : null,
      ),
      title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(userEmail, style: TextStyle(color: Colors.grey[700])),
      trailing: const Icon(Icons.chat, color: Colors.teal),
      onTap: () async {
        /// ✅ Create or fetch chat
        final chatId = await _chatService.createOrGetChat(
          widget.currentUserId,
          user.id,
        );

        /// ✅ Navigate to OneToOneChatScreen
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OneToOneChatScreen(
                chatId: chatId,
                currentUserId: widget.currentUserId,
                otherUserId: user.id,
              ),
            ),
          );
        }
      },
    );
  }
}
