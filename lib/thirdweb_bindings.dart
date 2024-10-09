// // lib/thirdweb_bindings.dart

// @JS()
// library thirdweb_bindings;

// import 'package:js/js.dart';

// // Define the response structures from JavaScript

// @JS()
// @anonymous
// class WalletResponse {
//   external bool get success;
//   external String? get account;
//   external String? get network;
//   external String? get message;
// }

// @JS()
// @anonymous
// class DeployResponse {
//   external bool get success;
//   external String? get contractAddress;
//   external String? get etherscanLink;
//   external String? get message;
// }

// // Declare the JavaScript functions

// @JS('initializeSDK')
// external bool initializeSDK();

// @JS('switchNetwork')
// external Future<bool> switchNetwork(String network);

// @JS('connectWallet')
// external Future<WalletResponse> connectWallet();

// @JS('deployNFT')
// external Future<DeployResponse> deployNFT(
//     String name, String symbol, String network);

// lib/thirdweb_bindings.dart

// lib/thirdweb_bindings.dart

// lib/thirdweb_bindings.dart

import 'dart:js_util' as js_util;

/// Initializes the Thirdweb SDK by calling the JavaScript function.
/// Returns `true` if successful, `false` otherwise.
Future<bool> initializeThirdweb() async {
  return await js_util.promiseToFuture<bool>(
    js_util.callMethod(js_util.globalThis, 'initializeThirdweb', []),
  );
}

/// Switches the Ethereum network by calling the JavaScript function.
/// Returns `true` if successful, `false` otherwise.
Future<bool> switchNetwork(String network) async {
  return await js_util.promiseToFuture<bool>(
    js_util.callMethod(js_util.globalThis, 'switchNetwork', [network]),
  );
}

/// Deploys an NFT collection by calling the JavaScript function.
/// Returns a dynamic object containing deployment results.
Future<dynamic> deployNFT(String name, String symbol, String network) async {
  return await js_util.promiseToFuture<dynamic>(
    js_util
        .callMethod(js_util.globalThis, 'deployNFT', [name, symbol, network]),
  );
}
