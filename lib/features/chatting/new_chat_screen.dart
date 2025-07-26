import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/features/chatting/chat_service.dart';
import 'package:myapp/features/chatting/one_to_one_chat_screen.dart';

class NewChatScreen extends StatefulWidget {
  final String currentUserId;

  const NewChatScreen({super.key, required this.currentUserId});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final ChatService _chatService = ChatService();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Start Chat"),
        centerTitle: true,
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(), // ✅ Search Bar
            Expanded(child: _buildUsersList()), // ✅ All Users List
          ],
        ),
      ),
    );
  }

  /// ✅ Search Bar Widget
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
Widget _buildUsersList() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('users').snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Center(child: Text("⚠️ No users found in Firestore"));
      }

      // ✅ Print count for debugging
      print("🔥 Users fetched: ${snapshot.data!.docs.length}");

      // ✅ Filter users by search AND remove current user
      final users = snapshot.data!.docs.where((doc) {
        final name = (doc['name'] ?? '').toString().toLowerCase();
        final email = (doc['email'] ?? '').toString().toLowerCase();

        // ✅ Always exclude current user
        if (doc.id == widget.currentUserId) return false;

        // ✅ If search query is empty, show ALL users
        if (_searchQuery.isEmpty) return true;

        // ✅ Otherwise, filter by search text
        return name.contains(_searchQuery) || email.contains(_searchQuery);
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



  /// ✅ Individual user tile with profile pic, name, email
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
    title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    subtitle: Text(userEmail, style: TextStyle(color: Colors.grey[700])),
    trailing: const Icon(Icons.chat, color: Colors.lightBlueAccent),

    /// ✅ Tap to start chat with this user
    onTap: () async {
      // ✅ 1️⃣ Create or get existing chat
      final chatId = await _chatService.createOrGetChat(
        widget.currentUserId,
        user.id, // <-- THIS is the other user's ID
      );

      // ✅ 2️⃣ Navigate to chat screen WITH otherUserId
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OneToOneChatScreen(
              chatId: chatId,
              currentUserId: widget.currentUserId,
              otherUserId: user.id,  // ✅ PASSED CORRECTLY NOW
            ),
          ),
        );
      }
    },
  );
}

}
