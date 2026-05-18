import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/gerenciador_autenticacao.dart';

class TelaPerfil extends StatelessWidget {
  const TelaPerfil({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Perfil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF252A4D),
                      border: Border.all(
                        color: const Color(0xFF7C5CFF),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Color(0xFF7C5CFF),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Vladimir Nepomuceno',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'vladimir@email.com',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Color(0xFF7C5CFF),
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Editar informação'),
              ),
            ),
            const SizedBox(height: 32),
            _CardOpcao(
              titulo: 'Conta e Segurança',
              icone: Icons.security_outlined,
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _CardOpcao(
              titulo: 'Definições de permissões backend',
              icone: Icons.settings_outlined,
              onTap: () {
                context.push('/permissoes-backend');
              },
            ),
            const SizedBox(height: 12),
            _CardOpcao(
              titulo: 'Sobre',
              icone: Icons.info_outlined,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: const Color(0xFF252A4D),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (context) => _ModalSobre(),
                );
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.2),
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(
                      color: Colors.red,
                      width: 1,
                    ),
                  ),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF252A4D),
                      title: const Text('Desconectar?'),
                      content: const Text(
                        'Tem certeza que deseja sair da sua conta?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () {
                            Provider.of<GerenciadorAutenticacao>(
                              context,
                              listen: false,
                            ).desconectar();
                            Navigator.pop(context);
                            context.go('/entrar');
                          },
                          child: const Text(
                            'Sair',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Desconectar'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _CardOpcao extends StatelessWidget {
  final String titulo;
  final IconData icone;
  final VoidCallback onTap;

  const _CardOpcao({
    required this.titulo,
    required this.icone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF252A4D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icone,
              color: const Color(0xFF7C5CFF),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.white30,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModalSobre extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sobre VisionGuide',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Versão: 1.0.0',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Equipe de Desenvolvimento:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '• Pedro H. A. Nascimento\n'
            '• Laila Maria Silva Pereira\n'
            '• Yago Barbosa de Andrade Oliveira\n'
            '• José Luiz Henrique Pereira',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {},
            child: const Text(
              'Repositório: https://github.com/Lemigro/visionGuide',
              style: TextStyle(
                color: Color(0xFF7C5CFF),
                fontSize: 12,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ),
        ],
      ),
    );
  }
}
