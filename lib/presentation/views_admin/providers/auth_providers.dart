import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/auth_exception.dart';
import '../../../domain/entities/usuario.dart';
import '../../../domain/usecases/auth/login_usecase.dart';

// ─────────────────────────────────────────────────────────────
// Estados de autenticación (máquina de estados)
// ─────────────────────────────────────────────────────────────

/// Estado base sellado del sistema de autenticación.
///
/// Los subtipos representan los posibles estados:
/// - [AuthUnauthenticated]: no hay sesión activa
/// - [AuthLoading]: proceso de inicio de sesión en curso
/// - [AuthAuthenticated]: sesión activa con [usuario]
/// - [AuthError]: error durante el inicio de sesión
sealed class AuthState {
  const AuthState();
}

/// Estado: no hay sesión activa.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Estado: proceso de autenticación en curso.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Estado: sesión activa.
class AuthAuthenticated extends AuthState {
  final Usuario usuario;

  const AuthAuthenticated(this.usuario);
}

/// Estado: error durante la autenticación.
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);
}

// ─────────────────────────────────────────────────────────────
// Notifier (StateNotifier)
// ─────────────────────────────────────────────────────────────

/// Notifier que gestiona el ciclo de vida de la autenticación.
class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase _loginUseCase;

  AuthNotifier(this._loginUseCase) : super(const AuthUnauthenticated());

  /// Intenta iniciar sesión con [username] y [password].
  ///
  /// Transiciona los estados: AuthUnauthenticated → AuthLoading → AuthAuthenticated
  /// En caso de error: → AuthLoading → AuthError
  Future<void> login(String username, String password) async {
    state = const AuthLoading();
    try {
      final usuario = await _loginUseCase.execute(username, password);
      if (usuario != null) {
        state = AuthAuthenticated(usuario);
      } else {
        state = const AuthError('Credenciales incorrectas');
      }
    } on AuthException catch (e) {
      state = AuthError(e.message);
    } catch (e) {
      state = AuthError('Error de conexión: $e');
    }
  }

  /// Cierra la sesión actual.
  void logout() {
    state = const AuthUnauthenticated();
  }
}

// ─────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────

/// Provider principal del estado de autenticación.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final loginUseCase = ref.watch(loginUseCaseProvider);
  return AuthNotifier(loginUseCase);
});

/// Provider que expone el usuario autenticado actual, o `null`.
final currentUserProvider = Provider<Usuario?>((ref) {
  final authState = ref.watch(authProvider);
  return switch (authState) {
    AuthAuthenticated(:final usuario) => usuario,
    _ => null,
  };
});

/// Provider booleano que indica si hay una sesión activa.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) is AuthAuthenticated;
});
