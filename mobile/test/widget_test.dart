import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/providers/auth_provider.dart';
import 'package:mobile/storage/secure_storage.dart';
import 'package:mobile/main.dart';

class FakeSecureStorage extends SecureStorage {
  String? _token;
  @override
  Future<void> saveToken(String token) async => _token = token;
  @override
  Future<String?> getToken() async => _token;
  @override
  Future<void> deleteToken() async => _token = null;
}

void main() {
  testWidgets('AI Finance App smoke test - renders Login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureStorageProvider.overrideWithValue(FakeSecureStorage()),
        ],
        child: const MyApp(),
      ),
    );

    // Allow initial async provider build to complete
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));

    // Verify that the login screen elements render
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('Sign Up'),
      ),
      findsOneWidget,
    );
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
