import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'routing/app_router.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AI Finance',
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Default to our sleek dark theme
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
