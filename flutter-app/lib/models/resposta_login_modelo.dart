class RespostaLoginModelo {
  final bool status;
  final String mensagem;
  final String? token;
  final Map<String, dynamic>? usuario;

  RespostaLoginModelo({
    required this.status,
    required this.mensagem,
    this.token,
    this.usuario,
  });

  factory RespostaLoginModelo.fromJson(Map<String, dynamic> json) {
    return RespostaLoginModelo(
      status: json['status'] as bool? ?? false,
      mensagem: json['mensagem'] as String? ?? '',
      token: json['token'] as String?,
      usuario: json['usuario'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'mensagem': mensagem,
      'token': token,
      'usuario': usuario,
    };
  }
}
