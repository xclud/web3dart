library json_rpc_multiquery;

import 'dart:convert';

import 'package:http/http.dart';

import 'contracts.dart';
import 'credentials.dart';
import 'crypto.dart';
import 'json_rpc.dart';
import 'src/core/block_number.dart';

abstract class MultiQueryRpcService {
  /// Performs a single RPC request, asking the server to execute several queries
  /// using the functions with associated parameters for each one, the parameters
  /// need to be encodable with the [json] class of dart:convert.
  ///
  /// When the request is successful, a list is returned, containing each query
  /// response. This responses can be either an [RPCResponse] on success, or an
  /// [RPCError] on failure.
  /// No [RPCError] instances will be thrown, they will only be part of the list.
  /// Other errors might be thrown if an IO-Error occurs.
  Future<List<dynamic>> callMultiQuery(List<RPCQuery> queries);
}

class JsonRPCMultiQuery extends JsonRPC implements MultiQueryRpcService {
  JsonRPCMultiQuery(String url, Client client) : super(url, client);

  int _currentRequestId = 1;

  @override
  Future<List<dynamic>> callMultiQuery(List<RPCQuery> queries) async {
    final payloadList = <Map<String, dynamic>>[];
    for (final query in queries) {
      payloadList.add(
        {
          'jsonrpc': '2.0',
          'method': query.function,
          'params': query.params ?? [],
          'id': _currentRequestId++,
        },
      );
    }
    final response = await client.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payloadList),
    );

    // responses list will be RPCResponse and/or RPCError instances
    final responses = <dynamic>[];

    final dataList = json.decode(response.body) as List<dynamic>;
    final castedList = dataList.cast<Map<String, dynamic>>();

    for (final data in castedList) {
      if (data.containsKey('error')) {
        final id = data['id'] as int;
        final error = data['error'];

        final code = error['code'] as int;
        final message = error['message'] as String;
        final errorData = error['data'];

        responses.add(RPCError(code, message, errorData, id));
      }

      final id = data['id'] as int;
      final result = data['result'];
      responses.add(RPCResponse(id, result));
    }
    return responses;
  }
}

class RPCQuery {
  RPCQuery(this.function, [this.params, this.id]);

  final String function;
  final String? id;
  final List<dynamic>? params;
}

/// Useful class to
class EthContractCall {
  EthContractCall({
    this.sender,
    required this.contract,
    required this.function,
    required this.params,
    this.atBlock = const BlockNum.current(),
  });

  final EthereumAddress? sender;
  final DeployedContract contract;
  final ContractFunction function;
  final List<dynamic> params;
  final BlockNum? atBlock;

  RPCQuery toRPCQuery(String id) {
    final data = function.encodeCall(params);
    final rawParamsBody = {
      'to': contract.address.hex,
      'data': bytesToHex(data, include0x: true, padToEvenLength: true),
      if (sender != null) 'from': sender!.hex,
    };
    return RPCQuery(
      'eth_call',
      [
        rawParamsBody,
        atBlock,
      ],
      id,
    );
  }
}
