import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/user.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

class AuthState {
  final User? user;
  final bool isAuthenticated;
  final String? error;

  AuthState({this.user, this.isAuthenticated = false, this.error});

  AuthState copyWith({User? user, bool? isAuthenticated, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(AuthState());

  Future<void> login(
    String username,
    String password,
    String licenseKey,
  ) async {
    try {
      final user = await _repository.authenticate(
        username,
        password,
        licenseKey,
      );
      state = AuthState(user: user, isAuthenticated: true);
    } catch (e) {
      state = AuthState(error: e.toString());
      rethrow;
    }
  }

  Future<void> loginWithoutLicense(String username, String password) async {
    try {
      final user = await _repository.authenticateWithoutLicense(
        username,
        password,
      );
      state = AuthState(user: user, isAuthenticated: true);
    } catch (e) {
      state = AuthState(error: e.toString());
      rethrow;
    }
  }

  void logout() {
    state = AuthState();
  }
}
