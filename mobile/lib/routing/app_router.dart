import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../features/auth/ui/login_screen.dart';
import '../features/auth/ui/register_screen.dart';

// Placeholder screen for dashboard
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text(title)));
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const PlaceholderScreen(title: 'Dashboard Screen'),
    ),
  ],
  redirect: (context, state) {
    // We will implement auth check redirect later using Riverpod state
    return null;
  },
);
