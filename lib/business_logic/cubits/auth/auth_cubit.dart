import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/auth/auth_event.dart';
import '../../../data/repositories/auth_repository.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;

  AuthCubit({required this.authRepository}) : super(const AuthInitial());

  Future<void> login(String email, String password) async {
    emit(const AuthLoading());
    try {
      final response = await authRepository.login(email, password);
      final user = await authRepository.me();
      if (user == null) {
        throw Exception('Profil utilisateur introuvable');
      }
      emit(AuthSuccess(user: user, token: response['token'].toString()));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> checkAuth() async {
    try {
      final isAuth = await authRepository.isAuthenticated();
      if (isAuth) {
        final user = await authRepository.me();
        if (user != null) {
          final token = await authRepository.storageProvider.getToken();
          emit(AuthSuccess(user: user, token: token ?? ''));
        } else {
          emit(const AuthUnauthenticated());
        }
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> logout() async {
    await authRepository.logout();
    emit(const AuthUnauthenticated());
  }

  Future<void> updateProfile(String name, String username, String email) async {
    final current = state;
    if (current is! AuthSuccess) return;
    emit(const AuthLoading());
    try {
      final user = await authRepository.updateProfile(name, username, email);
      emit(AuthSuccess(user: user, token: current.token));
    } catch (error) {
      emit(AuthError(message: error.toString()));
    }
  }

  Future<String?> updatePassword(
    String currentPassword,
    String password,
  ) async {
    try {
      await authRepository.updatePassword(currentPassword, password);
      return null;
    } catch (error) {
      return error.toString().replaceFirst('Exception: ', '');
    }
  }
}
