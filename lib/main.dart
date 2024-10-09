// lib/main.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'thirdweb_bindings.dart';
import 'dart:js_util' as js_util;

void main() {
  runApp(NFTDeploymentApp());
}

class NFTDeploymentApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NFT Deployment',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: DeploymentHomePage(),
    );
  }
}

class DeploymentHomePage extends StatefulWidget {
  @override
  _DeploymentHomePageState createState() => _DeploymentHomePageState();
}

class _DeploymentHomePageState extends State<DeploymentHomePage> {
  String _selectedNetwork = 'sepolia';
  bool _isConnected = false;
  String _walletAddress = '';
  String _currentNetwork = '';
  bool _isDeploying = false;
  String _deployMessage = '';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _symbolController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize Thirdweb SDK when the app starts
    // Note: It's better to initialize after wallet connection
  }

  /// Connects the wallet using flutter_web3 and initializes Thirdweb SDK
  Future<void> connectWalletFunction() async {
    if (!Ethereum.isSupported) {
      Fluttertoast.showToast(msg: 'MetaMask is not available in your browser');
      return;
    }

    try {
      // Request account access
      final accounts = await ethereum!.requestAccount();
      if (accounts.isEmpty) {
        Fluttertoast.showToast(msg: 'No accounts found');
        return;
      }

      setState(() {
        _walletAddress = accounts.first;
        _isConnected = true;
        _currentNetwork =
            _selectedNetwork; // Assuming network switch was successful
      });

      Fluttertoast.showToast(msg: '✅ Wallet connected: $_walletAddress');
      print('Wallet connected: $_walletAddress on network: $_currentNetwork');

      // Initialize Thirdweb SDK after connecting the wallet
      bool initialized = await initializeThirdweb();
      if (initialized) {
        Fluttertoast.showToast(msg: '🔧 Thirdweb SDK Initialized');
      } else {
        Fluttertoast.showToast(msg: '❌ Failed to initialize Thirdweb SDK');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '❌ Failed to connect wallet: $e');
      print('Exception during wallet connection: $e');
    }
  }

  /// Switches the Ethereum network
  Future<void> switchEthereumNetworkFunction() async {
    try {
      bool success = await switchNetwork(_selectedNetwork);
      if (success) {
        setState(() {
          _currentNetwork = _selectedNetwork;
        });
        Fluttertoast.showToast(msg: '🌐 Switched to $_selectedNetwork');
        print('Switched to network: $_selectedNetwork');

        // Re-initialize Thirdweb SDK after network switch
        bool initialized = await initializeThirdweb();
        if (initialized) {
          Fluttertoast.showToast(msg: '🔧 Thirdweb SDK Re-Initialized');
        } else {
          Fluttertoast.showToast(msg: '❌ Failed to re-initialize Thirdweb SDK');
        }
      } else {
        Fluttertoast.showToast(msg: '❌ Failed to switch network');
        print('Network switch failed.');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '❌ Error: $e');
      print('Exception during network switch: $e');
    }
  }

  /// Deploys the NFT Collection using Thirdweb SDK

  Future<void> deployNFTFunction() async {
    String name = _nameController.text.trim();
    String symbol = _symbolController.text.trim();

    if (name.isEmpty || symbol.isEmpty) {
      Fluttertoast.showToast(msg: '❌ Please enter both name and symbol');
      return;
    }

    setState(() {
      _isDeploying = true;
      _deployMessage = '';
    });

    try {
      var response = await deployNFT(name, symbol, _selectedNetwork);

      // Extract properties using js_util.getProperty
      bool success = js_util.getProperty(response, 'success');
      if (success) {
        String contractAddress =
            js_util.getProperty(response, 'contractAddress');
        String etherscanLink = js_util.getProperty(response, 'etherscanLink');

        setState(() {
          _deployMessage =
              '🎉 Contract deployed to: $contractAddress\n🔗 View on Etherscan: $etherscanLink';
        });
        Fluttertoast.showToast(msg: '🎉 NFT Deployed Successfully');
        print('NFT deployed to: $contractAddress');
        print('Etherscan link: $etherscanLink');
      } else {
        String message = js_util.getProperty(response, 'message');
        setState(() {
          _deployMessage = '❌ Deployment Error: $message';
        });
        Fluttertoast.showToast(msg: '❌ Deployment Failed');
        print('Deployment failed: $message');
      }
    } catch (e) {
      setState(() {
        _deployMessage = '❌ An error occurred: $e';
      });
      Fluttertoast.showToast(msg: '❌ Deployment Failed');
      print('Exception during NFT deployment: $e');
    } finally {
      setState(() {
        _isDeploying = false;
      });
    }
  }

  /// Disconnects the wallet
  Future<void> disconnectWalletFunction() async {
    // MetaMask does not support programmatic disconnection
    setState(() {
      _walletAddress = '';
      _isConnected = false;
      _currentNetwork = '';
      _deployMessage = '';
    });
    Fluttertoast.showToast(msg: '🔌 Wallet disconnected');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Deploy NFT'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instructions
              Text(
                'Please select the network, connect your wallet, and deploy your NFT.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),

              // Network Selection Dropdown
              Text(
                'Select Network:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: _selectedNetwork,
                isExpanded: true,
                items: <String>['sepolia', 'mainnet'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value[0].toUpperCase() + value.substring(1)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedNetwork = newValue!;
                  });
                  print('Selected network changed to: $_selectedNetwork');
                },
              ),
              SizedBox(height: 20),

              // Connect/Disconnect Wallet Button
              ElevatedButton(
                onPressed: _isConnected
                    ? () async {
                        await disconnectWalletFunction();
                      }
                    : () async {
                        await switchEthereumNetworkFunction();
                        await connectWalletFunction();
                      },
                child:
                    Text(_isConnected ? 'Disconnect Wallet' : 'Connect Wallet'),
              ),
              SizedBox(height: 20),

              // Display Wallet Address and Network
              if (_isConnected)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connected Wallet:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(_walletAddress),
                    SizedBox(height: 10),
                    Text(
                      'Network:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(_currentNetwork),
                  ],
                ),

              SizedBox(height: 20),

              // Deploy Form
              if (_isConnected) ...[
                Text(
                  'Deploy NFT Collection:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Token Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _symbolController,
                  decoration: InputDecoration(
                    labelText: 'Token Symbol',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isDeploying
                        ? null
                        : () async {
                            await deployNFTFunction();
                          },
                    child: _isDeploying
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text('Deploy'),
                  ),
                ),
                SizedBox(height: 20),
                if (_deployMessage.isNotEmpty)
                  Text(
                    _deployMessage,
                    style: TextStyle(
                      color: _deployMessage.startsWith('🎉')
                          ? Colors.green
                          : Colors.red,
                      fontSize: 16,
                    ),
                  ),
              ],
            ],
          )),
        ));
  }
}
