library json_rpc;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

// ignore: one_member_abstracts

/// RPC Service base class.
abstract class RpcService {
  /// Constructor.
  RpcService(this.url);

  /// Url.
  final String url;

  /// Performs an RPC request, asking the server to execute the function with
  /// the given name and the associated parameters, which need to be encodable
  /// with the [json] class of dart:convert.
  ///
  /// When the request is successful, an [RPCResponse] with the request id and
  /// the data from the server will be returned. If not, an RPCError will be
  /// thrown. Other errors might be thrown if an IO-Error occurs.
  Future<RPCResponse> call(String function, [List<dynamic>? params]);
}

/// Json RPC Service.
class JsonRPC extends RpcService {
  /// Constructor.
  JsonRPC(String url, this.client) : super(url);

  /// Http client.
  final Client client;

  int _currentRequestId = 1;

  /// Performs an RPC request, asking the server to execute the function with
  /// the given name and the associated parameters, which need to be encodable
  /// with the [json] class of dart:convert.
  ///
  /// When the request is successful, an [RPCResponse] with the request id and
  /// the data from the server will be returned. If not, an RPCError will be
  /// thrown. Other errors might be thrown if an IO-Error occurs.
  @override
  Future<RPCResponse> call(String function, [List<dynamic>? params]) async {
    params ??= [];

    final callId = _currentRequestId++;
    final requestPayload = {
      'jsonrpc': '2.0',
      'method': function,
      'params': params,
      'id': callId,
    };

    Web3Client.printLog?.call(
      '->\nid: $callId\nmethod: $function\nparams: $params\nrpc: $url',
    );
    final response = await client.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestPayload),
    );

    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data.containsKey('error')) {
      final error = data['error'];

      final code = error['code'] as int;
      final message = error['message'] as String;
      final errorData = error['data'];
      Web3Client.printLog?.call(
        '<-\nid: $callId\nmethod: $function\nerror: $error',
        error: true,
      );
      throw RPCError(code, message, errorData);
    }

    final id = data['id'] as int;
    final result = data['result'];
    Web3Client.printLog?.call(
      '<-\nid: $callId\nmethod: $function\nresult: $result',
    );
    return RPCResponse(id, result);
  }
}

/// Response from the server to an rpc request. Contains the id of the request
/// and the corresponding result as sent by the server.
class RPCResponse {
  /// Constructor.
  const RPCResponse(this.id, this.result);

  /// Id.
  final int id;

  /// Result.
  final dynamic result;
}

/// Exception thrown when an the server returns an error code to an rpc request.
class RPCError implements Exception {
  /// Constructor.
  const RPCError(this.errorCode, this.message, this.data);

  /// Error code.
  final int errorCode;

  /// Message.
  final String message;

  /// Data.
  final dynamic data;

  @override
  String toString() {
    return 'RPCError: got code $errorCode with msg "$message".';
  }
}
