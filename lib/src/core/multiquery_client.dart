part of 'package:web3dart/web3dart.dart';

class MultiQueryWeb3Client extends Web3Client {
  MultiQueryWeb3Client(
    String url,
    Client httpClient, {
    SocketConnector? socketConnector,
  }) : super.custom(
          JsonRPCMultiQuery(url, httpClient),
          socketConnector: socketConnector,
        );

  Future<List<dynamic>> multiqueryCall(
    List<EthContractCall> contractCalls,
    List<RPCQuery> rawQuerys,
  ) async {
    // Each instance of contract call is mapped to an id (the index).
    // This is intended to later find out how to decode the returned values.
    final contractCallsMap = contractCalls.asMap();
    int lastId = contractCallsMap.length;

    final contractQueries = contractCallsMap.entries.map(
      (e) => e.value.toRPCQuery(
        e.key.toString(),
      ),
    );
    final rawQuerysWithId = rawQuerys.map(
      (q) => RPCQuery(q.function, q.params, q.id ?? (lastId++).toString()),
    );

    final responses = await (_jsonRpc as MultiQueryRpcService).callMultiQuery([
      ...contractQueries,
      ...rawQuerysWithId,
    ]);
    final decodedResponses = <dynamic>[];
    for (final res in responses) {
      // each response can be either an error or a correct value returned
      if (res is RPCResponse) {
        final function = contractCallsMap[res.id]!.function;
        final decodedResult = function.decodeReturnValues(res.result as String);
        decodedResponses.add(decodedResult);
      } else if (res is RPCError) {
        decodedResponses.add(res);
      }
    }

    return decodedResponses;
  }
}
