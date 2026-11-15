class Abastecimento {
  final int? id;
  final int veiculoId;
  final String combustivel;
  final double precoLitro;
  final double quilometragem;
  final double litros;
  final DateTime dataHora;

  const Abastecimento({
    this.id,
    required this.veiculoId,
    required this.combustivel,
    required this.precoLitro,
    required this.quilometragem,
    required this.litros,
    required this.dataHora,
  });

  double get valorTotal => precoLitro * litros;

  Map<String, Object?> toMap() {
    return {
      'veiculo_id': veiculoId,
      'combustivel': combustivel,
      'preco_litro': precoLitro,
      'quilometragem': quilometragem,
      'litros': litros,
      'data_hora': dataHora.toUtc().toIso8601String(),
    };
  }

  factory Abastecimento.fromMap(Map<String, Object?> map) {
    return Abastecimento(
      id: map['id'] as int,
      veiculoId: map['veiculo_id'] as int,
      combustivel: map['combustivel'] as String,
      precoLitro: (map['preco_litro'] as num).toDouble(),
      quilometragem: (map['quilometragem'] as num).toDouble(),
      litros: (map['litros'] as num).toDouble(),
      dataHora: DateTime.parse(map['data_hora'] as String).toLocal(),
    );
  }
}
