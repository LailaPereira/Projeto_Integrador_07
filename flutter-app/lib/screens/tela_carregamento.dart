import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TelaCarregamento extends StatefulWidget {
  const TelaCarregamento({super.key});

  @override
  State<TelaCarregamento> createState() => _TelaCarregamentoState();
}

class _TelaCarregamentoState extends State<TelaCarregamento> {
  @override
  void initState() {
    super.initState();
    _naveguarAposDelai();
  }

  void _naveguarAposDelai() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/entrar');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161342),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 230,
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
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Enxergando o mundo por você',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 60),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C5CFF)),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
