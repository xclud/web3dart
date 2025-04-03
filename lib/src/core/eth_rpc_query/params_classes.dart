part of '../../../web3dart.dart';

class EthContractCallParams {
  EthContractCallParams({
    this.sender,
    required this.contract,
    required this.function,
    required this.params,
    this.atBlock = const BlockNum.current(),
    this.rpcId,
  });

  final EthereumAddress? sender;
  final DeployedContract contract;
  final ContractFunction function;
  final List<dynamic> params;
  final BlockNum? atBlock;
  final String? rpcId;
}

class EthEstimateGasParams {
  EthEstimateGasParams({
    this.sender,
    this.to,
    this.value,
    this.amountOfGas,
    this.gasPrice,
    this.maxPriorityFeePerGas,
    this.maxFeePerGas,
    this.data,
    this.rpcId,
  });

  final EthereumAddress? sender;
  final EthereumAddress? to;
  final EtherAmount? value;
  final BigInt? amountOfGas;
  final EtherAmount? gasPrice;
  final EtherAmount? maxPriorityFeePerGas;
  final EtherAmount? maxFeePerGas;
  final Uint8List? data;
  final String? rpcId;
}
