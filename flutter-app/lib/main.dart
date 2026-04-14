import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

void main() {
  runApp(const VisionGuideApp());
}

class VisionGuideApp extends StatelessWidget {
  const VisionGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF63A7FF),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VisionGuide Mobile',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFF08111F),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xF208111F),
          indicatorColor: const Color(0x2663A7FF),
          labelTextStyle: MaterialStateProperty.all(
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            side: BorderSide(color: Colors.white.withOpacity(0.12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0x141F2A3D),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintStyle: const TextStyle(color: Color(0xFF8F9AB3)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const VisionGuideHome(),
    );
  }
}

class VisionGuideHome extends StatefulWidget {
  const VisionGuideHome({super.key});

  @override
  State<VisionGuideHome> createState() => _VisionGuideHomeState();
}

class _VisionGuideHomeState extends State<VisionGuideHome> {
  int _index = 0;
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();

  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      role: _ChatRole.assistant,
      text: 'Olá. Posso descrever o ambiente, ler textos e ajudar na navegação.',
    ),
  ];

  static const _galleryItems = <_GalleryItem>[
    _GalleryItem(title: 'Praia', kind: 'Foto', tint: Color(0xFF63A7FF)),
    _GalleryItem(title: 'Floresta', kind: 'Foto', tint: Color(0xFF7AD089)),
    _GalleryItem(title: 'Mar', kind: 'Vídeo', tint: Color(0xFF42CBE2)),
    _GalleryItem(title: 'Cidade', kind: 'Foto', tint: Color(0xFF9FA9C7)),
    _GalleryItem(title: 'Noite', kind: 'Foto', tint: Color(0xFF6D7EFF)),
    _GalleryItem(title: 'Rua', kind: 'Vídeo', tint: Color(0xFFF0A35C)),
  ];

  static const _quickActions = <_QuickAction>[
    _QuickAction(
      title: 'Descrever ambiente',
      subtitle: 'Leitura rápida do cenário',
      icon: Icons.visibility_outlined,
    ),
    _QuickAction(
      title: 'Ler texto',
      subtitle: 'Reconhecer placas e avisos',
      icon: Icons.document_scanner_outlined,
    ),
    _QuickAction(
      title: 'Alertar obstáculos',
      subtitle: 'Aviso de navegação em tempo real',
      icon: Icons.warning_amber_rounded,
    ),
  ];

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendChat() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(role: _ChatRole.user, text: text));
      _messages.add(
        const _ChatMessage(
          role: _ChatRole.assistant,
          text: 'Resposta simulada da IA no protótipo Flutter. Aqui depois entra o backend real.',
        ),
      );
      _chatController.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _captureAndSendToChat() async {
    try {
      final capture = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 72,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (capture == null) return;

      final bytes = await capture.readAsBytes();

      setState(() {
        _messages.add(
          _ChatMessage(
            role: _ChatRole.user,
            text: 'Imagem capturada e enviada para análise.',
            imageBytes: bytes,
          ),
        );
        _messages.add(
          const _ChatMessage(
            role: _ChatRole.assistant,
            text: 'Recebi a imagem. Posso descrever o ambiente, destacar objetos e sugerir próximos passos.',
          ),
        );
        _index = 2;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir a câmera agora.')),
      );
    }
  }

  void _openCamera() {
    setState(() => _index = 1);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _HomeTab(
        key: const ValueKey('home'),
        quickActions: _quickActions,
        onOpenCamera: _openCamera,
      ),
        _CameraTab(
          key: const ValueKey('camera'),
          onCaptureAndSend: _captureAndSendToChat,
        ),
      _ChatTab(
        key: const ValueKey('chat'),
        messages: _messages,
        controller: _chatController,
        scrollController: _scrollController,
        onSend: _sendChat,
      ),
      _GalleryTab(
        key: const ValueKey('gallery'),
        items: _galleryItems,
      ),
      const _ProfileTab(key: ValueKey('profile')),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF08111F), Color(0xFF0D1730), Color(0xFF07101B)],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _AppHeader(
                  title: 'VisionGuide',
                  subtitle: 'Flutter mobile preview',
                  chip: _index == 1 ? 'Câmera' : _index == 2 ? 'IA' : _index == 3 ? 'Galeria' : _index == 4 ? 'Perfil' : 'Nativo',
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: pages[_index],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (value) => setState(() => _index = value),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Início'),
            NavigationDestination(
              icon: Icon(Icons.center_focus_strong_outlined),
              selectedIcon: Icon(Icons.center_focus_strong_rounded),
              label: 'Câmera',
            ),
            NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble_rounded), label: 'IA'),
            NavigationDestination(
              icon: Icon(Icons.photo_library_outlined),
              selectedIcon: Icon(Icons.photo_library_rounded),
              label: 'Galeria',
            ),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person_rounded), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader({required this.title, required this.subtitle, required this.chip});

  final String title;
  final String subtitle;
  final String chip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFF9EA9C2)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x1A63A7FF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0x3363A7FF)),
            ),
            child: Text(chip),
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({super.key, required this.quickActions, required this.onOpenCamera});

  final List<_QuickAction> quickActions;
  final VoidCallback onOpenCamera;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('home'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        _HeroCard(onOpenCamera: onOpenCamera),
        const SizedBox(height: 14),
        Row(
          children: const [
            Expanded(child: _StatCard(value: '3', label: 'fluxos')),
            SizedBox(width: 10),
            Expanded(child: _StatCard(value: '1', label: 'experiência')),
            SizedBox(width: 10),
            Expanded(child: _StatCard(value: '24/7', label: 'acesso')),
          ],
        ),
        const SizedBox(height: 14),
        _SectionTitle(title: 'Atalhos rápidos', subtitle: 'Ações mais usadas no app'),
        const SizedBox(height: 10),
        ...quickActions.map((action) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _QuickActionCard(action: action),
            )),
        const SizedBox(height: 6),
        _SectionTitle(title: 'Status da sessão', subtitle: 'Resumo visual do protótipo'),
        const SizedBox(height: 10),
        const _StatusPanel(),
      ],
    ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.03, end: 0);
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onOpenCamera});

  final VoidCallback onOpenCamera;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF17253C), Color(0xFF0F1727), Color(0xFF08111F)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 30, offset: Offset(0, 14)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VisionGuide Mobile',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF9EA9C2),
                  letterSpacing: 1.1,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Seu app de apoio visual no celular',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                  letterSpacing: -0.6,
                ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Base Flutter com foco em experiência nativa, acessibilidade e navegação rápida.',
            style: TextStyle(color: Color(0xFF9EA9C2), height: 1.4),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onOpenCamera,
            icon: const Icon(Icons.center_focus_strong_rounded),
            label: const Text('Abrir câmera assistiva'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: Color(0xFF9EA9C2), fontSize: 12)),
          ],
        ),
        TextButton(onPressed: () {}, child: const Text('Ver tudo')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 94,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x141F2A3D),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Color(0xFF9EA9C2))),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0x141F2A3D),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x1A63A7FF),
              border: Border.all(color: const Color(0x3363A7FF)),
            ),
            child: Icon(action.icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(action.subtitle, style: const TextStyle(color: Color(0xFF9EA9C2))),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF9EA9C2)),
        ],
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0x141F2A3D),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChipRow(label: 'Câmera', value: 'pronta'),
          SizedBox(height: 10),
          _ChipRow(label: 'IA', value: 'online'),
          SizedBox(height: 10),
          _ChipRow(label: 'Áudio', value: 'ativo'),
        ],
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF9EA9C2))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0x1A63A7FF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(value),
        ),
      ],
    );
  }
}

