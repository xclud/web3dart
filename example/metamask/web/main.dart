import 'dart:convert';
import 'dart:html';
import 'dart:typed_data';

import 'package:web3dart/browser.dart';
import 'package:web3dart/web3dart.dart';

Future<void> main() async {
  //metamask();
  binanceChainWallet();
}

Future<void> metamask() async {
  final eth = window.ethereum;
  if (eth == null) {
    print('MetaMask is not available');
    return;
  }

  final client = Web3Client.custom(eth.asRpcService());
  final credentials = await eth.requestAccount();

  print('Using ${credentials.address}');
  print('Client is listening: ${await client.isListeningForNetwork()}');

  final message = Uint8List.fromList(utf8.encode('Hello from web3dart'));
  final signature = await credentials.signPersonalMessage(message);
  print('Signature: ${base64.encode(signature)}');
}

Future<void> binanceChainWallet() async {
  final bsc = window.BinanceChain;
  if (bsc == null) {
    print('BinanceWallet is not available');
    return;
  }

  final client = Web3Client.custom(bsc.asRpcService());
  final credentials = await bsc.requestAccount();

  print('Using ${credentials.address}');
  print('Client is listening: ${await client.isListeningForNetwork()}');

  final message = Uint8List.fromList(utf8.encode('Hello from web3dart'));
  final signature = await credentials.signPersonalMessage(message);
  print('Signature: ${base64.encode(signature)}');
}
