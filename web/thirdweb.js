// web/thirdweb.js

// Ensure that Ethers.js and ThirdwebSDK are loaded
if (!window.ethers || !window.ThirdwebSDK) {
  console.error('Ethers.js or ThirdwebSDK not loaded.');
}

// Function to initialize Thirdweb SDK
window.initializeThirdweb = async function() {
  console.log('Initializing Thirdweb SDK...');
  if (window.ethereum && window.ethers && window.ThirdwebSDK) {
    try {
      // Request account access if needed
      await window.ethereum.request({ method: 'eth_requestAccounts' });

      // Create an ethers provider
      const provider = new window.ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();

      // Initialize Thirdweb SDK with the signer and clientId
      const sdk = new window.ThirdwebSDK(signer, {
        clientId: '690062c61fec9aa02c8f0d8d84e2dc99', // Replace with your actual clientId
        secretKey: 'WA7-QDoWghPpkIgjmKWtvUGSOgzD9c06_lDqUzcEK50o_9bdGo9u5fGm1aAp7lBRqdxp0fJ74NFRWeIp0ahTiA', // Replace with your actual clientId
        chainId: await signer.getChainId(),
      });

      window.thirdwebSDK = sdk;
      console.log('Thirdweb SDK initialized:', sdk);
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

// Function to deploy NFT Collection
window.deployNFT = async function(name, symbol, network) {
  console.log(`Deploying NFT Collection: Name=${name}, Symbol=${symbol}, Network=${network}`);
  
  if (!window.thirdwebSDK) {
    console.error('Thirdweb SDK is not initialized. Call initializeThirdweb first.');
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
    const contractAddress = await window.thirdwebSDK.deployer.deployBuiltInContract(
      "nft-collection",
      {
        name: name,
        symbol: symbol,
        primary_sale_recipient: window.ethers.constants.AddressZero,
        image: "https://example.com/your-image.png", // Replace with your image URL
        description: "This is Nin Token", // Replace with your description
        external_link: "https://ninjapay.in", // Replace with your external link
        platform_fee_recipient: window.ethers.constants.AddressZero,
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
