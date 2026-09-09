import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import '../../../networking/api_client.dart';
import '../../../storage/secure_storage.dart';
import '../models/user.dart';

// Provides the ApiClient
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

// Provides the SecureStorage
final secureStorageProvider = Provider<SecureStorage>((ref) => SecureStorage());

// Provides the AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});

// Provides the Auth State (the currently logged in User)
final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(() => AuthNotifier());

class AuthNotifier extends AsyncNotifier<User?> {
  late AuthRepository _repository;
  late SecureStorage _secureStorage;

  @override
  Future<User?> build() async {
    _repository = ref.watch(authRepositoryProvider);
    _secureStorage = ref.watch(secureStorageProvider);
    
    // Check if we have a token on startup to determine if we are logged in.
    // In a full app, we would validate the token against a /me endpoint here.
    final token = await _secureStorage.getToken();
    if (token != null) {
      // Return a dummy user for now just to signal we are authenticated
      return const User(id: 'cached', email: 'cached@example.com'); 
    }
    return null;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.login(email, password);
      final user = result['user'] as User;
      final token = result['token'] as String;
      
      await _secureStorage.saveToken(token);
      state = AsyncValue.data(user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> register(String email, String password, String name) async {
    state = const AsyncValue.loading();
    try {
      await _repository.register(email, password, name);
      // Registration successful. Since backend doesn't return a token on register,
      // we automatically attempt login.
      await login(email, password);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> logout() async {
    await _secureStorage.deleteToken();
    state = const AsyncValue.data(null);
  }
}
