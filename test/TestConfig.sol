// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

/**
 * @title TestConfig
 * @notice Test configuration and constants
 * @dev Centralized test configuration for consistent testing
 */
contract TestConfig {
    // Test accounts
    address public constant TEST_OWNER = address(0x1);
    address public constant TEST_FEE_COLLECTOR = address(0x2);
    address public constant TEST_USER_1 = address(0x3);
    address public constant TEST_USER_2 = address(0x4);
    address public constant TEST_USER_3 = address(0x5);

    // Test amounts
    uint256 public constant INITIAL_BALANCE = 1000000 * 10 ** 18;
    uint256 public constant TEST_AMOUNT = 1000 * 10 ** 18;
    uint256 public constant LARGE_AMOUNT = 10000 * 10 ** 18;
    uint256 public constant SMALL_AMOUNT = 100 * 10 ** 18;

    // Fee configurations
    uint256 public constant DEFAULT_FEE_PERCENTAGE = 100; // 1%
    uint256 public constant HIGH_FEE_PERCENTAGE = 500; // 5%
    uint256 public constant LOW_FEE_PERCENTAGE = 50; // 0.5%

    // Slippage configurations
    uint256 public constant DEFAULT_SLIPPAGE_BPS = 50; // 0.5%
    uint256 public constant HIGH_SLIPPAGE_BPS = 100; // 1%
    uint256 public constant LOW_SLIPPAGE_BPS = 25; // 0.25%

    // Router addresses (test addresses)
    address public constant TEST_AGGREGATION_ROUTER = address(0x1111);
    address public constant TEST_UNOSWAP_ROUTER = address(0x2222);
    address public constant TEST_CLIPPER_ROUTER = address(0x3333);
    address public constant TEST_GENERIC_ROUTER = address(0x4444);

    // Test token configurations
    string public constant TOKEN_A_NAME = "TestTokenA";
    string public constant TOKEN_A_SYMBOL = "TTA";
    string public constant TOKEN_B_NAME = "TestTokenB";
    string public constant TOKEN_B_SYMBOL = "TTB";
    string public constant TOKEN_C_NAME = "TestTokenC";
    string public constant TOKEN_C_SYMBOL = "TTC";

    // Test scenarios
    uint256 public constant BATCH_SIZE = 10;
    uint256 public constant MAX_BATCH_SIZE = 100;

    // Gas limits for testing
    uint256 public constant GAS_LIMIT_LOW = 100000;
    uint256 public constant GAS_LIMIT_MEDIUM = 500000;
    uint256 public constant GAS_LIMIT_HIGH = 1000000;
}


