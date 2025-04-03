part of web3dart;

/// D stands for decoded result
/// R stands for raw result
/// The idea is to maintain a stable typing when expecting raw results
/// and when using functions to parsing them.
/// Sadly Dart is not flexible with generic constructors nor factories,
/// so all "factories" are static methods (view factories.dart file)
typedef DecodableFunction<D, R> = D Function(R);

class EthQueryResult<T> {
  EthQueryResult(this.result, this.id);

  final T result;
  final int id;

  @override
  String toString() {
    return '{"id": $id , "result": $result}';
  }
}

class EthRPCQuery<D, R> extends RPCQuery {
  EthRPCQuery._({
    required String function,
    List<dynamic> params = const [],
    int? id,
    required DecodableFunction<D, R> decodeFn,
  })  : _decodeFunction = decodeFn,
        super(function, params, id);

  final DecodableFunction<D, R> _decodeFunction;

  EthQueryResult decodeResult(R rawResult) =>
      EthQueryResult(_decodeFunction(rawResult), id!);

  EthRPCQuery copyWithId(
    int id,
  ) =>
      EthRPCQuery<D, R>._(
        id: id,
        function: function,
        params: this.params ?? [],
        decodeFn: _decodeFunction,
      );

  /// Returns balance in Ether wei units of the address. (hex)
  static EthRPCQuery getBalance({
    required EthereumAddress address,
    BlockNum atBlock = const BlockNum.current(),
    int? id,
  }) =>
      EthRPCQuery<BigInt, String>._(
        function: 'eth_getBalance',
        params: [
          address.with0x,
          atBlock.toBlockParam(),
        ],
        id: id,
        decodeFn: (r) => hexToInt(r),
      );

  /// Returns the amount of Ether in wei typically needed to pay for
  /// one unit of gas. (hex)
  static EthRPCQuery getGasPrice(int? id) => EthRPCQuery<EtherAmount, String>._(
        function: 'eth_gasPrice',
        id: id,
        decodeFn: (r) => EtherAmount.fromHex(r),
      );

  static EthRPCQuery estimateGas(
    int? id,
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
    int? id,
  }) =>
      EthRPCQuery<List<dynamic>, String>._(
        function: 'eth_call',
        params: [
          {
            'to': contractCallParams.contract.address.with0x,
            'data': bytesToHex(
              contractCallParams.function.encodeCall(
                contractCallParams.params,
              ),
              include0x: true,
              padToEvenLength: true,
            ),
            if (contractCallParams.sender != null)
              'from': contractCallParams.sender!.with0x,
          },
          block.toBlockParam(),
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
    int? id,
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
    int? id,
  }) =>
      EthRPCQuery<int, String>._(
        function: 'eth_getTransactionCount',
        id: id,
        decodeFn: (r) => hexToDartInt(r),
      );

  static EthRPCQuery sendRawTransaction(
    Uint8List signedTransaction,
    int? id,
  ) =>
      EthRPCQuery<String, String>._(
        function: 'eth_sendRawTransaction',
        params: [
          bytesToHex(
            signedTransaction,
            include0x: true,
            padToEvenLength: true,
          ),
        ],
        id: id,
        decodeFn: (r) => r,
      );

  /// Returns the information of a transaction
  static EthRPCQuery getTransactionByHash(
    String hash,
    int? id,
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
    int? id,
  ) =>
      EthRPCQuery<TransactionReceipt?, Map<String, dynamic>?>._(
        function: 'eth_getTransactionReceipt',
        params: [hash],
        id: id,
        decodeFn: (r) => r != null ? TransactionReceipt.fromMap(r) : null,
      );

  // Returns version of the client (String)
  static EthRPCQuery getClientVersion(int? id) => EthRPCQuery<String, String>._(
        function: 'web3_clientVersion',
        id: id,
        decodeFn: (r) => r,
      );

  /// Returns network id (int)
  static EthRPCQuery getNetworkId(int? id) => EthRPCQuery<int, String>._(
        function: 'net_version',
        id: id,
        decodeFn: (r) => int.parse(r),
      );

  /// Returns chain id (hex)
  /// https://chainid.network/chains.json
  static EthRPCQuery getChainId(int? id) => EthRPCQuery<BigInt, String>._(
        function: 'eth_chainId',
        id: id,
        decodeFn: (r) => hexToInt(r),
      );

  /// Returns the version of the Ethereum-protocol (hex)
  static EthRPCQuery getEthProtocolVersion(int? id) =>
      EthRPCQuery<int, String>._(
        function: 'eth_protocolVersion',
        id: id,
        decodeFn: (r) => hexToDartInt(r),
      );

  /// Returns the coinbase address (hex)
  static EthRPCQuery coinbaseAddress(int? id) =>
      EthRPCQuery<EthereumAddress, String>._(
        function: 'eth_coinbase',
        id: id,
        decodeFn: (r) => EthereumAddress.fromHex(r),
      );

  /// Returns if the client is currently mining (bool)
  static EthRPCQuery isMining(int? id) => EthRPCQuery<bool, bool>._(
        function: 'eth_mining',
        id: id,
        decodeFn: (r) => r,
      );

  /// Returns the amount of hashes per second the connected node is
  /// mining with. (int)
  static EthRPCQuery getMiningHashrate(int? id) => EthRPCQuery<int, String>._(
        function: 'eth_hashrate',
        id: id,
        decodeFn: (r) => hexToDartInt(r),
      );

  /// Returns the number of the most recent mined block on the chain.
  /// (int)
  static EthRPCQuery getBlockNumber(int? id) => EthRPCQuery<int, String>._(
        function: 'eth_blockNumber',
        id: id,
        decodeFn: (r) => hexToDartInt(r),
      );

  /// Return the code at a specific address (hex)
  static EthRPCQuery getCode({
    required EthereumAddress address,
    BlockNum block = const BlockNum.current(),
    int? id,
  }) =>
      EthRPCQuery<Uint8List, String>._(
        function: 'eth_getCode',
        params: [
          address.with0x,
          block.toBlockParam(),
        ],
        id: id,
        decodeFn: (r) => hexToBytes(r),
      );
}