class _CameraTab extends StatelessWidget {
  const _CameraTab({super.key, required this.onCaptureAndSend});

  final Future<void> Function() onCaptureAndSend;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('camera'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Text('Câmera assistiva', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('Espaço reservado para integração com câmera, OCR e visão computacional.'),
        const SizedBox(height: 14),
        Container(
          height: 470,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF18253D), Color(0xFF07101D)],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 30, offset: Offset(0, 16)),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.2, -0.3),
                      radius: 1,
                      colors: [const Color(0x3363A7FF), Colors.transparent],
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 18,
                top: 18,
                child: _MiniBadge(text: 'Preview ao vivo'),
              ),
              const Center(
                child: Icon(Icons.center_focus_strong_rounded, size: 112, color: Colors.white70),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xC208111F),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: const Text(
                    'Aponte o celular para um texto, objeto ou obstáculo.\nAqui entra a câmera real quando a integração estiver pronta.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.search_rounded), label: const Text('Analisar agora'))),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.autorenew_rounded), label: const Text('Modo contínuo'))),
          ],
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: onCaptureAndSend,
          icon: const Icon(Icons.camera_alt_rounded),
          label: const Text('Capturar e enviar ao chat IA'),
        ),
      ],
    ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.03, end: 0);
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xB208111F),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _ChatTab extends StatelessWidget {
  const _ChatTab({
    super.key,
    required this.messages,
    required this.controller,
    required this.scrollController,
    required this.onSend,
  });

  final List<_ChatMessage> messages;
  final TextEditingController controller;
  final ScrollController scrollController;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Chat com IA', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Conversa rápida para pedir descrição, orientação e ajuda.'),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              itemCount: messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final message = messages[index];
                final isUser = message.role == _ChatRole.user;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 330),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0x2663A7FF) : const Color(0x141F2A3D),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.imageBytes != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              message.imageBytes!,
                              height: 160,
                              width: 260,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        Text(message.text),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 220.ms, delay: (index * 26).ms).slideY(begin: 0.05, end: 0);
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: const InputDecoration(
                    hintText: 'Pergunte algo para a IA...',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(onPressed: onSend, child: const Text('Enviar')),
            ],
          ),
        ],
      ),
    );
  }
}

