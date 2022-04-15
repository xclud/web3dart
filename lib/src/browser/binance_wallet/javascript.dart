@JS()
library web3dart.internal.js;

import 'dart:html';

import 'package:js/js.dart';
import 'package:meta/meta.dart';

import 'dart_wrappers.dart';

@JS('BinanceChain')
external BinanceChainWallet? get _binanceChain;

/// Extension to load obtain the `BinanceChain` window property injected by
/// BinanceChain browser plugins.
extension GetBinanceChain on Window {
  /// Loads the ethereum instance provided by the browser.
  ///
  /// For more information on how to use this object with the web3dart package,
  /// see the methods on [DartBinanceChain].
  BinanceChainWallet? get BinanceChain => _binanceChain;
}

@JS()
class BinanceChainWallet {
  external int get chainId;
  external bool autoRefreshOnNetworkChange;
  external bool isConnected();

  /// This should not be used in user code. Use `stream(event)` instead.
  @internal
  external void on(String event, Function callback);

  /// This should not be used in user code. Use `stream(event)` instead.
  @internal
  external void removeListener(String event, Function callback);

  /// This should not be used in user code. Use `requestRaw` instead.
  @internal
  external Object request(RequestArguments args);
}

@JS()
@anonymous
@internal
class RequestArguments {
  external String get method;
  external Object? get params;

  external factory RequestArguments({required String method, Object? params});
}
