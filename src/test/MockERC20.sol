// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockERC20
 * @notice Simple mock ERC20 token for testing
 * @dev Everything hardcoded - no constructor, no limits
 */
contract MockERC20 is ERC20 {
    
    /**
     * @notice Constructor with hardcoded values
     */
    constructor() ERC20("Mock Token", "MOCK") {
      
    }
    
    /**
     * @notice Mint tokens to any address
     * @param to Address to mint tokens to
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
    
    /**
     * @notice Mint tokens to caller
     * @param amount Amount of tokens to mint
     */
    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }
    
    /**
     * @notice Burn tokens from caller
     * @param amount Amount of tokens to burn
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
    
    /**
     * @notice Approve spender to spend tokens
     * @param spender Address to approve
     * @param amount Amount to approve
     * @return success Whether approval was successful
     */
    function approve(address spender, uint256 amount) public override returns (bool success) {
        _approve(msg.sender, spender, amount);
        return true;
    }
}
