import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/ui/login_screen.dart';
import '../features/auth/ui/register_screen.dart';
import '../features/dashboard/ui/dashboard_screen.dart';
import '../features/dashboard/ui/main_shell_screen.dart';
import '../features/expenses/ui/expenses_screen.dart';
import '../features/goals/ui/goals_screen.dart';
import '../features/analytics/ui/analytics_screen.dart';
import '../features/ai_assistant/ui/ai_chat_screen.dart';
import '../features/profile/ui/profile_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
    // Auth Routes
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),

    // Stateful Nested Shell Route for Bottom Navigation Bar
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShellScreen(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0: Home / Dashboard
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        // Tab 1: Expenses
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/expenses',
              builder: (context, state) => const ExpensesScreen(),
            ),
          ],
        ),
        // Tab 2: Goals
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/goals',
              builder: (context, state) => const GoalsScreen(),
            ),
          ],
        ),
        // Tab 3: Analytics
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/analytics',
              builder: (context, state) => const AnalyticsScreen(),
            ),
          ],
        ),
        // Tab 4: AI Assistant Chat
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/ai',
              builder: (context, state) => const AiChatScreen(),
            ),
          ],
        ),
        // Tab 5: Profile
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
