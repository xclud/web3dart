part of 'eth_rpc_query.dart';

/// Set of useful factories to easily instantiate an EthPRCQuery
extension Factories on EthRPCQuery {
  /// Returns balance in Ether wei units of the address. (hex)
  static EthRPCQuery getBalance({
    required EthereumAddress address,
    BlockNum atBlock = const BlockNum.current(),
    String? id,
  }) =>
      EthRPCQuery<BigInt, String>._(
        function: 'eth_getBalance',
        params: [
          address.hex,
          atBlock.toBlockParam(),
        ],
        id: id,
        decodeFn: (r) => hexToInt(r),
      );

  /// Returns the amount of Ether in wei typically needed to pay for
  /// one unit of gas. (hex)
  static EthRPCQuery getGasPrice(String? id) =>
      EthRPCQuery<EtherAmount, String>._(
        function: 'eth_gasPrice',
        id: id,
        decodeFn: (r) => EtherAmount.fromHex(r),
      );

  static EthRPCQuery estimateGas(
    String? id,
  ) =>
      EthRPCQuery<EtherAmount, String>._(
        function: 'eth_estimateGas',
        id: id,
        decodeFn: (r) => EtherAmount.fromHex(r),
      );

  /// Returns the result of calling a contract as a List of returned results
  static EthRPCQuery callContract({
    required EthContractCallParams contractCallParams,
    BlockNum block = const BlockNum.current(),
    String? id,
  }) =>
      EthRPCQuery<List<dynamic>, String>._(
        function: 'eth_call',
        params: [
          {
            'to': contractCallParams.contract.address.hex,
            'data': bytesToHex(
              contractCallParams.function.encodeCall(
                contractCallParams.params,
              ),
              include0x: true,
              padToEvenLength: true,
            ),
            if (contractCallParams.sender != null)
              'from': contractCallParams.sender!.hex,
          },
          block,
        ],
        id: id,
        decodeFn: (r) {
          return contractCallParams.function.decodeReturnValues(r);
        },
      );

  /// Returns metadata of a certain block. [returnTransactionObjects]
  /// parameter defines if txs details should be returned in this call,
  /// or only the tx hashes. (map)
  static EthRPCQuery getBlockInformation({
    required BlockNum block,
    bool returnTransactionObjects = false,
    String? id,
  }) =>
      EthRPCQuery<BlockInformation, Map<String, dynamic>>._(
        function: 'eth_getBlockByNumber',
        params: [
          block.toBlockParam(),
          returnTransactionObjects,
        ],
        id: id,
        decodeFn: (r) => BlockInformation.fromJson(r),
      );

  static EthRPCQuery getTransactionCount({
    required EthereumAddress address,
    BlockNum blockNum = const BlockNum.current(),
    String? id,
  }) =>
      EthRPCQuery<int, String>._(
        function: 'eth_getTransactionCount',
        id: id,
        decodeFn: (r) => hexToDartInt(r),
      );

  static EthRPCQuery sendRawTransaction(
    Uint8List signedTransaction,
    String? id,
  ) =>
      EthRPCQuery<String, String>._(
        function: 'eth_sendRawTransaction',
        params: [
          bytesToHex(
            signedTransaction,
            include0x: true,
            padToEvenLength: true,
          )
        ],
        id: id,
        decodeFn: (r) => r,
      );

  /// Returns the information of a transaction
  static EthRPCQuery getTransactionByHash(
    String hash,
    String? id,
  ) =>
      EthRPCQuery<TransactionInformation?, Map<String, dynamic>?>._(
        function: 'eth_getTransactionByHash',
        params: [hash],
        id: id,
        decodeFn: (r) => r != null ? TransactionInformation.fromMap(r) : null,
      );

  /// Returns a receipt of a transaction
  static EthRPCQuery getTransactionReceipt(
    String hash,
    String? id,
  ) =>
      EthRPCQuery<TransactionReceipt?, Map<String, dynamic>?>._(
        function: 'eth_getTransactionReceipt',
        params: [hash],
        id: id,
        decodeFn: (r) => r != null ? TransactionReceipt.fromMap(r) : null,
      );

  // Returns version of the client (String)
  static EthRPCQuery getClientVersion(String? id) =>
      EthRPCQuery<String, String>._(
        function: 'web3_clientVersion',
        id: id,
        decodeFn: (r) => r,
      );

  /// Returns network id (int)
  static EthRPCQuery getNetworkId(String? id) => EthRPCQuery<int, String>._(
        function: 'net_version',
        id: id,
        decodeFn: (r) => int.parse(r),
      );

  /// Returns chain id (hex)
  /// https://chainid.network/chains.json
  static EthRPCQuery getChainId(String? id) => EthRPCQuery<BigInt, String>._(
        function: 'eth_chainId',
        id: id,
        decodeFn: (r) => hexToInt(r),
      );

  /// Returns the version of the Ethereum-protocol (hex)
  static EthRPCQuery getEthProtocolVersion(String? id) =>
      EthRPCQuery<int, String>._(
        function: 'eth_protocolVersion',
        id: id,
        decodeFn: (r) => hexToDartInt(r),
      );

  /// Returns the coinbase address (hex)
  static EthRPCQuery coinbaseAddress(String? id) =>
      EthRPCQuery<EthereumAddress, String>._(
        function: 'eth_coinbase',
        id: id,
        decodeFn: (r) => EthereumAddress.fromHex(r),
      );

  /// Returns if the client is currently mining (bool)
  static EthRPCQuery isMining(String? id) => EthRPCQuery<bool, bool>._(
        function: 'eth_mining',
        id: id,
        decodeFn: (r) => r,
      );

  /// Returns the amount of hashes per second the connected node is
  /// mining with. (int)
  static EthRPCQuery getMiningHashrate(String? id) =>
      EthRPCQuery<int, String>._(
        function: 'eth_hashrate',
        id: id,
        decodeFn: (r) => hexToDartInt(r),
      );

  /// Returns the number of the most recent mined block on the chain.
  /// (int)
  static EthRPCQuery getBlockNumber(String? id) => EthRPCQuery<int, String>._(
        function: 'eth_blockNumber',
        id: id,
        decodeFn: (r) => hexToDartInt(r),
      );

  /// Return the code at a specific address (hex)
  static EthRPCQuery getCode({
    required EthereumAddress address,
    BlockNum block = const BlockNum.current(),
    String? id,
  }) =>
      EthRPCQuery<Uint8List, String>._(
        function: 'eth_getCode',
        params: [
          address.hex,
          block.toBlockParam(),
        ],
        id: id,
        decodeFn: (r) => hexToBytes(r),
      );
}

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
