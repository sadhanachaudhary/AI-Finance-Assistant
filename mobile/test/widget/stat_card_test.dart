import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/shared/widgets/stat_card.dart';

void main() {
  group('StatCard Widget Tests', () {
    testWidgets('renders title, currency, amount, and positive trend chip', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: StatCard(
              title: 'Top Spending',
              amount: 5400.0,
              currency: 'INR',
              trendPercent: 15.2,
              subtitle: 'Shopping',
              icon: Icons.shopping_bag_outlined,
            ),
          ),
        ),
      );

      expect(find.text('Top Spending'), findsOneWidget);
      expect(find.text('₹5,400.00'), findsOneWidget);
      expect(find.text('Shopping'), findsOneWidget);
      expect(find.text('+15.2%'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
      expect(find.byIcon(Icons.trending_up_rounded), findsOneWidget);
    });

    testWidgets('triggers onTap callback when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: StatCard(
              title: 'Interactive Card',
              amount: 100.0,
              icon: Icons.touch_app_rounded,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(StatCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
