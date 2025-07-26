import 'package:go_router/go_router.dart';
import 'package:myapp/features/authentication/chatbot/presentation/chatbot_screen.dart';
import 'package:myapp/features/authentication/chatbot/presentation/widgets/splash_screen.dart';
import 'package:myapp/features/authentication/presentation/pages/dashboard_page.dart';
import 'package:myapp/features/authentication/presentation/pages/login_page.dart';
import 'package:myapp/features/authentication/presentation/pages/signup_page.dart';
import 'package:myapp/features/chatting/discussion_screen.dart';
import 'package:myapp/features/chatting/people_screen.dart';
import 'package:myapp/features/chatting/new_chat_screen.dart';
import 'package:myapp/features/chatting/one_to_one_chat_screen.dart'; // ✅ NEW IMPORT
import 'package:myapp/features/dsa/screens/dsa_screen.dart';
import 'package:myapp/features/dsa/screens/explain_screen.dart';
import 'package:myapp/features/dsa/screens/solve_screen.dart';
import 'package:myapp/features/dsa/screens/dsa_progress_screen.dart';

final router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpPage()),
    GoRoute(path: '/dashboard', builder: (context, state) => const DashboardPage()),
    GoRoute(path: '/chatbot', builder: (context, state) => const ChatbotScreen()),
    GoRoute(path: '/dsa', builder: (context, state) => const DSAScreen()),

    // ✅ SOLVE ROUTE – expects all details
    GoRoute(
      path: '/solve',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return SolveScreen(
          questionId: data['questionId'],
          question: data['question'],
          difficulty: data['difficulty'],
          topic: data['topic'],
          userId: data['userId'],
        );
      },
    ),

    // ✅ EXPLAIN ROUTE – needs the question text
 GoRoute(
  path: '/explain',
  builder: (context, state) {
    final data = state.extra as Map<String, dynamic>;
    return ExplainScreen(questionData: data);
  },
),


    // ✅ TRACKER ROUTE
    GoRoute(
      path: '/tracker',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return DSAProgressScreen(
          userId: data['userId'],
          questions: data['questions'],
        );
      },
    ),

    // ✅ DISCUSSION ROUTE – Pass chatId & userId dynamically
    GoRoute(
      path: '/discussion',
      builder: (context, state) {
        final data = (state.extra is Map<String, dynamic>) ? state.extra as Map<String, dynamic> : {};
        return DiscussionScreen(
          chatId: data['chatId'] ?? '',
          userId: data['userId'] ?? '',
        );
      },
    ),

    // ✅ PEOPLE SCREEN – chat list page
    GoRoute(
      path: '/people',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return PeopleScreen(currentUserId: data['userId']);
      },
    ),

    // ✅ NEW CHAT SCREEN – search all users
    GoRoute(
      path: '/new-chat',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return NewChatScreen(currentUserId: data['userId']);
      },
    ),

    // ✅ NEW: ONE-TO-ONE CHAT ROUTE
    GoRoute(
      path: '/one-to-one-chat',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return OneToOneChatScreen(
          chatId: data['chatId'],
          currentUserId: data['currentUserId'],
          otherUserId: data['otherUserId'],
        );
      },
    ),
  ],
);
