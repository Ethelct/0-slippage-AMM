require('dotenv').config();
const { Web3 } = require('web3');

// Load environment variables
const PRIVATE_KEY = process.env.Private_Key; // Your wallet's private key
const WALLET_ADDRESS = process.env.Wallet; // Your wallet address
const POOL_ADDRESS = process.env.Pool2; // Your pool contract address
const SEPOLIA_RPC_URL = process.env.Sepolia_Url; // Your RPC URL
const USDT_ADDRESS = process.env.USDT; // USDT token address
const OTHER_TOKEN_ADDRESS = process.env.OtherToken; // Replace with TokenA or TokenB address
const INTERTOKEN_ADDRESS = process.env.Intertoken; // InterToken contract address

// Initialize Web3
const web3 = new Web3(new Web3.providers.HttpProvider(SEPOLIA_RPC_URL));

// Load the ERC-20 token ABI (approve function)
const ERC20_ABI = [
  {
    "constant": false,
    "inputs": [
      { "name": "_spender", "type": "address" },
      { "name": "_value", "type": "uint256" }
    ],
    "name": "approve",
    "outputs": [{ "name": "", "type": "bool" }],
    "type": "function"
  }
];

// Create token contract instance
function getTokenContract(tokenAddress) {
  return new web3.eth.Contract(ERC20_ABI, tokenAddress);
}

// Function to send a transaction for approval
async function approveToken(tokenAddress, spender, amount) {
  console.log(`Approving ${amount} of token ${tokenAddress} for spender ${spender}...`);

  try {
    const tokenContract = getTokenContract(tokenAddress);

    // Prepare the transaction data
    const data = tokenContract.methods.approve(spender, amount).encodeABI();

    // Get gas price and estimate
    const gasPrice = await web3.eth.getGasPrice();
    const gasEstimate = await web3.eth.estimateGas({
      from: WALLET_ADDRESS,
      to: tokenAddress,
      data: data
    });

    // Create the transaction
    const tx = {
      from: WALLET_ADDRESS,
      to: tokenAddress,
      data: data,
      gas: gasEstimate,
      gasPrice: gasPrice
    };

    // Sign the transaction
    const signedTx = await web3.eth.accounts.signTransaction(tx, PRIVATE_KEY);

    // Send the signed transaction
    const receipt = await web3.eth.sendSignedTransaction(signedTx.rawTransaction);

    console.log(`Approval successful! Transaction hash: ${receipt.transactionHash}`);
  } catch (error) {
    console.error("Error during approval:", error);
  }
}

// Main function to approve USDT, another token, and InterToken
async function main() {
  // Approve amounts
  const usdtApproveAmount = web3.utils.toWei("100000", "mwei"); // 1000 USDT (6 decimals)
  const otherTokenApproveAmount = web3.utils.toWei("100000", "mwei"); // 1000 TokenA or TokenB (18 decimals)
  const interTokenApproveAmount = web3.utils.toWei("100000", "mwei"); // 1000 InterToken (6 decimals)

  // Approve USDT for the pool
  await approveToken(USDT_ADDRESS, POOL_ADDRESS, usdtApproveAmount);

  // Approve the other token for the pool
  await approveToken(OTHER_TOKEN_ADDRESS, POOL_ADDRESS, otherTokenApproveAmount);

  // Approve the InterToken for the pool
  await approveToken(INTERTOKEN_ADDRESS, POOL_ADDRESS, interTokenApproveAmount);
}

// Run the script
main().catch((error) => {
  console.error("Error in script execution:", error);
});
