import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/ui/login_screen.dart';

void main() {
  testWidgets('AI Finance App smoke test - renders Login screen with inputs and submit', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const ProviderScope(
          child: LoginScreen(),
        ),
      ),
    );

    // Settle entry animations safely
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Login to manage your finances intelligently'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
