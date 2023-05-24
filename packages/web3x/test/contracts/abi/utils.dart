import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:web3x/contracts.dart';
import 'package:web3x/crypto.dart';

import 'package:web3x/web3x.dart' show LengthTrackingByteSink;


void expectEncodes<T>(AbiType<T> type, T data, String encoded) {
  final buffer = LengthTrackingByteSink();
  type.encode(data, buffer);

  expect(bytesToHex(buffer.asBytes()), encoded);
}

ByteBuffer bufferFromHex(String hex) {
  return hexToBytes(hex).buffer;
}
