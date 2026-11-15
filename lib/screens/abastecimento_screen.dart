import 'package:flutter/material.dart';

import '../models/abastecimento.dart';
import '../models/veiculo.dart';
import '../services/banco_service.dart';

class AbastecimentoScreen extends StatefulWidget {
  const AbastecimentoScreen({super.key});

  @override
  State<AbastecimentoScreen> createState() =>
      _AbastecimentoScreenState();
}

class _AbastecimentoScreenState
    extends State<AbastecimentoScreen> {
  final _formKey = GlobalKey<FormState>();

  final _precoController = TextEditingController();
  final _kmController = TextEditingController();
  final _litrosController = TextEditingController();

  String _combustivel = 'Gasolina';

  Veiculo? _veiculo;
  List<Abastecimento> _abastecimentos = [];

  bool _carregando = true;
  bool _salvando = false;
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
        _erro = 'Não foi possível carregar os abastecimentos.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  double? _converterNumero(String texto) {
    return double.tryParse(
      texto.trim().replaceAll(',', '.'),
    );
  }

  String? _validarNumero(String? valor) {
    final numero = _converterNumero(valor ?? '');

    if (numero == null || numero <= 0) {
      return 'Informe um valor maior que zero';
    }

    return null;
  }

  Future<void> _salvarAbastecimento() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_veiculo == null) return;

    final preco = _converterNumero(_precoController.text)!;
    final km = _converterNumero(_kmController.text)!;
    final litros = _converterNumero(_litrosController.text)!;

    // A quilometragem deve avançar a cada abastecimento.
    if (_abastecimentos.isNotEmpty) {
      final ultimo = _abastecimentos.last;

      if (km <= ultimo.quilometragem) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'A quilometragem deve ser maior que a '
              'do último abastecimento.',
            ),
          ),
        );
        return;
      }
    }

    final abastecimento = Abastecimento(
      veiculoId: _veiculo!.id!,
      combustivel: _combustivel,
      precoLitro: preco,
      quilometragem: km,
      litros: litros,
      dataHora: DateTime.now(),
    );

    setState(() {
      _salvando = true;
    });

    try {
      await BancoService.salvarAbastecimento(abastecimento);

      if (!mounted) return;

      _precoController.clear();
      _kmController.clear();
      _litrosController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Abastecimento salvo com sucesso!'),
        ),
      );

      await _carregarDados();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao salvar abastecimento.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
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

  Widget _construirFormulario() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Novo Abastecimento',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            initialValue: _combustivel,
            decoration: const InputDecoration(
              labelText: 'Tipo de combustível',
              border: OutlineInputBorder(),
            ),
            items: ['Gasolina', 'Etanol', 'Diesel'].map((tipo) {
              return DropdownMenuItem(
                value: tipo,
                child: Text(tipo),
              );
            }).toList(),
            onChanged: (valor) {
              if (valor != null) {
                setState(() {
                  _combustivel = valor;
                });
              }
            },
          ),

          const SizedBox(height: 15),

          TextFormField(
            controller: _precoController,
            decoration: const InputDecoration(
              labelText: 'Preço por litro (R\$)',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            validator: _validarNumero,
          ),

          const SizedBox(height: 15),

          TextFormField(
            controller: _kmController,
            decoration: const InputDecoration(
              labelText: 'Quilometragem atual (km)',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            validator: _validarNumero,
          ),

          const SizedBox(height: 15),

          TextFormField(
            controller: _litrosController,
            decoration: const InputDecoration(
              labelText: 'Quantidade de litros',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            validator: _validarNumero,
          ),

          const SizedBox(height: 10),

          const Text(
            'A data e a hora serão registradas automaticamente.',
          ),

          const SizedBox(height: 25),

          ElevatedButton(
            onPressed: _salvando ? null : _salvarAbastecimento,
            child: const Text('Salvar Abastecimento'),
          ),
        ],
      ),
    );
  }

  Widget _construirHistorico() {
    if (_abastecimentos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text('Nenhum abastecimento registrado.'),
        ),
      );
    }

    return Column(
      children: _abastecimentos.reversed.map((abastecimento) {
        return Card(
          child: ListTile(
            leading: const Icon(Icons.local_gas_station),
            title: Text(
              '${abastecimento.combustivel} - '
              'R\$ ${abastecimento.valorTotal.toStringAsFixed(2)}',
            ),
            subtitle: Text(
              '${abastecimento.litros.toStringAsFixed(2)} L | '
              '${abastecimento.quilometragem.toStringAsFixed(1)} km\n'
              '${_formatarData(abastecimento.dataHora)}',
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    _precoController.dispose();
    _kmController.dispose();
    _litrosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Abastecimentos'),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_erro!),
                      TextButton(
                        onPressed: _carregarDados,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _veiculo == null
                  ? const Center(
                      child: Text(
                        'Cadastre um veículo antes de '
                        'registrar abastecimentos.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${_veiculo!.marca} ${_veiculo!.modelo}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 25),

                          _construirFormulario(),

                          const SizedBox(height: 30),

                          const Divider(),

                          const SizedBox(height: 15),

                          const Text(
                            'Histórico de Abastecimentos',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 15),

                          _construirHistorico(),
                        ],
                      ),
                    ),
    );
  }
}
