class UsuarioModelo {
  final String id;
  final String nome;
  final String email;
  final String? fotoPerfil;
  final DateTime dataCadastro;

  UsuarioModelo({
    required this.id,
    required this.nome,
    required this.email,
    this.fotoPerfil,
    required this.dataCadastro,
  });

  factory UsuarioModelo.fromJson(Map<String, dynamic> json) {
    return UsuarioModelo(
      id: json['id'] as String,
      nome: json['nome'] as String,
      email: json['email'] as String,
      fotoPerfil: json['fotoPerfil'] as String?,
      dataCadastro: DateTime.parse(json['dataCadastro'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'fotoPerfil': fotoPerfil,
      'dataCadastro': dataCadastro.toIso8601String(),
    };
  }
}
