import 'package:web3dart/src/crypto/formatting.dart';
import 'package:web3dart/web3dart.dart';

class BlockInformation {
  final int? number;
  final EtherAmount? baseFeePerGas;
  final DateTime timestamp;

  BlockInformation({
    required this.number,
    required this.baseFeePerGas,
    required this.timestamp,
  });

  factory BlockInformation.fromJson(Map<String, dynamic> json) {
    return BlockInformation(
      number: _parseNumber(json),
      baseFeePerGas: _parseBaseFeePerGas(json),
      timestamp: _parseTimestamp(json),
    );
  }

  bool get isSupportEIP1559 => baseFeePerGas != null;
}

class BlockInformationWithTransactions extends BlockInformation {
  final List<TransactionInformation> transactions;

  BlockInformationWithTransactions({
    required int? number,
    required EtherAmount? baseFeePerGas,
    required DateTime timestamp,
    required this.transactions,
  }) : super(
    number: number,
    baseFeePerGas: baseFeePerGas,
    timestamp: timestamp,
  );

  factory BlockInformationWithTransactions.fromMap(Map<String, dynamic> map) {
    return BlockInformationWithTransactions(
      number: _parseNumber(map),
      baseFeePerGas: _parseBaseFeePerGas(map),
      timestamp: _parseTimestamp(map),
      transactions: _parseTransactions(map),
    );
  }

  static List<TransactionInformation> _parseTransactions(Map<String, dynamic> map) {
    return (map['transactions'] as List)
        .cast<Map<String, dynamic>>()
        .map((map) => TransactionInformation.fromMap(map))
        .toList(growable: false);
  }
}

int? _parseNumber(Map<String, dynamic> map) {
  if (!map.containsKey('number')) return null;
  return hexToDartInt(map['number'] as String);
}

EtherAmount? _parseBaseFeePerGas(Map<String, dynamic> map) {
  if (!map.containsKey('baseFeePerGas')) return null;

  return EtherAmount.fromUnitAndValue(
    EtherUnit.wei,
    hexToInt(map['baseFeePerGas'] as String),
  );
}

DateTime _parseTimestamp(Map<String, dynamic> map) {
  return DateTime.fromMillisecondsSinceEpoch(
    hexToDartInt(map['timestamp'] as String) * 1000,
    isUtc: true,
  );
}
