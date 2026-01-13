import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/zitadel_auth_service.dart';

// Auth state enum
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
}

// Auth state class
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;

  AuthState({
    required this.status,
    this.user,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }
}

// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final ZitadelAuthService _authService;

  AuthNotifier(this._authService)
      : super(AuthState(status: AuthStatus.initial)) {
    _checkAuthStatus();
  }

  // Check initial auth status
  Future<void> _checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final isAuth = await _authService.isAuthenticated();
      if (isAuth) {
        final user = await _authService.getCurrentUser();
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
        );
      } else {
        state = AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  // Login
  Future<void> login() async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final user = await _authService.login();
      if (user != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
        );
      } else {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          error: 'Login failed',
        );
      }
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  // Register
  Future<void> register() async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final user = await _authService.register();
      if (user != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
        );
      } else {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          error: 'Registration failed',
        );
      }
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  // Logout
  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      await _authService.logout();
      state = AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  // Refresh user info
  Future<void> refreshUser() async {
    try {
      final user = await _authService.getUserInfo();
      if (user != null) {
        state = state.copyWith(user: user);
      }
    } catch (e) {
      print('Refresh user error: $e');
    }
  }
}

// Provider instances
final authServiceProvider = Provider<ZitadelAuthService>((ref) {
  return ZitadelAuthService();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

// Convenience providers
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).status == AuthStatus.authenticated;
});

final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).status == AuthStatus.loading;
});
