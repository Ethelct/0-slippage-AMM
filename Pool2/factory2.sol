// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import "./Pool.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PoolFactory is Ownable {
    // Event to log the creation of new pools
    event PoolCreated(
        address indexed poolAddress,
        address indexed tokenA,
        address indexed tokenB,
        address interToken,
        uint256 swapFeePercentage,
        address owner
    );

    // Array to store addresses of created pools
    address[] public createdPools;

    // Constructor: Ownable constructor automatically takes msg.sender as the owner
    constructor() Ownable(msg.sender) {}

    // Function to deploy a new pool contract with your factory's own address set as its owner (or use an admin wallet)
    function createPool(
        address _tokenA,
        address _tokenB,
        address _interToken,
        uint256 _swapFeePercentage
    ) external onlyOwner returns (address) {
        // Validate input arguments
        require(_tokenA != address(0), "Invalid TokenA address");
        require(_tokenB != address(0), "Invalid TokenB address");
        require(_interToken != address(0), "Invalid InterToken address");
        require(_swapFeePercentage <= 10000, "Invalid fee percentage");

        // Deploy the new pool contract with your factory's own address set as its owner
        DynamicPoolWithInterToken newPool = new DynamicPoolWithInterToken(
            _tokenA,
            _tokenB,
            _interToken,
            _swapFeePercentage,
            address(this)  // Set this line to an admin wallet if desired, e.g., "0xYourAdminWalletAddress"
        );

        // Add the newly created pool to the createdPools array
        createdPools.push(address(newPool));

        // Emit event for pool creation
        emit PoolCreated(
            address(newPool),
            _tokenA,
            _tokenB,
            _interToken,
            _swapFeePercentage,
            msg.sender  // Set this to an admin wallet if desired, e.g., "0xYourAdminWalletAddress"
        );

        // Return the address of the newly created pool contract
        return address(newPool);
    }

    // Function to get the owner of the factory contract (if needed)
    function getOwner() external view returns (address) {
        return owner();
    }

    // Function to get the list of all created pools
    function getCreatedPools() external view returns (address[] memory) {
        return createdPools;
    }

    // Function to get the number of created pools
    function getCreatedPoolsCount() external view returns (uint256) {
        return createdPools.length;
    }
}
