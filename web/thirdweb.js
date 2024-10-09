// web/thirdweb.js

// Import ThirdwebSDK and ethers
import { ThirdwebSDK } from 'https://esm.sh/@thirdweb-dev/sdk@4.0.99?bundle';
import { ethers } from 'https://esm.sh/ethers@5.7.2';

// Function to initialize Thirdweb SDK
window.initializeSDK = async function() {
  console.log('Initializing Thirdweb SDK...');
  if (window.ethereum && window.ethers && window.ThirdwebSDK) {
    try {
      // Request account access if needed
      await window.ethereum.request({ method: 'eth_requestAccounts' });

      // Create an ethers provider
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();

      // Initialize Thirdweb SDK with the signer
      const sdk = new ThirdwebSDK(signer, {
        chainId: await signer.getChainId(),
      });

      window.sdkInstance = sdk;
      console.log('Thirdweb SDK initialized with signer:', sdk);
      return true;
    } catch (error) {
      console.error('Error initializing Thirdweb SDK:', error);
      return false;
    }
  } else {
    console.error('MetaMask, Ethers.js, or ThirdwebSDK is not available.');
    return false;
  }
};

// Function to switch network
window.switchNetwork = async function(network) {
  console.log(`Switching to network: ${network}`);
  const networkChainIds = {
    sepolia: '0xaa36a7',
    mainnet: '0x1',
    // Add more networks as needed
  };

  const chainId = networkChainIds[network.toLowerCase()];
  if (!chainId) {
    alert('Unsupported network selected.');
    return false;
  }

  try {
    await window.ethereum.request({
      method: 'wallet_switchEthereumChain',
      params: [{ chainId }],
    });
    console.log(`Switched to network: ${network}`);
    return true;
  } catch (switchError) {
    if (switchError.code === 4902) {
      alert('The selected network is not available in your MetaMask. Please add it manually.');
    } else {
      console.error('Failed to switch network:', switchError);
      alert('Failed to switch network.');
    }
    return false;
  }
};

// Function to connect wallet
window.connectWallet = async function() {
  console.log('Connecting wallet...');
  if (!window.ethereum) {
    alert('MetaMask is not installed.');
    return { success: false, message: 'MetaMask is not installed.' };
  }

  try {
    // Initialize SDK
    const initialized = await window.initializeSDK();
    if (!initialized) {
      return { success: false, message: 'SDK initialization failed.' };
    }

    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    const account = await signer.getAddress();
    const network = await signer.getChainId();

    console.log('Wallet connected:', account, 'on network:', network);
    return { success: true, account: account, network: network };
  } catch (error) {
    console.error('Error connecting wallet:', error);
    return { success: false, message: error.message || 'Unknown error.' };
  }
};

// Function to deploy NFT Collection
window.deployNFT = async function(name, symbol, network) {
  console.log(`Deploying NFT Collection: Name=${name}, Symbol=${symbol}, Network=${network}`);
  if (!window.sdkInstance) {
    console.error('SDK instance not initialized.');
    return { success: false, message: 'SDK not initialized.' };
  }

  const networkConfigs = {
    sepolia: {
      rpcUrl: 'https://rpc.ankr.com/eth_sepolia',
      etherscan: 'https://sepolia.etherscan.io/address/'
    },
    mainnet: {
      rpcUrl: 'https://rpc.ankr.com/eth',
      etherscan: 'https://etherscan.io/address/'
    },
    // Add more networks as needed
  };

  const selectedNetwork = networkConfigs[network.toLowerCase()];
  if (!selectedNetwork) {
    return { success: false, message: 'Unsupported network selected.' };
  }

  try {
    // Switch network if necessary
    await window.switchNetwork(network);

    // Deploy the NFT Collection Contract using Thirdweb SDK
    const contractAddress = await window.sdkInstance.deployer.deployBuiltInContract(
      "nft-collection",
      {
        name: name,
        symbol: symbol,
        primary_sale_recipient: ethers.constants.AddressZero,
        image: "https://example.com/your-image.png",
        description: "This is Nin Token",
        external_link: "https://ninjapay.in",
        platform_fee_recipient: ethers.constants.AddressZero,
        platform_fee_basis_points: 100 // 1%
      },
      "5.0.2", // Specify the version
      {
        gasLimit: 5000000, // Set a higher gas limit if needed
      }
    );

    // Generate Etherscan Link
    const etherscanLink = `${selectedNetwork.etherscan}${contractAddress}`;

    console.log("NFT Contract deployed to:", contractAddress);
    return { success: true, contractAddress, etherscanLink };
  } catch (error) {
    console.error('Error deploying contract:', error);
    const errorMessage = error.reason || error.message || 'Unknown error during deployment.';
    return { success: false, message: errorMessage };
  }
};
