import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fed_tms/features/auth/data/models/user.dart';
import 'package:fed_tms/features/auth/data/models/user.dart';
import 'package:fed_tms/features/auth/data/services/auth_service.dart';


final userProvider = StateProvider<User?>((ref) => null);
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;

  AuthNotifier(this.ref) : super(const AuthState());

  Future<void> login(String email, String password) async {
    state = const AuthState(isLoading: true);

    try {
      final authService = AuthService();
      final user = await authService.login(email, password);

      ref.read(userProvider.notifier).state = user;
      state = AuthState(isAuthenticated: true, user: user);
    } catch (e) {
      state = AuthState(
        isAuthenticated: false,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    ref.read(userProvider.notifier).state = null;
    state = const AuthState();

    final authService = AuthService();
    await authService.logout();
  }
}

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final User? user;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.error,
  });
}
