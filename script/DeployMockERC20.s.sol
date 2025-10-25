// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {MockERC20} from "../src/test/MockERC20.sol";

/**
 * @title DeployMockERC20
 * @notice Script to deploy mock ERC20 tokens for testing
 */
contract DeployMockERC20 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy Mock USDC
        MockERC20 mockUSDC = new MockERC20(
            "Mock USD Coin",
            "mUSDC",
            6, // USDC has 6 decimals
            1000000 * 10**6 // 1M tokens
        );
        
        // Deploy Mock DAI
        MockERC20 mockDAI = new MockERC20(
            "Mock Dai Stablecoin",
            "mDAI",
            18, // DAI has 18 decimals
            1000000 * 10**18 // 1M tokens
        );
        
        // Deploy Mock WETH
        MockERC20 mockWETH = new MockERC20(
            "Mock Wrapped Ether",
            "mWETH",
            18, // WETH has 18 decimals
            1000 * 10**18 // 1000 tokens
        );
        
        vm.stopBroadcast();
        
        // Log deployment addresses
        console.log("Mock USDC deployed at:", address(mockUSDC));
        console.log("Mock DAI deployed at:", address(mockDAI));
        console.log("Mock WETH deployed at:", address(mockWETH));
    }
}
