part of 'package:web3dart/web3dart.dart';

class BlockInformation {
  BlockInformation({
    required this.baseFeePerGas,
    required this.timestamp,
  });

  factory BlockInformation.fromJson(Map<String, dynamic> json) {
    return BlockInformation(
      baseFeePerGas: json.containsKey('baseFeePerGas')
          ? EtherAmount.fromBigInt(
              EtherUnit.wei,
              hexToInt(json['baseFeePerGas'] as String),
            )
          : null,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        hexToDartInt(json['timestamp'] as String) * 1000,
        isUtc: true,
      ),
    );
  }

  final EtherAmount? baseFeePerGas;
  final DateTime timestamp;
  bool get isSupportEIP1559 => baseFeePerGas != null;
}
