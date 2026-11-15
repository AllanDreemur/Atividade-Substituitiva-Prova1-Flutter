import 'package:flutter/material.dart';

import '../models/veiculo.dart';
import '../services/banco_service.dart';
import '../services/veiculo_service.dart';

class VeiculoScreen extends StatefulWidget {
  const VeiculoScreen({super.key});

  @override
  State<VeiculoScreen> createState() => _VeiculoScreenState();
}

class _VeiculoScreenState extends State<VeiculoScreen> {
  final _formKey = GlobalKey<FormState>();

  final _anoController = TextEditingController();
  final _cilindradaController = TextEditingController();

  final VeiculoService _service = VeiculoService();

  List<Map<String, dynamic>> _marcas = [];
  List<Map<String, dynamic>> _modelos = [];

  String? _marcaSelecionada;
  String? _modeloSelecionado;

  Veiculo? _veiculo;

  bool _carregando = true;
  bool _carregandoMarcas = false;
  bool _carregandoModelos = false;
  bool _salvando = false;

  String? _erroMarcas;
  String? _erroModelos;
  String? _erroInicial;

  @override
  void initState() {
    super.initState();
    _carregarVeiculo();
  }

  Future<void> _carregarVeiculo() async {
    setState(() {
      _carregando = true;
      _erroInicial = null;
    });

    try {
      final veiculo = await BancoService.buscarVeiculo();

      if (!mounted) return;

      setState(() {
        _veiculo = veiculo;
      });

      if (veiculo == null) {
        await _buscarMarcas();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erroInicial = 'Não foi possível carregar os dados.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  Future<void> _buscarMarcas() async {
    setState(() {
      _carregandoMarcas = true;
      _erroMarcas = null;
    });

    try {
      final marcas = await _service.buscarMarcas();

      if (!mounted) return;

      setState(() {
        _marcas = marcas;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _erroMarcas = 'Não foi possível carregar as marcas.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _carregandoMarcas = false;
        });
      }
    }
  }

  Future<void> _buscarModelos(String codigoMarca) async {
    setState(() {
      _carregandoModelos = true;
      _erroModelos = null;
      _modelos = [];
      _modeloSelecionado = null;
    });

    try {
      final modelos = await _service.buscarModelos(codigoMarca);

      if (!mounted || _marcaSelecionada != codigoMarca) {
        return;
      }

      setState(() {
        _modelos = modelos;
      });
    } catch (e) {
      if (!mounted || _marcaSelecionada != codigoMarca) {
        return;
      }

      setState(() {
        _erroModelos = 'Não foi possível carregar os modelos.';
      });
    } finally {
      if (mounted && _marcaSelecionada == codigoMarca) {
        setState(() {
          _carregandoModelos = false;
        });
      }
    }
  }

  Future<void> _cadastrarVeiculo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final marca = _marcas.firstWhere(
      (item) => item['valor'].toString() == _marcaSelecionada,
    );

    final modelo = _modelos.firstWhere(
      (item) => item['valor'].toString() == _modeloSelecionado,
    );

    final veiculo = Veiculo(
      marca: marca['nome'].toString(),
      modelo: modelo['modelo'].toString(),
      ano: int.parse(_anoController.text.trim()),
      cilindrada: _cilindradaController.text.trim(),
    );

    setState(() {
      _salvando = true;
    });

    try {
      await BancoService.salvarVeiculo(veiculo);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veículo cadastrado com sucesso!'),
        ),
      );

