import 'package:flutter/material.dart';
import 'dart:js' as js; // Import js for JS interaction.
import 'package:js/js_util.dart'
    as js_util; // Import js_util to handle JS calls and promises.

class DeployNFTPage extends StatefulWidget {
  @override
  _DeployNFTPageState createState() => _DeployNFTPageState();
}

class _DeployNFTPageState extends State<DeployNFTPage> {
  String? _walletAddress;
  String? _nftAddress;

  // Function to connect to the wallet
  Future<void> connectWallet() async {
    try {
      // Use js_util.promiseToFuture to convert JS promise to a Dart Future.
      final walletAddress = await js_util.promiseToFuture<String>(
          js_util.callMethod(js.context, 'connectMetamask', []));
      setState(() {
        _walletAddress = walletAddress;
      });
    } catch (e) {
      print("Error connecting wallet: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect wallet')),
      );
    }
  }

  // Function to deploy the NFT
  Future<void> deployNFT() async {
    if (_walletAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please connect your wallet first')),
      );
      return;
    }

    try {
      final nftAddress = await js_util.promiseToFuture<String>(
          js_util.callMethod(js.context, 'deployNFT', ['MyToken', 'MTK']));
      setState(() {
        _nftAddress = nftAddress;
      });
    } catch (e) {
      print("Error deploying NFT: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to deploy NFT')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Deploy NFT')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: connectWallet,
              child: Text(_walletAddress == null
                  ? 'Connect Wallet'
                  : 'Wallet Connected: $_walletAddress'),
            ),
            ElevatedButton(
              onPressed: deployNFT,
              child: Text('Deploy NFT'),
            ),
            if (_nftAddress != null) Text('NFT Deployed at: $_nftAddress'),
          ],
        ),
      ),
    );
  }
}
