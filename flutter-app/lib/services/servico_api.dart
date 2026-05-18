import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/resposta_login_modelo.dart';

class ServicoApi {
  static const String urlBase = 'http://10.0.2.2:8000';

  static Future<RespostaLoginModelo> realizarLogin(
    String email,
    String senha,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$urlBase/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'senha': senha,
        }),
      );

      if (response.statusCode == 200) {
        return RespostaLoginModelo.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        return RespostaLoginModelo(
          status: false,
          mensagem: 'Erro ao fazer login: ${response.statusCode}',
        );
      }
    } catch (e) {
      return RespostaLoginModelo(
        status: false,
        mensagem: 'Erro de conexão: $e',
      );
    }
  }

  static Future<RespostaLoginModelo> registrarUsuario({
    required String email,
    required String nome,
    required String senha,
    required String confirmacaoSenha,
    required String codigoOtp,
  }) async {
    try {
      if (senha != confirmacaoSenha) {
        return RespostaLoginModelo(
          status: false,
          mensagem: 'As senhas não coincidem',
        );
      }

      final response = await http.post(
        Uri.parse('$urlBase/registrar'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'nome': nome,
          'senha': senha,
          'codigoOtp': codigoOtp,
        }),
      );

      if (response.statusCode == 201) {
        return RespostaLoginModelo.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        return RespostaLoginModelo(
          status: false,
          mensagem: 'Erro ao registrar: ${response.statusCode}',
        );
      }
    } catch (e) {
      return RespostaLoginModelo(
        status: false,
        mensagem: 'Erro de conexão: $e',
      );
    }
  }

  static Future<Map<String, dynamic>> enviarOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$urlBase/enviar-otp'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {
          'status': false,
          'mensagem': 'Erro ao enviar OTP: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'status': false,
        'mensagem': 'Erro de conexão: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> verificarOtp({
    required String email,
    required String codigo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$urlBase/verificar-otp'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'codigo': codigo,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {
          'status': false,
          'mensagem': 'Código OTP inválido',
        };
      }
    } catch (e) {
      return {
        'status': false,
        'mensagem': 'Erro de conexão: $e',
      };
    }
  }
}
