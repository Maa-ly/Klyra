// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title PaymentBreakdown
 * @notice Struct for payment breakdown information
 * @dev Contains all relevant information for a payment transaction
 */
struct PaymentBreakdown {
    address inputToken;
    address outputToken;
    uint256 inputAmount;
    uint256 feeAmount;
    uint256 netInputAmount;
    uint256 expectedOutputAmount;
    uint256 feePercentage;
    uint256 minOutputWithSlippage;
    uint256 slippageBps;
}
