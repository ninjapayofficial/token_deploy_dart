// lib/main.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:js/js.dart';
import 'thirdweb_bindings.dart';

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
    // No need to initialize SDK here as it will be handled in connectWallet
  }

  Future<void> connectWalletFunction() async {
    try {
      var response = await connectWallet();
      if (response.success) {
        setState(() {
          _isConnected = true;
          _walletAddress = response.account ?? '';
          _currentNetwork = _selectedNetwork; // Assuming network switch was successful
        });
        Fluttertoast.showToast(msg: '✅ Wallet connected');
        print('Wallet connected: $_walletAddress on network: $_currentNetwork');
      } else {
        Fluttertoast.showToast(msg: '❌ ${response.message}');
        print('Wallet connection failed: ${response.message}');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '❌ Error: $e');
      print('Exception during wallet connection: $e');
    }
  }

  Future<void> switchEthereumNetworkFunction() async {
    try {
      bool success = await switchNetwork(_selectedNetwork);
      if (success) {
        setState(() {
          _currentNetwork = _selectedNetwork;
        });
        Fluttertoast.showToast(msg: '🌐 Switched to $_selectedNetwork');
        print('Switched to network: $_selectedNetwork');
      } else {
        Fluttertoast.showToast(msg: '❌ Failed to switch network');
        print('Network switch failed.');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '❌ Error: $e');
      print('Exception during network switch: $e');
    }
  }

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
      if (response.success) {
        setState(() {
          _deployMessage =
              '🎉 Contract deployed to: ${response.contractAddress}\n🔗 View on Etherscan: ${response.etherscanLink}';
        });
        Fluttertoast.showToast(msg: '🎉 NFT Deployed Successfully');
        print('NFT deployed to: ${response.contractAddress}');
        print('Etherscan link: ${response.etherscanLink}');
      } else {
        setState(() {
          _deployMessage = '❌ Deployment Error: ${response.message}';
        });
        Fluttertoast.showToast(msg: '❌ Deployment Failed');
        print('Deployment failed: ${response.message}');
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

              // Connect Wallet Button
              ElevatedButton(
                onPressed: _isConnected
                    ? null
                    : () async {
                        await switchEthereumNetworkFunction();
                        await connectWalletFunction();
                      },
                child:
                    Text(_isConnected ? 'Wallet Connected' : 'Connect Wallet'),
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
                    onPressed: _isDeploying ? null : () async => await deployNFTFunction(),
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
