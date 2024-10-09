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

@JS()
library thirdweb_bindings;

import 'package:js/js.dart';

@JS()
@anonymous
class WalletResponse {
  external bool get success;
  external String? get account;
  external int? get network;
  external String? get message;
}

@JS()
@anonymous
class DeployResponse {
  external bool get success;
  external String? get contractAddress;
  external String? get etherscanLink;
  external String? get message;
}

// Declare the JavaScript functions
@JS('initializeSDK')
external bool initializeSDK();

@JS('switchNetwork')
external Future<bool> switchNetwork(String network);

@JS('connectWallet')
external Future<WalletResponse> connectWallet();

@JS('deployNFT')
external Future<DeployResponse> deployNFT(
    String name, String symbol, String network);
