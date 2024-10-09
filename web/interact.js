window.connectMetamask = async function () {
  if (typeof window.ethereum !== 'undefined') {
    try {
      await window.ethereum.request({ method: 'eth_requestAccounts' });
      provider = new ethers.providers.Web3Provider(window.ethereum);
      signer = provider.getSigner();
      sdk = new ThirdwebSDK(signer);
      return await signer.getAddress();
    } catch (error) {
      console.error('Error connecting wallet:', error);
      return null;
    }
  } else {
    alert('MetaMask is not installed!');
    return null;
  }
};

window.deployNFT = async function (name, symbol) {
  if (!sdk) {
    console.error('SDK is not initialized, please connect wallet first.');
    return 'SDK not initialized';
  }

  try {
    const contractAddress = await sdk.deployer.deployBuiltInContract(
      "nft-collection",
      {
        name: name,
        symbol: symbol,
        primary_sale_recipient: ethers.constants.AddressZero,
        image: "https://example.com/your-image.png",
        description: "This is Nin Token",
        external_link: "https://ninjapay.in",
        platform_fee_recipient: ethers.constants.AddressZero,
        platform_fee_basis_points: 100, // 1%
      },
      "5.0.2",
      {
        gasLimit: 5000000,
      }
    );

    console.log("NFT Contract deployed to:", contractAddress);
    return contractAddress;
  } catch (error) {
    console.error('Error deploying contract:', error);
    return `Deployment Error: ${error.message}`;
  }
};
