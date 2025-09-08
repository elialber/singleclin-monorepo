import 'package:get/get.dart';
import 'package:singleclin_mobile/core/services/api_service.dart';

class AuthService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();

  /// Login com email e senha
  Future<Map<String, dynamic>> loginWithEmail(String email, String password) async {
    try {
      final response = await _apiService.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
          'message': 'Login realizado com sucesso',
        };
      } else {
        return {
          'success': false,
          'message': response.data?['message'] ?? 'Erro no login',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Login com Google
  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      // Implementar login com Google usando google_sign_in
      // Por enquanto, retorna erro
      return {
        'success': false,
        'message': 'Login com Google não implementado',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Login com Apple
  Future<Map<String, dynamic>> loginWithApple() async {
    try {
      // Implementar login com Apple usando sign_in_with_apple
      // Por enquanto, retorna erro
      return {
        'success': false,
        'message': 'Login com Apple não implementado',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Registro de novo usuário
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final response = await _apiService.post('/auth/register', data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'phone': phone,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': response.data,
          'message': 'Conta criada com sucesso',
        };
      } else {
        return {
          'success': false,
          'message': response.data?['message'] ?? 'Erro no registro',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Recuperação de senha
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _apiService.post('/auth/forgot-password', data: {
        'email': email,
      });

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Email de recuperação enviado',
        };
      } else {
        return {
          'success': false,
          'message': response.data?['message'] ?? 'Erro ao enviar email',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Validar token
  Future<bool> validateToken() async {
    try {
      final response = await _apiService.get('/auth/validate');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _apiService.post('/auth/logout');
    } catch (e) {
      // Ignore errors during logout
    }
  }

  /// Atualizar usuário
  Future<Map<String, dynamic>> updateUser(dynamic user) async {
    try {
      final response = await _apiService.put('/auth/user', data: user.toJson());

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data,
          'message': 'Usuário atualizado com sucesso',
        };
      } else {
        return {
          'success': false,
          'message': response.data?['message'] ?? 'Erro na atualização',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Alterar senha
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.put('/auth/change-password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Senha alterada com sucesso',
        };
      } else {
        return {
          'success': false,
          'message': response.data?['message'] ?? 'Erro ao alterar senha',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Deletar conta
  Future<Map<String, dynamic>> deleteAccount(String password) async {
    try {
      final response = await _apiService.delete('/auth/account', data: {
        'password': password,
      });

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Conta deletada com sucesso',
        };
      } else {
        return {
          'success': false,
          'message': response.data?['message'] ?? 'Erro ao deletar conta',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}