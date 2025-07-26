import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/features/authentication/presentation/providers/auth_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key}); // ✅ Keep const for better rebuild performance

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    /// ✅ Get logged-in user ID (runtime, not in a const field)
    final userId = FirebaseAuth.instance.currentUser!.uid ?? 'anonymous';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 🔵 Drawer Header
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.blue),
                ),
                const SizedBox(height: 10),
                authState.when(
                  data: (user) => Text(
                    user?.displayName ?? user?.email ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  loading: () => const Text('Loading...',
                      style: TextStyle(color: Colors.white)),
                  error: (error, _) => const Text('Error',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),

          // 🏠 Dashboard Tile
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => context.go('/dashboard'),
          ),

          // 💬 AI Chatbot Tile
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('AI Chatbot'),
            onTap: () => context.go('/chatbot'),
          ),

          // 📚 DSA Practice Tile
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('DSA Practice'),
            onTap: () => context.go('/dsa'),
          ),

          // 👥 People Tile
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('People'),
            onTap: () => context.go(
              '/people',
              extra: {'userId': userId}, // ✅ Pass userId dynamically
            ),
          ),

          // 📢 Discussion Tile (Global Chat)
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Discussion'),
            onTap: () => context.go(
              '/discussion',
              extra: {
                'chatId': 'global_discussion', // ✅ Use a fixed ID for global chat
                'userId': userId,
              },
            ),
          ),

          // 📊 Progress Tracker Tile (future feature)
          ListTile(
            leading: const Icon(Icons.track_changes),
            title: const Text('Progress Tracker'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("🚧 Progress Tracker Coming Soon")),
              );
            },
          ),

          const Divider(),

          // 🚪 Logout Tile
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }
}
