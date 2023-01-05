import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';
import 'package:test/test.dart';
import 'package:web3dart/json_rpc_multiquery.dart';

final uri = Uri.parse('url');

void main() {
  late MockClient client;

  setUp(() {
    client = MockClient();
  });

  test('encodes and sends requests', () async {
    final queries = [
      RPCQuery('eth_gasPrice'),
      RPCQuery(
        'eth_getBalance',
        ['0x95222290dd7278aa32dd189cc1e1d165cc4bafe5'],
      )
    ];
    await JsonRPCMultiQuery('url', client).callMultiQuery(queries);

    final request = client.request!;
    expect(
      request.headers,
      containsPair('Content-Type', startsWith('application/json')),
    );
  });

  test('increments request id', () async {
    final rpc = JsonRPCMultiQuery('url', client);
    final queries = [
      RPCQuery('eth_gasPrice'),
      RPCQuery(
        'eth_getBalance',
        ['0x95222290dd7278aa32dd189cc1e1d165cc4bafe5'],
      )
    ];
    await rpc.callMultiQuery(queries);

    final lastRequest = client.request!;
    expect(
      lastRequest.finalize().bytesToString(),
      completion(contains('"id":2')),
    );
  });

  test('throws errors', () {
    final rpc = JsonRPCMultiQuery('url', client);
    client.nextResponse = StreamedResponse(
      Stream.value(
        utf8.encode(
          '['
          '{"id": 1, "jsonrpc": "2.0", '
          '"error": {"code": 1, "message": "Message", "data": "data"}}, '
          '{"id": 2, "jsonrpc": "2.0", '
          '"error": {"code": 1, "message": "Message", "data": "data"}}'
          ']',
        ),
      ),
      200,
    );

    expect(
      rpc.callMultiQuery(
        [RPCQuery('eth_gasPrice')],
      ),
      throwsException,
    );
  });
}

class MockClient extends BaseClient {
  StreamedResponse? nextResponse;
  BaseRequest? request;

  @override
  Future<StreamedResponse> send(BaseRequest request) {
    this.request = request;
    return Future.value(
      nextResponse ??
          StreamedResponse(
            Stream.value(
              utf8.encode(
                '[{"id": 1, "jsonrpc": "2.0", "result": "0x1"},'
                '{"id": 2, "jsonrpc": "2.0", "result": "0x1"}]',
              ),
            ),
            200,
          ),
    );
  }
}
