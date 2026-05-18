import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TelaPermissoesBackend extends StatelessWidget {
  const TelaPermissoesBackend({super.key});

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
        title: const Text('Permissões Backend'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Definições de permissões de backend',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Para evitar que o sistema móvel interrompa a operação do aplicativo e afete o uso da rede de compartilhamento Bluetooth, notificação de mensagens e outras funções, conclua as seguintes configurações:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            _CardPermissao(
              titulo: 'Otimização da bateria',
              subtitulo:
                  'Evitar que o sistema interrompa a operação do aplicativo para economizar energia',
              onPresionar: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Abrindo configurações de bateria...'),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _CardPermissao(
              titulo: 'Permitir operação em segundo plano',
              subtitulo:
                  'Certifique-se de que o aplicativo ainda possa ser executado ativamente após sair do segundo plano',
              onPresionar: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Exibindo tutorial...'),
                  ),
                );
              },
              botaoTexto: 'Ver tutorial',
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF252A4D).withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dicas:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Essas configurações garantem que o VisionGuide funcione continuamente\n'
                    '• Permita o uso de bateria sem restrições\n'
                    '• Configure o Bluetooth para conexão permanente\n'
                    '• Verifique as permissões de câmera e microfone',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardPermissao extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final VoidCallback onPresionar;
  final String botaoTexto;

  const _CardPermissao({
    required this.titulo,
    required this.subtitulo,
    required this.onPresionar,
    this.botaoTexto = 'Acessar as configurações',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF252A4D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitulo,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C5CFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onPresionar,
              child: Text(botaoTexto),
            ),
          ),
        ],
      ),
    );
  }
}
