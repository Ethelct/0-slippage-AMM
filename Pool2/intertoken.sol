// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract InterToken is ERC20, Ownable {
    // Mapping to track authorized minters
    mapping(address => bool) public authorizedMinters;

    // Address of the pool contract
    address public poolAddress;

    // Events
    event Minted(address indexed to, uint256 amount);
    event Burned(address indexed from, uint256 amount);
    event MinterAuthorized(address indexed minter);
    event MinterRevoked(address indexed minter);
    event PoolAddressUpdated(address indexed newPoolAddress);

    // Constructor
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address _owner
    ) ERC20(name, symbol) Ownable(_owner) {
        _mint(_owner, initialSupply);
        transferOwnership(_owner);
        emit Minted(_owner, initialSupply);
    }

    // Specify 6 decimals
    function decimals() public pure override returns (uint8) {
        return 6;
    }

    // Modifier to restrict access to the pool
    modifier onlyPool() {
        require(msg.sender == poolAddress, "Only the pool can call this function");
        _;
    }

    // Function to set the pool address
    function setPoolAddress(address _poolAddress) external onlyOwner {
        require(_poolAddress != address(0), "Invalid pool address");
        poolAddress = _poolAddress;
        emit PoolAddressUpdated(_poolAddress);
    }

    // Authorize a minter
    function authorizeMinter(address minter) external onlyOwner {
        require(minter != address(0), "Invalid minter address");
        authorizedMinters[minter] = true;
        emit MinterAuthorized(minter);
    }

    // Revoke minter
    function revokeMinter(address minter) external onlyOwner {
        require(authorizedMinters[minter], "Minter not authorized");
        authorizedMinters[minter] = false;
        emit MinterRevoked(minter);
    }

    // Mint tokens to the pool (restricted to the pool)
    function mintToPool(uint256 amount) external onlyPool {
        require(amount > 0, "Amount must be greater than zero");
        _mint(poolAddress, amount);
        emit Minted(poolAddress, amount);
    }

    // Burn tokens from the pool (restricted to the pool)
    function burnFromPool(uint256 amount) external onlyPool {
        uint256 poolBalance = balanceOf(poolAddress);
        require(amount > 0, "Amount must be greater than zero");
        require(amount <= poolBalance, "Cannot burn more than pool balance");
        _burn(poolAddress, amount);
        emit Burned(poolAddress, amount);
    }

    // Mint function for authorized minters (if needed)
    function mint(address to, uint256 amount) external {
        require(authorizedMinters[msg.sender], "Not authorized to mint");
        require(amount > 0, "Amount must be greater than zero");
        _mint(to, amount);
        emit Minted(to, amount);
    }

    // Burn function for authorized minters (if needed)
    function burn(address from, uint256 amount) external {
        require(authorizedMinters[msg.sender], "Not authorized to burn");
        require(amount > 0, "Amount must be greater than zero");
        _burn(from, amount);
        emit Burned(from, amount);
    }
}
