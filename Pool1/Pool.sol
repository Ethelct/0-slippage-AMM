// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DynamicPool is Ownable {
    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;
    uint256 private swapFeePercentage; // Swap fee in basis points (0.09% = 9 basis points)
    uint256 private constant FEE_DENOMINATOR = 10_000;

    uint256 public collectedFees; // Tracks collected fees in TokenB

    uint256 public interTokenTotalSupply;
    mapping(address => uint256) private interTokenBalances;

    event SwapExecuted(
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 fee,
        address indexed sender,
        address recipient
    );
    event Minted(address indexed to, uint256 amount);
    event Burned(address indexed from, uint256 amount);
    event InitialSupplyTransferred(address token, address from, uint256 amount);

    // Constructor
    constructor(
        address _tokenA,
        address _tokenB,
        uint256 _swapFeePercentage,
        uint256 _initialInterTokenSupply,
        address _owner
    ) Ownable(_owner) {
        require(_tokenA != address(0), "Invalid TokenA address");
        require(_tokenB != address(0), "Invalid TokenB address");
        require(_swapFeePercentage <= FEE_DENOMINATOR, "Fee too high");

        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        swapFeePercentage = _swapFeePercentage;

        interTokenTotalSupply = _initialInterTokenSupply;
        interTokenBalances[address(this)] = _initialInterTokenSupply;
        emit Minted(address(this), _initialInterTokenSupply);
    }

    function initializeTokenASupply(
        uint256 _initialTokenASupply
    ) external onlyOwner {
        require(
            _initialTokenASupply > 0,
            "Initial TokenA supply must be greater than zero"
        );
        require(
            tokenA.transferFrom(
                msg.sender,
                address(this),
                _initialTokenASupply
            ),
            "TokenA transfer failed"
        );
        emit InitialSupplyTransferred(
            address(tokenA),
            msg.sender,
            _initialTokenASupply
        );
    }

    function setSwapFeePercentage(uint256 _swapFeePercentage) public onlyOwner {
        require(_swapFeePercentage <= FEE_DENOMINATOR, "Fee too high");
        swapFeePercentage = _swapFeePercentage;
    }

    function getSwapFeePercentage() public view returns (uint256) {
        return swapFeePercentage;
    }

    function mintInterToken(address to, uint256 amount) internal {
        interTokenBalances[to] += amount;
        interTokenTotalSupply += amount;
        emit Minted(to, amount);
    }

    function burnInterToken(address from, uint256 amount) internal {
        require(interTokenBalances[from] >= amount, "Insufficient balance");
        interTokenBalances[from] -= amount;
        interTokenTotalSupply -= amount;
        emit Burned(from, amount);
    }

    // Swap TokenB for TokenA
// Swap TokenB for TokenA
function swapTokenBForTokenA(
    uint256 amountIn,
    address recipient
) external returns (uint256 amountOut) {
    require(amountIn > 0, "Invalid input amount");

    // Ensure pool has allowance to spend TokenB
    require(
        tokenB.allowance(msg.sender, address(this)) >= amountIn,
        "Insufficient TokenB allowance"
    );

    // Deduct the fee
    uint256 fee = (amountIn * swapFeePercentage) / FEE_DENOMINATOR;
    uint256 amountInAfterFee = amountIn - fee;

    // Track the collected fee
    collectedFees += fee;

    // Calculate output amount (after fee deduction) using scaled calculation
    amountOut = calculateOutGivenIn(
        interTokenTotalSupply * 1e18, // ReserveIN = InterToken supply scaled
        tokenA.balanceOf(address(this)) * 1e18, // ReserveOUT = TokenA scaled
        amountInAfterFee * 1e18
    ) / 1e18; // Scale down the result

    // Mint InterToken based on the input amount of TokenB
    mintInterToken(msg.sender, amountInAfterFee);

    // Transfer TokenB from sender to pool
    tokenB.transferFrom(msg.sender, address(this), amountIn);

    // Transfer TokenA to recipient
    tokenA.transfer(recipient, amountOut);

    emit SwapExecuted(
        address(tokenB),
        address(tokenA),
        amountIn,
        amountOut,
        fee,
        msg.sender,
        recipient
    );
}

// Swap TokenA for TokenB
function swapTokenAForTokenB(
    uint256 amountIn,
    address recipient
) external returns (uint256 amountOut) {
    require(amountIn > 0, "Invalid input amount");

    // Ensure pool has allowance to spend TokenA
    require(
        tokenA.allowance(msg.sender, address(this)) >= amountIn,
        "Insufficient TokenA allowance"
    );

    // Current reserves scaled up for precision
    uint256 tokenASupply = tokenA.balanceOf(address(this)) * 1e18;
    uint256 interTokenSupply = interTokenTotalSupply * 1e18;

    // Add the full amountIn to the tokenASupply (scaled)
    uint256 newTokenASupply = tokenASupply + (amountIn * 1e18);

    // Calculate k = interTokenSupply * tokenASupply (scaled)
    uint256 k = interTokenSupply * tokenASupply;

    // Calculate new interToken supply based on k (scaled)
    uint256 newInterTokenSupply = k / newTokenASupply;

    // Calculate the amountOut before fee (scaled down)
    uint256 amountOutBeforeFee = (interTokenSupply - newInterTokenSupply) / 1e18;

    // Deduct the fee from the amountOut
    uint256 fee = (amountOutBeforeFee * swapFeePercentage) / FEE_DENOMINATOR;
    amountOut = amountOutBeforeFee - fee;

    // Track the collected fee
    collectedFees += fee;

    // Transfer TokenA from sender to pool
    tokenA.transferFrom(msg.sender, address(this), amountIn);

    // Burn InterToken based on the output amount before fee
    burnInterToken(msg.sender, amountOutBeforeFee);

    // Transfer the equivalent amount of TokenB to recipient minus the fee
    tokenB.transfer(recipient, amountOut);

    emit SwapExecuted(
        address(tokenA),
        address(tokenB),
        amountIn,
        amountOut,
        fee,
        msg.sender,
        recipient
    );
}


// Utility function to calculate the output of the swap
function calculateOutGivenIn(
    uint256 reserveIn,
    uint256 reserveOut,
    uint256 amountIn
) private pure returns (uint256) {
    require(reserveIn > 0 && reserveOut > 0, "Insufficient liquidity");

    // New reserves after adding the input (scaled)
    uint256 newReserveIn = reserveIn + amountIn;

    // Calculate k = reserveIn * reserveOut (scaled)
    uint256 k = reserveIn * reserveOut;

    // Calculate new reserveOut based on the constant k (scaled)
    uint256 newReserveOut = k / newReserveIn;

    // Amount out is the difference between old and new reserveOut (scaled)
    return reserveOut - newReserveOut;
}


    function withdrawFees(address to) external onlyOwner {
        require(collectedFees > 0, "No fees to withdraw");
        uint256 feeBalance = collectedFees;
        collectedFees = 0; // Reset fee balance
        tokenB.transfer(to, feeBalance);
    }

    function getTokenBalance()
        external
        view
        returns (uint256 tokenABalance, uint256 tokenBBalance)
    {
        tokenABalance = tokenA.balanceOf(address(this));
        tokenBBalance = tokenB.balanceOf(address(this));
    }
}
