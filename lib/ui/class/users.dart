class Usuario {
  final int id;
  final String nome;
  final String email;
  final String? fotoUrl;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    this.fotoUrl,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      nome: json['nome'],
      email: json['email'],
      fotoUrl: json['foto'],
    );
  }
}