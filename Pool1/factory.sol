// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./pool2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DynamicPoolFactory is Ownable {
    // Event to log the creation of new pools
    event PoolCreated(
        address indexed poolAddress,
        address indexed tokenA,
        address indexed tokenB,
        uint256 swapFeePercentage,
        uint256 initialInterTokenSupply,
        address owner
    );

    // Array to store addresses of created pools
    address[] public createdPools;

    // Constructor: Ownable constructor automatically takes msg.sender as the owner
    constructor() Ownable(msg.sender) {}

    // Function to deploy a new pool contract with the specified parameters
    function createPool(
    address _tokenA,
    address _tokenB,
    uint256 _swapFeePercentage,
    uint256 _initialInterTokenSupply
) external onlyOwner returns (address) {
    // Validate input arguments
    require(_tokenA != address(0), "Invalid TokenA address");
    require(_tokenB != address(0), "Invalid TokenB address");
    require(_swapFeePercentage <= 10000, "Invalid fee percentage");
    require(_initialInterTokenSupply > 0, "Initial InterToken supply must be greater than zero");

    // Deploy the new pool contract with the factory's owner as the owner of the pool
    DynamicPool newPool = new DynamicPool(
        _tokenA,
        _tokenB,
        _swapFeePercentage,
        _initialInterTokenSupply,
        msg.sender  // Pass the factory's owner as the owner of the pool
    );

    // Add the newly created pool to the createdPools array
    createdPools.push(address(newPool));

    // Emit event for pool creation
    emit PoolCreated(
        address(newPool),
        _tokenA,
        _tokenB,
        _swapFeePercentage,
        _initialInterTokenSupply,
        msg.sender  // Set this to an admin wallet if desired
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