class _GalleryTab extends StatelessWidget {
  const _GalleryTab({super.key, required this.items});

  final List<_GalleryItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Galeria', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Linha de mídia recente para o protótipo VisionGuide.'),
          const SizedBox(height: 14),
          Expanded(
            child: GridView.builder(
              itemCount: items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.94,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [item.tint.withOpacity(0.98), const Color(0xFF101B2F)],
                    ),
                    boxShadow: const [
                      BoxShadow(color: Color(0x22000000), blurRadius: 18, offset: Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(item.kind, style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 6),
                      Text(item.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: const [
        _ProfileHeader(),
        SizedBox(height: 14),
        _SettingRow(title: 'Voz', value: 'PT-BR'),
        SizedBox(height: 10),
        _SettingRow(title: 'Velocidade', value: 'Normal'),
        SizedBox(height: 10),
        _SettingRow(title: 'Alertas', value: 'Ativos'),
        SizedBox(height: 10),
        _SettingRow(title: 'Tema', value: 'Escuro'),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF17253C), Color(0xFF0F1727)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x1A63A7FF),
              border: Border.all(color: const Color(0x3363A7FF)),
            ),
            child: const Icon(Icons.person_rounded, size: 34, color: Colors.white),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Perfil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text(
                  'Preferências de voz, alertas e resposta rápida.',
                  style: TextStyle(color: Color(0xFF9EA9C2), height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0x141F2A3D),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({required this.title, required this.subtitle, required this.icon});

  final String title;
  final String subtitle;
  final IconData icon;
}

class _GalleryItem {
  const _GalleryItem({required this.title, required this.kind, required this.tint});

  final String title;
  final String kind;
  final Color tint;
}

enum _ChatRole { user, assistant }

class _ChatMessage {
  const _ChatMessage({required this.role, required this.text, this.imageBytes});

  final _ChatRole role;
  final String text;
  final Uint8List? imageBytes;
}
