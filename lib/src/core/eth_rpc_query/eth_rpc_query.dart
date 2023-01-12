// ignore_for_file: sort_constructors_first

import 'dart:typed_data';

import 'package:web3dart/web3dart.dart';

import '../../../crypto.dart';
import '../../../json_rpc_multiquery.dart';

part 'factories.dart';

/// D stands for decoded result
/// R stands for raw result
/// The idea is to maintain a stable typing when expecting raw results
/// and when using functions to parsing them.
/// Sadly Dart is not flexible with generic constructors nor factories,
/// so all "factories" are static methods (view factories.dart file)
typedef DecodableFunction<D, R> = D Function(R);

class EthRPCQuery<D, R> extends RPCQuery {
  final DecodableFunction<D, R> _decodeFunction;

  EthRPCQuery._({
    required String function,
    List<dynamic> params = const [],
    String? id,
    required DecodableFunction<D, R> decodeFn,
  })  : _decodeFunction = decodeFn,
        super(function, params, id);

  EthQueryResult decodeResult(R rawResult) =>
      EthQueryResult(_decodeFunction(rawResult), id!);

  EthRPCQuery copyWithId(
    String id,
  ) =>
      EthRPCQuery<D, R>._(
        id: id,
        function: function,
        params: params ?? [],
        decodeFn: _decodeFunction,
      );
}

class EthQueryResult<T> {
  EthQueryResult(this.result, this.id);

  final T result;
  final String id;
}
