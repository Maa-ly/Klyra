// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title KlyraConstants
 * @notice Constants used across Klyra contracts
 */
library KlyraConstants {
    // Chain IDs
    address internal constant ETH_ADDRESS = address(0);
    uint256 internal constant ETHEREUM_CHAIN_ID = 1;
    uint256 internal constant BASE_CHAIN_ID = 8453;
    
    // Testnet Chain IDs
    uint256 internal constant ETHEREUM_SEPOLIA_CHAIN_ID = 11155111;
    uint256 internal constant BASE_SEPOLIA_CHAIN_ID = 84532;
    
    // Fee calculation constants
    uint256 internal constant FEE_DENOMINATOR = 10000; // 100% = 10000 basis points
    uint256 internal constant MAX_FEE = 1000; // 10% max fee
    uint256 internal constant SLIPPAGE_DENOMINATOR = 1000; // For slippage calculations
    uint256 internal constant DEFAULT_SLIPPAGE_BPS = 50; // Default 0.5% slippage
    
    // Default 1inch Router address
    // Note: All router types use the same address as they are handled by the same contract
    address internal constant DEFAULT_ROUTER = 0x111111125421cA6dc452d289314280a0f8842A65;
}


