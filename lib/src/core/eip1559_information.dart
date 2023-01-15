import 'package:web3dart/src/core/amount.dart';

class EIP1559Information {
  EIP1559Information({
    required this.maxPriorityFeePerGas,
    required this.maxFeePerGas,
    required this.estimatedGas,
  });

  factory EIP1559Information.fromJson(Map<String, String> json) =>
      EIP1559Information(
        maxPriorityFeePerGas:
            EtherAmount.inWei(BigInt.parse(json['maxPriorityFeePerGas']!)),
        maxFeePerGas: EtherAmount.inWei(BigInt.parse(json['maxFeePerGas']!)),
        estimatedGas: BigInt.parse(json['estimatedGas']!),
      );

  Map<String, String> toJson() => {
        'maxPriorityFeePerGas': maxPriorityFeePerGas.getInWei.toString(),
        'maxFeePerGas': maxFeePerGas.getInWei.toString(),
        'estimatedGas': estimatedGas.toString(),
      };

  final EtherAmount maxPriorityFeePerGas;
  final EtherAmount maxFeePerGas;
  final BigInt estimatedGas;
}
