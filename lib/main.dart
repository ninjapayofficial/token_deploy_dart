// lib/main.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_web3/flutter_web3.dart';
import 'dart:js_util' as js_util;
import 'thirdweb_bindings.dart';

void main() {
  runApp(NFTDeploymentApp());
}

class NFTDeploymentApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blockchain Deployment',
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
  bool _isDeployingNFT = false;
  bool _isDeployingERC20 = false;
  String _deployMessage = '';

  // Controllers for NFT
  final TextEditingController _nftNameController = TextEditingController();
  final TextEditingController _nftSymbolController = TextEditingController();

  // Controllers for ERC-20
  final TextEditingController _erc20NameController = TextEditingController();
  final TextEditingController _erc20SymbolController = TextEditingController();
  final TextEditingController _erc20InitialSupplyController =
      TextEditingController();
  final TextEditingController _erc20DecimalsController =
      TextEditingController(text: '18'); // Default to 18

  @override
  void initState() {
    super.initState();
    // Optionally, initialize Thirdweb SDK here if needed
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

  /// Deploys the NFT Collection
  Future<void> deployNFTFunction() async {
    String name = _nftNameController.text.trim();
    String symbol = _nftSymbolController.text.trim();

    if (name.isEmpty || symbol.isEmpty) {
      Fluttertoast.showToast(msg: '❌ Please enter both NFT name and symbol');
      return;
    }

    setState(() {
      _isDeployingNFT = true;
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
              '🎉 NFT Contract deployed to: $contractAddress\n🔗 View on Etherscan: $etherscanLink';
        });
        Fluttertoast.showToast(msg: '🎉 NFT Deployed Successfully');
        print('NFT deployed to: $contractAddress');
        print('Etherscan link: $etherscanLink');
      } else {
        String message = js_util.getProperty(response, 'message');
        setState(() {
          _deployMessage = '❌ NFT Deployment Error: $message';
        });
        Fluttertoast.showToast(msg: '❌ NFT Deployment Failed');
        print('NFT Deployment failed: $message');
      }
    } catch (e) {
      setState(() {
        _deployMessage = '❌ An error occurred during NFT deployment: $e';
      });
      Fluttertoast.showToast(msg: '❌ NFT Deployment Failed');
      print('Exception during NFT deployment: $e');
    } finally {
      setState(() {
        _isDeployingNFT = false;
      });
    }
  }

  /// Deploys the ERC-20 Token
  Future<void> deployERC20Function() async {
    String name = _erc20NameController.text.trim();
    String symbol = _erc20SymbolController.text.trim();
    String initialSupplyStr = _erc20InitialSupplyController.text.trim();
    String decimalsStr = _erc20DecimalsController.text.trim();

    if (name.isEmpty ||
        symbol.isEmpty ||
        initialSupplyStr.isEmpty ||
        decimalsStr.isEmpty) {
      Fluttertoast.showToast(msg: '❌ Please enter all ERC-20 token details');
      return;
    }

    // Validate initialSupply and decimals
    if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(initialSupplyStr)) {
      Fluttertoast.showToast(msg: '❌ Initial Supply must be a valid number');
      return;
    }

    int decimals;
    try {
      decimals = int.parse(decimalsStr);
      if (decimals < 0 || decimals > 18) {
        Fluttertoast.showToast(msg: '❌ Decimals must be between 0 and 18');
        return;
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '❌ Decimals must be a valid integer');
      return;
    }

    // Convert initialSupply to the smallest unit based on decimals
    // Assuming initialSupplyStr is in whole units
    double initialSupplyDouble = double.parse(initialSupplyStr);
    BigInt initialSupply = BigInt.from(
        initialSupplyDouble * (pow(10, decimals) as double).toInt());

    setState(() {
      _isDeployingERC20 = true;
      _deployMessage = '';
    });

    try {
      var response = await deployERC20(
          name, symbol, initialSupply.toString(), decimals, _selectedNetwork);

      // Extract properties using js_util.getProperty
      bool success = js_util.getProperty(response, 'success');
      if (success) {
        String contractAddress =
            js_util.getProperty(response, 'contractAddress');
        String etherscanLink = js_util.getProperty(response, 'etherscanLink');

        setState(() {
          _deployMessage +=
              '\n🎉 ERC-20 Token Contract deployed to: $contractAddress\n🔗 View on Etherscan: $etherscanLink';
        });
        Fluttertoast.showToast(msg: '🎉 ERC-20 Token Deployed Successfully');
        print('ERC-20 Token deployed to: $contractAddress');
        print('Etherscan link: $etherscanLink');
      } else {
        String message = js_util.getProperty(response, 'message');
        setState(() {
          _deployMessage += '\n❌ ERC-20 Deployment Error: $message';
        });
        Fluttertoast.showToast(msg: '❌ ERC-20 Deployment Failed');
        print('ERC-20 Deployment failed: $message');
      }
    } catch (e) {
      setState(() {
        _deployMessage += '\n❌ An error occurred during ERC-20 deployment: $e';
      });
      Fluttertoast.showToast(msg: '❌ ERC-20 Deployment Failed');
      print('Exception during ERC-20 deployment: $e');
    } finally {
      setState(() {
        _isDeployingERC20 = false;
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
          title: Text('Blockchain Deployment'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instructions
              Text(
                'Select a network, connect your wallet, and deploy your NFT or ERC-20 token.',
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

              // NFT Deployment Section
              if (_isConnected) ...[
                Text(
                  'Deploy NFT Collection:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _nftNameController,
                  decoration: InputDecoration(
                    labelText: 'NFT Token Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _nftSymbolController,
                  decoration: InputDecoration(
                    labelText: 'NFT Token Symbol',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isDeployingNFT || _isDeployingERC20
                        ? null
                        : () async {
                            await deployNFTFunction();
                          },
                    child: _isDeployingNFT
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text('Deploy NFT'),
                  ),
                ),
                SizedBox(height: 40),

                // ERC-20 Deployment Section
                Text(
                  'Deploy ERC-20 Token:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _erc20NameController,
                  decoration: InputDecoration(
                    labelText: 'ERC-20 Token Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _erc20SymbolController,
                  decoration: InputDecoration(
                    labelText: 'ERC-20 Token Symbol',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _erc20InitialSupplyController,
                  decoration: InputDecoration(
                    labelText: 'Initial Supply',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: _erc20DecimalsController,
                  decoration: InputDecoration(
                    labelText: 'Decimals',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isDeployingERC20 || _isDeployingNFT
                        ? null
                        : () async {
                            await deployERC20Function();
                          },
                    child: _isDeployingERC20
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text('Deploy ERC-20 Token'),
                  ),
                ),
                SizedBox(height: 20),

                // Deployment Messages
                if (_deployMessage.isNotEmpty)
                  Text(
                    _deployMessage,
                    style: TextStyle(
                      color: _deployMessage.contains('🎉')
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
