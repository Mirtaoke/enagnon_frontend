import '../models/user_model.dart';
import '../providers/api_provider.dart';
import '../providers/storage_provider.dart';

class AuthRepository {
  final ApiProvider apiProvider;
  final StorageProvider storageProvider;

  AuthRepository({required this.apiProvider, required this.storageProvider});

  Future<Map<String, dynamic>> login(String login, String password) async {
    final response = await apiProvider.post('/auth/login', {
      'login': login,
      'password': password,
    });

    if (response['token'] != null) {
      await storageProvider.saveToken(response['token']);
    }
    if (response['user'] is Map) {
      await storageProvider.saveUser(
        Map<String, dynamic>.from(response['user']),
      );
    }

    return response;
  }

  Future<User?> me() async {
    try {
      final token = await storageProvider.getToken();
      if (token == null) return null;

      final response = await apiProvider.get('/auth/me', token: token);
      final user = User.fromJson(Map<String, dynamic>.from(response['user']));
      await storageProvider.saveUser(user.toJson());
      return user;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await storageProvider.removeToken();
        return null;
      }
      return cachedUser();
    } catch (_) {
      return cachedUser();
    }
  }

  Future<void> logout() async {
    final token = await storageProvider.getToken();
    try {
      if (token != null) {
        await apiProvider.post('/auth/logout', const {}, token: token);
      }
    } finally {
      await storageProvider.removeToken();
    }
  }

  Future<User> updateProfile(String name, String username, String email) async {
    final token = await storageProvider.getToken();
    final response = await apiProvider.put('/auth/profile', {
      'name': name,
      'username': username,
      'email': email,
    }, token: token);
    final user = User.fromJson(response['user']);
    await storageProvider.saveUser(user.toJson());
    return user;
  }

  Future<void> updatePassword(String currentPassword, String password) async {
    final token = await storageProvider.getToken();
    await apiProvider.put('/auth/password', {
      'current_password': currentPassword,
      'password': password,
      'password_confirmation': password,
    }, token: token);
  }

  Future<bool> isAuthenticated() async {
    return await storageProvider.hasToken();
  }

  Future<User?> cachedUser() async {
    final data = await storageProvider.getUser();
    return data == null ? null : User.fromJson(data);
  }

  Future<String> forgotPassword(String email) async {
    final response = await apiProvider.post('/auth/forgot-password', {
      'email': email,
    });
    return '${response['message']}';
  }

  Future<String> resetPassword(
    String email,
    String code,
    String password,
  ) async {
    final response = await apiProvider.post('/auth/reset-password', {
      'email': email,
      'code': code,
      'password': password,
      'password_confirmation': password,
    });
    return '${response['message']}';
  }
}
