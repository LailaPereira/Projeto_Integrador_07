import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'tela_perfil.dart';

class TelaInicio extends StatefulWidget {
  const TelaInicio({super.key});

  @override
  State<TelaInicio> createState() => _TelaInicioState();
}

class _TelaInicioState extends State<TelaInicio> {
  int _indiceAbaSelecionada = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161342),
      body: IndexedStack(
        index: _indiceAbaSelecionada,
        children: [
          _TelaInicioConteudo(),
          _TelaGaleria(),
          const TelaPerfil(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceAbaSelecionada,
        onDestinationSelected: (int indice) {
          setState(() {
            _indiceAbaSelecionada = indice;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: 'Galeria',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class _TelaInicioConteudo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background_pattern.png'),
              fit: BoxFit.cover,
              opacity: 0.15,
            ),
            color: const Color(0xFF161342),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'VisionGuide',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Conectando dispositivos...'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bluetooth_connected),
                    label: const Text(
                      'Ligar dispositivos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }
}

class _TelaGaleria extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      _ItemGaleria(titulo: 'Praia', tipo: 'Foto', cor: const Color(0xFF63A7FF)),
      _ItemGaleria(
          titulo: 'Floresta', tipo: 'Foto', cor: const Color(0xFF7AD089)),
      _ItemGaleria(titulo: 'Mar', tipo: 'Vídeo', cor: const Color(0xFF42CBE2)),
      _ItemGaleria(
          titulo: 'Cidade', tipo: 'Foto', cor: const Color(0xFF9FA9C7)),
      _ItemGaleria(titulo: 'Noite', tipo: 'Foto', cor: const Color(0xFF6D7EFF)),
      _ItemGaleria(titulo: 'Rua', tipo: 'Vídeo', cor: const Color(0xFFF0A35C)),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Galeria',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          item.cor.withOpacity(0.8),
                          const Color(0xFF1A1F3A),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            item.tipo,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.titulo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemGaleria {
  final String titulo;
  final String tipo;
  final Color cor;

  _ItemGaleria({
    required this.titulo,
    required this.tipo,
    required this.cor,
  });
}
