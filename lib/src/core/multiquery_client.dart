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

  /// Method used to make several contract calls and/or various rpc queries, using only
  /// one request to the eth client.
  /// The resulting list of responses will a mix of [RPCError] instance/s and/or
  /// [EthRPCQuery] instance/s with the returned value
  Future<List<dynamic>> multiqueryCall(
    List<EthRPCQuery> queries,
  ) async {
    // Each instance of contract call is mapped to an id (the index).
    // This is intended to later find out how to decode the returned values.

    late final allQueriesWithId = queries.every((c) => c.id != null);
    late final allQueriesWithNoId = queries.every((c) => c.id == null);
    // Queries should be passed: all with id or all without id
    if (!allQueriesWithId && !allQueriesWithNoId) {
      throw ArgumentError(
          'Some but not all querys have been provided with an RPC id.'
          'You must assign an id to each call or leave all calls without any assigned id');
    }

    final Map<int, EthRPCQuery> preparedQueries = {};
    int lastId = 0;
    for (var q in queries) {
      final id = q.id ?? lastId++;
      preparedQueries[id] = q.copyWithId(id);
    }

    final responses = await (_jsonRpc as MultiQueryRpcService)
        .callMultiQuery(preparedQueries.values.toList());
    if (responses.length != queries.length) {
      throw Error.throwWithStackTrace(
        'Eth node client did not respond correctly to all the queries',
        StackTrace.current,
      );
    }
    // The decoded responses will be either [RPCError] instance/s or
    // [EthRPCQuery] instance/s with the returned value
    final decodedResponses = <dynamic>[];
    for (final res in responses) {
      // each response can be either an error or a correct value returned
      if (res is RPCResponse) {
        final correspondingQuery = preparedQueries[res.id]!;
        final decodedResult = correspondingQuery.decodeResult(res.result);

        decodedResponses.add(decodedResult);
      } else if (res is RPCError) {
        decodedResponses.add(res);
      }
    }

    // sorting responses by querys order (not id order)
    final sortedResponsesList = [];

    for (var k = 0; k > preparedQueries.keys.length; k++) {
      final sameIdResponse = decodedResponses.firstWhere((dynamic r) {
        if (r is RPCError) {
          return r.id == preparedQueries[k]!.id;
        } else if (r is RPCResponse) {
          return r.id == preparedQueries[k]!.id;
        }
        return false;
      });
      sortedResponsesList[k] = sameIdResponse;
    }

    return decodedResponses;
  }
}
