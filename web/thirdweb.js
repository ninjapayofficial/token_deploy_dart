// web/thirdweb.js

let sdkInstance = null;

// **⚠️ Security Warning:**  
// Do **NOT** expose your SECRET_KEY in production. This is insecure and for demonstration only.
const CLIENT_ID = 'YOUR_THIRDWEB_CLIENT_ID'; // Replace with your Thirdweb Client ID
const SECRET_KEY = 'YOUR_THIRDWEB_SECRET_KEY'; // Replace with your Thirdweb Secret Key

// Function to initialize Thirdweb SDK
window.initializeSDK = function() {
  console.log('Initializing SDK...');
  if (window.ethereum && window.ethers && window.ThirdwebSDK) {
    try {
      const provider = new window.ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();
      sdkInstance = new window.ThirdwebSDK(signer, {
        clientId: CLIENT_ID,
        secretKey: SECRET_KEY
      });
      console.log('Thirdweb SDK initialized.', sdkInstance);
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
    await window.ethereum.request({ method: 'eth_requestAccounts' });
    const provider = new window.ethers.providers.Web3Provider(window.ethereum);
    const network = await provider.getNetwork();
    const account = await provider.getSigner().getAddress();
    console.log('Wallet connected:', account, 'on network:', network.name);
    return { success: true, account: account, network: network.name };
  } catch (error) {
    console.error('Error connecting wallet:', error);
    return { success: false, message: error.message || 'Unknown error.' };
  }
};

// Function to deploy NFT Collection
window.deployNFT = async function(name, symbol, network) {
  console.log(`Deploying NFT Collection: Name=${name}, Symbol=${symbol}, Network=${network}`);
  if (!sdkInstance) {
    const initialized = window.initializeSDK();
    if (!initialized) {
      return { success: false, message: 'SDK initialization failed.' };
    }
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
    // Re-initialize SDK with selected network
    sdkInstance = new window.ThirdwebSDK(new window.ethers.Wallet(SECRET_KEY), selectedNetwork.rpcUrl);
    console.log('Thirdweb SDK re-initialized with network:', network);

    // Deploy the NFT Collection Contract
    const contractAddress = await sdkInstance.deployer.deployBuiltInContract(
      "nft-collection",
      {
        name: name,
        symbol: symbol,
        primary_sale_recipient: window.ethers.constants.AddressZero,
        image: "https://example.com/your-image.png",
        description: "This is Nin Token",
        external_link: "https://ninjapay.in",
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
