import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/abastecimento.dart';

import '../models/veiculo.dart';

class BancoService {
  static Database? _banco;

  static Future<Database> get banco async {
    if (_banco != null) {
      return _banco!;
    }

    final pasta = await getDatabasesPath();
    final caminho = p.join(pasta, 'combustivel.db');

    _banco = await openDatabase(
      caminho,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE veiculos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            marca TEXT NOT NULL,
            modelo TEXT NOT NULL,
            ano INTEGER NOT NULL,
            cilindrada TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE abastecimentos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            veiculo_id INTEGER NOT NULL,
            combustivel TEXT NOT NULL,
            preco_litro REAL NOT NULL,
            quilometragem REAL NOT NULL,
            litros REAL NOT NULL,
            data_hora TEXT NOT NULL,
            FOREIGN KEY (veiculo_id)
              REFERENCES veiculos(id)
              ON DELETE CASCADE
          )
        ''');
      },
    );

    return _banco!;
  }

  // Recupera o veículo cadastrado
  static Future<Veiculo?> buscarVeiculo() async {
    final db = await banco;

    final resultado = await db.query(
      'veiculos',
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    return Veiculo.fromMap(resultado.first);
  }

  // Cadastra apenas se não existir outro veículo
  static Future<void> salvarVeiculo(Veiculo veiculo) async {
    final db = await banco;

    await db.transaction((txn) async {
      final resultado = await txn.query(
        'veiculos',
        limit: 1,
      );

      if (resultado.isNotEmpty) {
        throw Exception('Já existe um veículo cadastrado.');
      }

      await txn.insert(
        'veiculos',
        veiculo.toMap(),
      );
    });
  }

  // Exclui o veículo e seus abastecimentos
  static Future<void> excluirVeiculo(int id) async {
    final db = await banco;

    await db.delete(
      'veiculos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  // Salva um novo abastecimento
  static Future<void> salvarAbastecimento(
    Abastecimento abastecimento,
  ) async {
    final db = await banco;

    await db.insert(
      'abastecimentos',
      abastecimento.toMap(),
    );
  }

  // Recupera os abastecimentos de um veículo
  static Future<List<Abastecimento>> buscarAbastecimentos(
    int veiculoId,
  ) async {
    final db = await banco;

    final resultado = await db.query(
      'abastecimentos',
      where: 'veiculo_id = ?',
      whereArgs: [veiculoId],
      orderBy: 'data_hora ASC, id ASC',
    );

    return resultado
        .map((item) => Abastecimento.fromMap(item))
        .toList();
  }


}
