import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../widgets/campo_texto_customizado.dart';
import '../widgets/botao_primario.dart';
import '../services/gerenciador_autenticacao.dart';

class TelaEntrar extends StatefulWidget {
  const TelaEntrar({super.key});

  @override
  State<TelaEntrar> createState() => _TelaEntrarState();
}

class _TelaEntrarState extends State<TelaEntrar> {
  final _formularioChave = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _fazerLogin() async {
    if (!_formularioChave.currentState!.validate()) return;

    final gerenciador =
        Provider.of<GerenciadorAutenticacao>(context, listen: false);

    final sucesso = await gerenciador.realizarLogin(
      _emailController.text,
      _senhaController.text,
    );

    if (!mounted) return;

    if (sucesso) {
      context.go('/inicio');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(gerenciador.mensagemErro ?? 'Erro ao fazer login'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161342),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            SizedBox(
              width: 80,
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'VisionGuide',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fazer login em sua conta',
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 40),

            Form(
              key: _formularioChave,
              child: Column(
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
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                          .hasMatch(value)) {
                        return 'E-mail inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CampoTextoCustomizado(
                    label: 'Senha',
                    dica: 'Digite sua senha',
                    controller: _senhaController,
                    esSenha: true,
                    icone: Icons.lock_outlined,
                    validador: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira sua senha';
                      }
                      if (value.length < 6) {
                        return 'A senha deve ter pelo menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Consumer<GerenciadorAutenticacao>(
              builder: (context, gerenciador, _) {
                return BotaoPrimario(
                  texto: 'Entrar',
                  aoClicar: _fazerLogin,
                  estaCarregando: gerenciador.estaCarregando,
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Divider(
                    color: Color(0xFF424242),
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Não tem cadastro?',
                    style: TextStyle(
                      color: const Color(0xFF9CA3AF),
                      fontSize: 14,
                    ),
                  ),
                ),
                const Expanded(
                  child: Divider(
                    color: Color(0xFF424242),
                    thickness: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => context.push('/registrar'),
              child: RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Criar conta',
                      style: TextStyle(
                        color: Color(0xFF7C5CFF),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(
                    color: Color(0xFF424242),
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: SizedBox(
                  width: 20,
                  height: 20,
                  child: Image.asset('assets/images/google.png'),
                ),
                label: const Text('Entrar com o Google'),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
