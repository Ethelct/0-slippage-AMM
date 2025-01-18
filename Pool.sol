// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./InterToken.sol";

contract DynamicPoolWithInterToken is Ownable {
    IERC20 public immutable tokenA;
    IERC20 public immutable tokenB;
    InterToken public immutable interToken;
    uint256 private swapFeePercentage;
    uint256 private constant FEE_DENOMINATOR = 10_000;
    uint256 public collectedFees;

    event SwapExecuted(
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 fee,
        address indexed sender,
        address recipient
    );
    event InitialSupplyTransferred(address token, address from, uint256 amount);

    constructor(
        address _tokenA,
        address _tokenB,
        address _interToken,
        uint256 _swapFeePercentage,
        address _owner
    ) Ownable(_owner) {
        require(_tokenA != address(0), "Invalid TokenA address");
        require(_tokenB != address(0), "Invalid TokenB address");
        require(_interToken != address(0), "Invalid InterToken address");
        require(_swapFeePercentage <= FEE_DENOMINATOR, "Fee too high");

        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        interToken = InterToken(_interToken);
        swapFeePercentage = _swapFeePercentage;
        transferOwnership(_owner);
    }

    function initializeSupply(
        uint256 _initialTokenASupply,
        uint256 _initialInterTokenSupply
    ) external onlyOwner {
        require(
            _initialTokenASupply > 0,
            "Initial TokenA supply must be greater than zero"
        );
        require(
            _initialInterTokenSupply > 0,
            "Initial InterToken supply must be greater than zero"
        );

        require(
            tokenA.transferFrom(
                msg.sender,
                address(this),
                _initialTokenASupply
            ),
            "TokenA transfer failed"
        );
        require(
            interToken.transferFrom(
                msg.sender,
                address(this),
                _initialInterTokenSupply
            ),
            "InterToken transfer failed"
        );

        emit InitialSupplyTransferred(
            address(tokenA),
            msg.sender,
            _initialTokenASupply
        );
        emit InitialSupplyTransferred(
            address(interToken),
            msg.sender,
            _initialInterTokenSupply
        );
    }

    function setSwapFeePercentage(uint256 _swapFeePercentage) public onlyOwner {
        require(_swapFeePercentage <= FEE_DENOMINATOR, "Fee too high");
        swapFeePercentage = _swapFeePercentage;
    }

    function getSwapFeePercentage() public view returns (uint256) {
        return swapFeePercentage;
    }

    function swapTokenBForTokenA(
        uint256 amountIn,
        address recipient
    ) external returns (uint256 amountOut) {
        require(amountIn > 0, "Invalid input amount");
        require(
            tokenB.allowance(msg.sender, address(this)) >= amountIn,
            "Insufficient TokenB allowance"
        );

        uint256 fee = (amountIn * swapFeePercentage) / FEE_DENOMINATOR;
        uint256 amountInAfterFee = amountIn - fee;

        collectedFees += fee;

        amountOut = calculateOutGivenIn(
            interToken.balanceOf(address(this)) * 1e18,
            tokenA.balanceOf(address(this)) * 1e18,
            amountInAfterFee * 1e18
        ) / 1e18;

        interToken.mint(address(this), amountInAfterFee);
        tokenB.transferFrom(msg.sender, address(this), amountIn);
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

  function swapTokenAForTokenB(
    uint256 amountIn,
    address recipient
) external returns (uint256 amountOut) {
    require(amountIn > 0, "Invalid input amount");
    require(
        tokenA.allowance(msg.sender, address(this)) >= amountIn,
        "Insufficient TokenA allowance"
    );

    uint256 tokenASupply = tokenA.balanceOf(address(this)) * 1e18;
    uint256 interTokenPoolBalance = interToken.balanceOf(address(this)) * 1e18; // Use pool balance
    uint256 newTokenASupply = tokenASupply + (amountIn * 1e18);
    uint256 k = interTokenPoolBalance * tokenASupply;
    uint256 newInterTokenSupply = k / newTokenASupply;
    uint256 amountOutBeforeFee = (interTokenPoolBalance - newInterTokenSupply) / 1e18;

    uint256 fee = (amountOutBeforeFee * swapFeePercentage) / FEE_DENOMINATOR;
    amountOut = amountOutBeforeFee - fee;

    collectedFees += fee;

    tokenA.transferFrom(msg.sender, address(this), amountIn);
    interToken.burn(address(this), amountOutBeforeFee); // Ensure only pool tokens are burned
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



    function calculateOutGivenIn(
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 amountIn
    ) private pure returns (uint256) {
        require(reserveIn > 0 && reserveOut > 0, "Insufficient liquidity");

        uint256 newReserveIn = reserveIn + amountIn;
        uint256 k = reserveIn * reserveOut;
        uint256 newReserveOut = k / newReserveIn;

        return reserveOut - newReserveOut;
    }

    function withdrawFees(address to) external onlyOwner {
        require(collectedFees > 0, "No fees to withdraw");
        uint256 feeBalance = collectedFees;
        collectedFees = 0;
        tokenB.transfer(to, feeBalance);
    }

    function getTokenBalances()
        external
        view
        returns (uint256 tokenABalance, uint256 tokenBBalance, uint256 interTokenBalance)
    {
        tokenABalance = tokenA.balanceOf(address(this));
        tokenBBalance = tokenB.balanceOf(address(this));
        interTokenBalance = interToken.balanceOf(address(this));
    }
}
