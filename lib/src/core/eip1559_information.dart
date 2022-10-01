import 'package:web3dart/src/core/amount.dart';

class EIP1559Information {
  EIP1559Information({
    required this.maxPriorityFeePerGas,
    required this.maxFeePerGas,
    required this.estimatedGas,
  });

  factory EIP1559Information.fromJson(Map<String, double> json) =>
      EIP1559Information(
        maxPriorityFeePerGas:
            EtherAmount.inWei(BigInt.from(json['maxPriorityFeePerGas']!)),
        maxFeePerGas: EtherAmount.inWei(BigInt.from(json['maxFeePerGas']!)),
        estimatedGas: BigInt.from(json['estimatedGas']!),
      );

  Map<String, double> toJson() => {
        'maxPriorityFeePerGas': maxPriorityFeePerGas.getInWei.toDouble(),
        'maxFeePerGas': maxFeePerGas.getInWei.toDouble(),
        'estimatedGas': estimatedGas.toDouble(),
      };

  final EtherAmount maxPriorityFeePerGas;
  final EtherAmount maxFeePerGas;
  final BigInt estimatedGas;
}
