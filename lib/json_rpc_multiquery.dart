import 'dart:convert';

import 'package:http/http.dart';

import 'json_rpc.dart';

class JsonRPCMultiQuery extends JsonRPC {
  JsonRPCMultiQuery(String url, Client client) : super(url, client);

  int _currentRequestId = 1;

  Future<List<RPCResponse>> callMultiQuery(List<RPCQuery> queries) async {
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

    final responses = <RPCResponse>[];

    final dataList = json.decode(response.body) as List<dynamic>;
    final castedList = dataList.cast<Map<String, dynamic>>();

    for (final data in castedList) {
      if (data.containsKey('error')) {
        final error = data['error'];

        final code = error['code'] as int;
        final message = error['message'] as String;
        final errorData = error['data'];

        throw RPCError(code, message, errorData);
      }

      final id = data['id'] as int;
      final result = data['result'];
      responses.add(RPCResponse(id, result));
    }
    return responses;
  }
}

class RPCQuery {
  RPCQuery(this.function, [this.params]);

  final String function;
  final List<dynamic>? params;
}
