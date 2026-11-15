# Controle de Combustível

Aplicativo desenvolvido em Flutter e Dart para gerenciar veículos, registrar abastecimentos e acompanhar gastos e consumo de combustível.

## Funcionalidades

- Cadastro de veículo com marca, modelo, ano e cilindrada.
- Consulta de marcas e modelos utilizando a BrasilAPI.
- Cadastro de apenas um veículo por vez.
- Exclusão do veículo com confirmação.
- Registro e histórico de abastecimentos.
- Cálculo automático do valor total de cada abastecimento.
- Cálculo do consumo em km/L e custo em R$/km.
- Gráficos de evolução do consumo e dos custos.
- Armazenamento local utilizando SQLite.

## Tecnologias utilizadas

- Flutter e Dart
- BrasilAPI
- SQLite (`sqflite` e `path`)
- `http`
- `fl_chart`

## Como executar

**1.** Clone o repositório:

```bash
git clone URL_DO_REPOSITORIO
```

**2.** Entre na pasta do projeto:

```bash
cd controle_combustivel
```

**3.** Instale as dependências:

```bash
flutter pub get
```

**4.** Execute o aplicativo em um emulador ou dispositivo Android:

```bash
flutter run
```

## Cálculos utilizados

**Valor total:**

Valor total = Preço por litro × Litros abastecidos

**Consumo:**

Consumo (km/L) = Distância percorrida ÷ Litros do abastecimento atual

**Custo por quilômetro:**

Custo (R$/km) = Valor total do abastecimento atual ÷ Distância percorrida

O primeiro abastecimento é utilizado como referência inicial para os cálculos.

## Capturas de tela

As imagens das principais funcionalidades estão disponíveis na pasta `screenshots`:

- Tela inicial
- Cadastro do veículo
- Registro de abastecimentos
- Dashboard com gráficos

## Observações

- Os dados são armazenados localmente no dispositivo.
- É necessário acesso à internet para consultar marcas e modelos.
- A exclusão do veículo remove também seus abastecimentos associados.