      await _carregarVeiculo();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível cadastrar o veículo.'),
        ),
      );

      await _carregarVeiculo();
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  Future<void> _excluirVeiculo() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir veículo'),
          content: const Text(
            'Deseja realmente excluir este veículo? '
            'Todos os abastecimentos associados '
            'também serão excluídos.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || _veiculo == null) {
      return;
    }

    setState(() {
      _salvando = true;
    });

    try {
      await BancoService.excluirVeiculo(_veiculo!.id!);

      if (!mounted) return;

      setState(() {
        _veiculo = null;
        _marcaSelecionada = null;
        _modeloSelecionado = null;
        _modelos = [];
        _marcas = [];
        _anoController.clear();
        _cilindradaController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veículo excluído com sucesso!'),
        ),
      );

      await _carregarVeiculo();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível excluir o veículo.'),
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

  @override
  void dispose() {
    _anoController.dispose();
    _cilindradaController.dispose();
    super.dispose();
  }

  Widget _campoInformacao(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(valor),
        ],
      ),
    );
  }

  Widget _construirVeiculo() {
    final veiculo = _veiculo!;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.directions_car,
            size: 70,
            color: Colors.blue,
          ),
          const SizedBox(height: 20),
          const Text(
            'Veículo Cadastrado',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 25),
          _campoInformacao('Marca', veiculo.marca),
          _campoInformacao('Modelo', veiculo.modelo),
          _campoInformacao('Ano', veiculo.ano.toString()),
          _campoInformacao('Cilindrada', veiculo.cilindrada),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _salvando ? null : _excluirVeiculo,
            icon: const Icon(Icons.delete),
            label: const Text('Excluir Veículo'),
          ),
        ],
      ),
    );
  }

  Widget _construirFormulario() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.directions_car,
              size: 70,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            const Text(
              'Dados do Veículo',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // MARCA
            if (_carregandoMarcas)
              const Center(
                child: CircularProgressIndicator(),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _marcaSelecionada,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Marca',
                  border: OutlineInputBorder(),
                ),
                items: _marcas.map((marca) {
                  return DropdownMenuItem<String>(
                    value: marca['valor'].toString(),
                    child: Text(
                      marca['nome'].toString(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (valor) {
                  setState(() {
                    _marcaSelecionada = valor;
                    _modeloSelecionado = null;
                    _modelos = [];
                    _erroModelos = null;
                  });

                  if (valor != null) {
                    _buscarModelos(valor);
                  }
                },
                validator: (valor) {
                  if (valor == null) {
                    return 'Selecione uma marca';
                  }
                  return null;
                },
              ),

            if (_erroMarcas != null) ...[
              const SizedBox(height: 8),
              Text(
                _erroMarcas!,
                style: const TextStyle(color: Colors.red),
              ),
              TextButton(
                onPressed: _buscarMarcas,
                child: const Text('Tentar novamente'),
              ),
            ],

            const SizedBox(height: 15),

            // MODELO
            if (_carregandoModelos)
              const Center(
                child: CircularProgressIndicator(),
              )
            else
              DropdownButtonFormField<String>(
                key: ValueKey(_marcaSelecionada),
                initialValue: _modeloSelecionado,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Modelo',
                  border: OutlineInputBorder(),
                ),
                items: _modelos.map((modelo) {
                  return DropdownMenuItem<String>(
                    value: modelo['valor'].toString(),
                    child: Text(
                      modelo['modelo'].toString(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: _marcaSelecionada == null ||
                        _erroModelos != null
                    ? null
                    : (valor) {
                        setState(() {
                          _modeloSelecionado = valor;
                        });
                      },
                validator: (valor) {
                  if (valor == null) {
                    return 'Selecione um modelo';
                  }
                  return null;
                },
              ),

            if (_erroModelos != null) ...[
              const SizedBox(height: 8),
              Text(
                _erroModelos!,
                style: const TextStyle(color: Colors.red),
              ),
              TextButton(
                onPressed: _marcaSelecionada == null
                    ? null
                    : () => _buscarModelos(_marcaSelecionada!),
                child: const Text('Tentar novamente'),
              ),
            ],

            const SizedBox(height: 15),

            // ANO
            TextFormField(
              controller: _anoController,
              decoration: const InputDecoration(
                labelText: 'Ano',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                final ano = int.tryParse(value?.trim() ?? '');

                if (ano == null ||
                    ano < 1886 ||
                    ano > DateTime.now().year + 1) {
                  return 'Informe um ano válido';
                }
                return null;
              },
            ),

            const SizedBox(height: 15),

            // CILINDRADA
            TextFormField(
              controller: _cilindradaController,
              decoration: const InputDecoration(
                labelText: 'Cilindrada (ex.: 1.0 ou 1600)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                final cilindrada = double.tryParse(
                  (value ?? '').trim().replaceAll(',', '.'),
                );

                if (cilindrada == null || cilindrada <= 0) {
                  return 'Informe uma cilindrada válida';
                }
                return null;
              },
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _salvando ||
                      _carregandoMarcas ||
                      _carregandoModelos ||
                      _erroMarcas != null ||
                      _erroModelos != null
                  ? null
                  : _cadastrarVeiculo,
              child: const Text('Cadastrar Veículo'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro do Veículo'),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erroInicial != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_erroInicial!),
                      TextButton(
                        onPressed: _carregarVeiculo,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: _veiculo == null
                      ? _construirFormulario()
                      : _construirVeiculo(),
                ),
    );
  }
}
