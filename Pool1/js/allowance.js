require('dotenv').config(); // Load environment variables
const { Web3 } = require('web3'); // Web3 setup

// Load environment variables
const SEPOLIA_URL = process.env.Sepolia_Url; // Sepolia network URL
const WALLET_ADDRESS = process.env.Wallet; // Wallet address
const POOL_ADDRESS = process.env.Pool; // Pool contract address

// ERC20 ABI for checking allowance
const ERC20_ABI = [
    {
        "constant": true,
        "inputs": [
            { "internalType": "address", "name": "_owner", "type": "address" },
            { "internalType": "address", "name": "_spender", "type": "address" }
        ],
        "name": "allowance",
        "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }],
        "stateMutability": "view",
        "type": "function"
    }
];

// Connect to the Sepolia network
const web3 = new Web3(SEPOLIA_URL);

// Function to check allowance
async function checkAllowance(tokenAddress, ownerAddress, spenderAddress) {
    try {
        const tokenContract = new web3.eth.Contract(ERC20_ABI, tokenAddress);
        const allowance = await tokenContract.methods.allowance(ownerAddress, spenderAddress).call();
        console.log(`Allowance for spender ${spenderAddress} from owner ${ownerAddress} for token ${tokenAddress}: ${allowance}`);
    } catch (error) {
        console.error("Error checking allowance:", error.message);
    }
}

// Example usage: Check allowance for USDT and another token for the pool contract
const USDT_ADDRESS = process.env.USDT; // USDT token address
const OTHER_TOKEN_ADDRESS = process.env.OtherToken; // Replace with TokenA or TokenB address

async function main() {
    console.log("Checking allowances...");

    // Check USDT allowance
    await checkAllowance(USDT_ADDRESS, WALLET_ADDRESS, POOL_ADDRESS);

    // Check Other Token allowance
    await checkAllowance(OTHER_TOKEN_ADDRESS, WALLET_ADDRESS, POOL_ADDRESS);
}

main().catch((error) => {
    console.error("Error in script execution:", error);
});
