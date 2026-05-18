import 'package:flutter/material.dart';

class BotaoPrimario extends StatelessWidget {
  final String texto;
  final VoidCallback aoClicar;
  final bool estaCarregando;
  final bool estaDesabilitado;
  final Color? cor;
  final IconData? icone;

  const BotaoPrimario({
    super.key,
    required this.texto,
    required this.aoClicar,
    this.estaCarregando = false,
    this.estaDesabilitado = false,
    this.cor,
    this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: cor ?? const Color(0xFF7C5CFF),
          disabledBackgroundColor: Colors.grey.shade700,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: estaCarregando || estaDesabilitado ? null : aoClicar,
        child: estaCarregando
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icone != null) ...[
                    Icon(icone),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    texto,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
