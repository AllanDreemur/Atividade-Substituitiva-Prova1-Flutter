import 'dart:convert';
import 'package:http/http.dart' as http;

class VeiculoService {
  static const String baseUrl =
      'https://brasilapi.com.br/api/fipe';

  // Consulta as marcas de carros
  Future<List<Map<String, dynamic>>> buscarMarcas() async {
    final url = Uri.parse('$baseUrl/marcas/v1/carros');

    final resposta = await http.get(url).timeout(
      const Duration(seconds: 15),
    );

    if (resposta.statusCode == 200) {
      final List<dynamic> dados = jsonDecode(resposta.body);

      return dados
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    throw Exception('Erro ao consultar marcas');
  }

  // Consulta os modelos da marca selecionada
  Future<List<Map<String, dynamic>>> buscarModelos(
    String codigoMarca,
  ) async {
    final url = Uri.parse(
      '$baseUrl/veiculos/v1/carros/$codigoMarca',
    );

    final resposta = await http.get(url).timeout(
      const Duration(seconds: 15),
    );

    if (resposta.statusCode == 200) {
      final List<dynamic> dados = jsonDecode(resposta.body);

      return dados
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    throw Exception('Erro ao consultar modelos');
  }
}
