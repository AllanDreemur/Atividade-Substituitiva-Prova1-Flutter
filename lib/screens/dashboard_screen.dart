import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/abastecimento.dart';
import '../models/veiculo.dart';
import '../services/banco_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Veiculo? _veiculo;
  List<Abastecimento> _abastecimentos = [];

  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final veiculo = await BancoService.buscarVeiculo();

      List<Abastecimento> abastecimentos = [];

      if (veiculo != null) {
        abastecimentos =
            await BancoService.buscarAbastecimentos(veiculo.id!);
      }

      if (!mounted) return;

      setState(() {
        _veiculo = veiculo;
        _abastecimentos = abastecimentos;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erro = 'Não foi possível carregar o dashboard.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  String _formatarData(DateTime data) {
    String doisDigitos(int numero) =>
        numero.toString().padLeft(2, '0');

    return '${doisDigitos(data.day)}/'
        '${doisDigitos(data.month)}/'
        '${data.year} '
        '${doisDigitos(data.hour)}:'
        '${doisDigitos(data.minute)}';
  }

  // Calcula a distância entre dois abastecimentos
  double _calcularDistancia(int index) {
    if (index == 0) return 0;

    final atual = _abastecimentos[index];
    final anterior = _abastecimentos[index - 1];

    return atual.quilometragem - anterior.quilometragem;
  }

  // Calcula o consumo em km/L
  double _calcularConsumo(int index) {
    if (index == 0) return 0;

    final distancia = _calcularDistancia(index);
    final litros = _abastecimentos[index].litros;

    if (distancia <= 0 || litros <= 0) return 0;

    return distancia / litros;
  }

  // Calcula o custo por quilômetro
  double _calcularCustoKm(int index) {
    if (index == 0) return 0;

    final distancia = _calcularDistancia(index);
    final valorTotal = _abastecimentos[index].valorTotal;

    if (distancia <= 0) return 0;

    return valorTotal / distancia;
  }

  // Monta os pontos utilizados pelos gráficos
  List<FlSpot> _gerarPontos(bool consumo) {
    final pontos = <FlSpot>[];

    for (int i = 1; i < _abastecimentos.length; i++) {
      final distancia = _calcularDistancia(i);

      if (distancia <= 0) continue;

      final valor = consumo
          ? _calcularConsumo(i)
          : _calcularCustoKm(i);

      pontos.add(
        FlSpot((i + 1).toDouble(), valor),
      );
    }

    return pontos;
  }

  Widget _construirGrafico({
    required String titulo,
    required bool consumo,
    required Color cor,
  }) {
    final pontos = _gerarPontos(consumo);

    if (pontos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'São necessários pelo menos dois '
            'abastecimentos para exibir o gráfico.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final maiorValor = pontos
        .map((ponto) => ponto.y)
        .reduce((a, b) => a > b ? a : b);

    final maxY = maiorValor > 0 ? maiorValor * 1.2 : 1.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              height: 240,
              child: LineChart(
                LineChartData(
                  minX: 1,
                  maxX: _abastecimentos.length.toDouble(),
                  minY: 0,
                  maxY: maxY,

                  gridData: const FlGridData(
                    show: true,
                  ),

                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey.shade300,
                    ),
                  ),

                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget:
                          const Text('Abastecimento'),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value != value.roundToDouble() ||
                              value < 2 ||
                              value > _abastecimentos.length) {
                            return const SizedBox.shrink();
                          }

                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 11,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(
                              consumo ? 1 : 2,
                            ),
                            style: const TextStyle(
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  lineBarsData: [
                    LineChartBarData(
                      spots: pontos,
                      isCurved: false,
                      color: cor,
                      barWidth: 3,
                      dotData: const FlDotData(
                        show: true,
                      ),
                      belowBarData: BarAreaData(
                        show: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirHistorico() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Indicadores por Abastecimento',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        ...List.generate(_abastecimentos.length, (index) {
          final abastecimento = _abastecimentos[index];

          final distancia = _calcularDistancia(index);
          final consumo = _calcularConsumo(index);
          final custoKm = _calcularCustoKm(index);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Abastecimento ${index + 1}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _formatarData(abastecimento.dataHora),
                  ),

                  Text(
                    'Combustível: ${abastecimento.combustivel}',
                  ),

                  Text(
                    'Quilometragem: '
                    '${abastecimento.quilometragem.toStringAsFixed(1)} km',
                  ),

                  Text(
                    'Litros: '
                    '${abastecimento.litros.toStringAsFixed(2)} L',
                  ),

                  Text(
                    'Valor total: R\$ '
                    '${abastecimento.valorTotal.toStringAsFixed(2)}',
                  ),

                  const SizedBox(height: 10),

                  if (index == 0)
                    const Text(
                      'Primeiro abastecimento: '
                      'referência inicial.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else if (distancia <= 0)
                    const Text(
                      'Não foi possível calcular os '
                      'indicadores deste abastecimento.',
                    )
                  else ...[
                    Text(
                      'Distância percorrida: '
                      '${distancia.toStringAsFixed(1)} km',
                    ),
                    Text(
                      'Consumo: '
                      '${consumo.toStringAsFixed(2)} km/L',
                    ),
                    Text(
                      'Custo por km: R\$ '
                      '${custoKm.toStringAsFixed(3)}/km',
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _construirDashboard() {
    if (_veiculo == null) {
      return const Center(
        child: Text(
          'Cadastre um veículo para visualizar '
          'o dashboard.',
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_abastecimentos.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum abastecimento registrado.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_veiculo!.marca} ${_veiculo!.modelo}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          _construirHistorico(),

          const SizedBox(height: 25),

          const Text(
            'Gráficos de Evolução',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          _construirGrafico(
            titulo: 'Consumo (km/L)',
            consumo: true,
            cor: Colors.blue,
          ),

          const SizedBox(height: 15),

          _construirGrafico(
            titulo: 'Custo por km (R\$/km)',
            consumo: false,
            cor: Colors.green,
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: _carregando ? null : _carregarDados,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _carregando
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _erro != null
              ? Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Text(_erro!),
                      TextButton(
                        onPressed: _carregarDados,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _construirDashboard(),
    );
  }
}
