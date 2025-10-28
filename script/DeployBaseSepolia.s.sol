// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {Klyra1inchV2} from "../src/core/klyra.sol";
import {KlyraConstants} from "../src/dataTypes/constants.sol";

/**
 * @title Deploy to Base Sepolia
 * @notice Deploys Klyra contracts to Base Sepolia testnet
 */
contract DeployBaseSepolia is Script {
    Klyra1inchV2 public klyra;
    address public feeCollector = 0xC263d52CB381e41B3B3bBD27fb0B9457e22d9b3F;
    uint256 public feePercentage = 300; // 3%
    address public routerAddress;

    function run() external {
        string memory privateKeyString = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.parseUint(privateKeyString);
        address deployer = vm.addr(deployerPrivateKey);

        // Set configuration
        setConfiguration(deployer);

        vm.createSelectFork("https://base-sepolia.g.alchemy.com/v2/V_wzwTCsq7HY3N8NgrxQa");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy contract
        deploy();

        vm.stopBroadcast();

        console.log("=== Base Sepolia Deployment Complete ===");
        console.log("Contract Address:", getDeployedAddress());
        console.log("Fee Collector:", feeCollector);
        console.log("Fee Percentage:", feePercentage, "(3%)");
        console.log("Router Address:", routerAddress);
        console.log("Deployer:", deployer);
    }

    function deploy() public {
        console.log("Deploying Klyra1inchV2 to Base Sepolia...");
        klyra = new Klyra1inchV2(feeCollector, feePercentage, routerAddress);
        console.log("Klyra1inchV2 deployed at:", address(klyra));
    }

    function setConfiguration(address deployer) public {
        // Set fee collector to deployer for testnet
        feeCollector = deployer;

        // Use default 1inch router for Base
        routerAddress = KlyraConstants.DEFAULT_ROUTER;

        console.log("Configuration set:");
        console.log("Fee Collector:", feeCollector);
        console.log("Fee Percentage:", feePercentage);
        console.log("Router Address:", routerAddress);
    }

    function getDeployedAddress() public view returns (address) {
        return address(klyra);
    }
}
