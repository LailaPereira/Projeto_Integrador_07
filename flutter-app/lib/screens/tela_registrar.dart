import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../widgets/campo_texto_customizado.dart';
import '../widgets/botao_primario.dart';
import '../services/gerenciador_autenticacao.dart';
import '../services/servico_api.dart';

class TelaRegistrar extends StatefulWidget {
  const TelaRegistrar({super.key});

  @override
  State<TelaRegistrar> createState() => _TelaRegistrarState();
}

class _TelaRegistrarState extends State<TelaRegistrar> {
  final _formularioChave = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codigoOtpController = TextEditingController();
  final _nomeController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmacaoSenhaController = TextEditingController();

  int _segundosRestantes = 0;
  late Timer _timerOtp;
  bool _otpEnviado = false;
  final bool _otpVerificado = false;
  bool _estaEnviandoOtp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codigoOtpController.dispose();
    _nomeController.dispose();
    _senhaController.dispose();
    _confirmacaoSenhaController.dispose();
    _timerOtp.cancel();
    super.dispose();
  }

  Future<void> _enviarOtp() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, insira seu e-mail primeiro'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _estaEnviandoOtp = true;
    });

    final resultado = await ServicoApi.enviarOtp(_emailController.text);

    setState(() {
      _estaEnviandoOtp = false;
    });

    if (resultado['status'] == true) {
      setState(() {
        _otpEnviado = true;
        _segundosRestantes = 130;
      });

      _timerOtp = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _segundosRestantes--;
        });

        if (_segundosRestantes <= 0) {
          timer.cancel();
          setState(() {
            _otpEnviado = false;
            _codigoOtpController.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Código OTP expirou. Solicite um novo.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código OTP enviado para seu e-mail'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['mensagem'] ?? 'Erro ao enviar OTP'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verificarOtpERegistrar() async {
    if (!_formularioChave.currentState!.validate()) return;

    if (_codigoOtpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, insira o código OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_senhaController.text != _confirmacaoSenhaController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('As senhas não coincidem'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final verificacao = await ServicoApi.verificarOtp(
      email: _emailController.text,
      codigo: _codigoOtpController.text,
    );

    if (verificacao['status'] != true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(verificacao['mensagem'] ?? 'OTP inválido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;
    final gerenciador =
        Provider.of<GerenciadorAutenticacao>(context, listen: false);

    final sucesso = await gerenciador.registrarUsuario(
      email: _emailController.text,
      nome: _nomeController.text,
      senha: _senhaController.text,
      confirmacaoSenha: _confirmacaoSenhaController.text,
      codigoOtp: _codigoOtpController.text,
    );

    if (!mounted) return;

    if (sucesso) {
      context.go('/inicio');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(gerenciador.mensagemErro ?? 'Erro ao registrar'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatarTempo(int segundos) {
    final minutos = segundos ~/ 60;
    final segs = segundos % 60;
    return '$minutos:${segs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161342),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161342),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Registrar'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formularioChave,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CampoTextoCustomizado(
                label: 'E-mail',
                dica: 'seu@email.com',
                controller: _emailController,
                icone: Icons.email_outlined,
                validador: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira seu e-mail';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'E-mail inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CampoTextoCustomizado(
                      label: 'Código de verificação',
                      dica: '000000',
                      controller: _codigoOtpController,
                      icone: Icons.lock_outline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: _otpEnviado || _estaEnviandoOtp
                              ? null
                              : _enviarOtp,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFF7C5CFF),
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 8,
                            ),
                          ),
                          child: _estaEnviandoOtp
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : _otpEnviado
                                  ? Text(
                                      _formatarTempo(_segundosRestantes),
                                      style: const TextStyle(
                                        color: Color(0xFF7C5CFF),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : const Text('Enviar'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CampoTextoCustomizado(
                label: 'Nome Utilizador',
                dica: 'Seu nome completo',
                controller: _nomeController,
                icone: Icons.person_outline,
                validador: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira seu nome';
                  }
                  if (value.length < 3) {
                    return 'O nome deve ter pelo menos 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CampoTextoCustomizado(
                label: 'Senha',
                dica: 'Digite uma senha forte',
                controller: _senhaController,
                esSenha: true,
                icone: Icons.lock_outlined,
                validador: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira uma senha';
                  }
                  if (value.length < 6) {
                    return 'A senha deve ter pelo menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CampoTextoCustomizado(
                label: 'Confirmar senha',
                dica: 'Confirme sua senha',
                controller: _confirmacaoSenhaController,
                esSenha: true,
                icone: Icons.lock_outlined,
                validador: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, confirme sua senha';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              Consumer<GerenciadorAutenticacao>(
                builder: (context, gerenciador, _) {
                  return BotaoPrimario(
                    texto: 'Confirmar',
                    aoClicar: _verificarOtpERegistrar,
                    estaCarregando: gerenciador.estaCarregando,
                  );
                },
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: const Text(
                    'Já tem conta? Voltar para login',
                    style: TextStyle(
                      color: Color(0xFF7C5CFF),
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
