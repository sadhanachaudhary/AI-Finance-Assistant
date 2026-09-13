import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/shared/widgets/app_card.dart';

void main() {
  group('AppCard and Reusable UI Component Tests', () {
    testWidgets('SectionHeader displays title, badgeText, and fires action onTap', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SectionHeader(
              title: 'Monthly Limit',
              icon: Icons.pie_chart_rounded,
              badgeText: '85% Used',
              actionLabel: 'Edit',
              onActionTap: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('Monthly Limit'), findsOneWidget);
      expect(find.text('85% Used'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.byIcon(Icons.pie_chart_rounded), findsOneWidget);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(actionTriggered, isTrue);
    });

    testWidgets('GlassCard renders child with gradient and responds to tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: GlassCard(
              onTap: () => tapped = true,
              child: const Text('Hero Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Hero Card Content'), findsOneWidget);
      await tester.tap(find.text('Hero Card Content'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });
}
