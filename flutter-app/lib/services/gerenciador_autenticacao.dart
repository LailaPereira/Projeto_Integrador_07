import 'package:flutter/material.dart';
import '../models/usuario_modelo.dart';
import 'servico_api.dart';

class GerenciadorAutenticacao extends ChangeNotifier {
  UsuarioModelo? _usuarioAtual;
  String? _tokenJwt;
  bool _estaCarregando = false;
  String? _mensagemErro;
  bool _estaAutenticado = false;

  UsuarioModelo? get usuarioAtual => _usuarioAtual;
  String? get tokenJwt => _tokenJwt;
  bool get estaCarregando => _estaCarregando;
  String? get mensagemErro => _mensagemErro;
  bool get estaAutenticado => _estaAutenticado;

  Future<bool> realizarLogin(String email, String senha) async {
    _estaCarregando = true;
    _mensagemErro = null;
    notifyListeners();

    try {
      final resposta = await ServicoApi.realizarLogin(email, senha);

      if (resposta.status && resposta.token != null) {
        _tokenJwt = resposta.token;
        _estaAutenticado = true;
        _usuarioAtual = UsuarioModelo(
          id: resposta.usuario?['id'] ?? '',
          nome: resposta.usuario?['nome'] ?? '',
          email: resposta.usuario?['email'] ?? '',
          fotoPerfil: resposta.usuario?['fotoPerfil'],
          dataCadastro: DateTime.now(),
        );

        _estaCarregando = false;
        notifyListeners();
        return true;
      } else {
        _mensagemErro = resposta.mensagem;
        _estaCarregando = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _mensagemErro = 'Erro ao fazer login: $e';
      _estaCarregando = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registrarUsuario({
    required String email,
    required String nome,
    required String senha,
    required String confirmacaoSenha,
    required String codigoOtp,
  }) async {
    _estaCarregando = true;
    _mensagemErro = null;
    notifyListeners();

    try {
      final resposta = await ServicoApi.registrarUsuario(
        email: email,
        nome: nome,
        senha: senha,
        confirmacaoSenha: confirmacaoSenha,
        codigoOtp: codigoOtp,
      );

      if (resposta.status) {
        _tokenJwt = resposta.token;
        _estaAutenticado = true;

        _estaCarregando = false;
        notifyListeners();
        return true;
      } else {
        _mensagemErro = resposta.mensagem;
        _estaCarregando = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _mensagemErro = 'Erro ao registrar: $e';
      _estaCarregando = false;
      notifyListeners();
      return false;
    }
  }

  void desconectar() {
    _usuarioAtual = null;
    _tokenJwt = null;
    _estaAutenticado = false;
    _mensagemErro = null;
    notifyListeners();
  }
}
