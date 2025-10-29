// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {KlyraErrors} from "../dataTypes/errors.sol";
import {KlyraConstants} from "../dataTypes/constants.sol";

/**
 * @title KlyraHelpers
 * @notice Helper functions for Klyra contracts
 */
library KlyraHelpers {
    using SafeERC20 for IERC20;

    /**
     * @notice Handle token input (transfer from user to contract)
     * @dev REQUIRES: User must have called token.approve(thisContract, amount) BEFORE calling this
     * @dev This uses safeTransferFrom which will revert if:
     *      1. User hasn't approved this contract
     *      2. User's approval amount is less than the transfer amount
     *      3. User doesn't have sufficient token balance
     * @param token The ERC20 token address (or ETH_ADDRESS for native ETH)
     * @param amount The amount to transfer
     * @param from The address to transfer from (must have approved this contract)
     * @param to The address to transfer to
     */
    function handleTokenInput(address token, uint256 amount, address from, address to) internal {
        if (token != KlyraConstants.ETH_ADDRESS) {
            IERC20(token).safeTransferFrom(from, to, amount);
        }
    }

    /**
     * @notice Approve router for token spending
     */
    function approveRouter(address token, address router, uint256 amount) internal {
        if (token != KlyraConstants.ETH_ADDRESS) {
            IERC20(token).safeIncreaseAllowance(router, amount);
        }
    }

    /**
     * @notice Calculate fee and net amount
     * @dev Fee is rounded up to ensure protocol always receives at least the minimum fee
     */
    function calculateFee(uint256 amount, uint256 feePercentage)
        internal
        pure
        returns (uint256 feeAmount, uint256 netAmount)
    {
        // Round up: (amount * feePercentage + FEE_DENOMINATOR - 1) / FEE_DENOMINATOR
        feeAmount = (amount * feePercentage + KlyraConstants.FEE_DENOMINATOR - 1) / KlyraConstants.FEE_DENOMINATOR;
        netAmount = amount - feeAmount;
    }

    /**
     * @notice Transfer token or ETH
     */
    function transferToken(address token, address to, uint256 amount) internal {
        if (token == KlyraConstants.ETH_ADDRESS) {
            (bool success,) = payable(to).call{value: amount}("");
            if (!success) revert KlyraErrors.TransferFailed();
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }

    /**
     * @notice Get balance of token or ETH
     */
    function getBalance(address token, address account) internal view returns (uint256) {
        if (token == KlyraConstants.ETH_ADDRESS) {
            return account.balance;
        } else {
            return IERC20(token).balanceOf(account);
        }
    }

    /**
     * @notice Validate output meets requirement
     */
    function validateOutput(uint256 actualOutput, uint256 requiredOutput) internal pure {
        if (actualOutput < requiredOutput) {
            revert KlyraErrors.InsufficientInputForRequiredOutput();
        }
    }

    /**
     * @notice Get token decimals, handling ETH (which has 18 decimals)
     * @dev Safely retrieves decimals using staticcall, defaults to 18 if call fails
     * @param token The token address (or ETH_ADDRESS for native ETH)
     * @return decimals The number of decimals (18 for ETH or if call fails)
     */
    function getTokenDecimals(address token) internal view returns (uint8) {
        if (token == KlyraConstants.ETH_ADDRESS) {
            return 18;
        }
        
        // Try to get decimals using staticcall (safe for non-standard tokens)
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSelector(IERC20Metadata.decimals.selector)
        );
        
        if (success && data.length >= 32) {
            uint256 returnedDecimals = abi.decode(data, (uint256));
            if (returnedDecimals <= type(uint8).max) {
                return uint8(returnedDecimals);
            }
        }
        
        // Default to 18 decimals if call fails or returns invalid value
        return 18;
    }

    /**
     * @notice Normalize token amount to a standard decimal base (18 decimals)
     * @dev Converts token amounts to a common 18-decimal representation for consistent calculations
     * @param amount The token amount in its native smallest unit
     * @param token The token address (or ETH_ADDRESS for native ETH)
     * @return normalizedAmount The amount normalized to 18 decimals
     */
    function normalizeTo18Decimals(uint256 amount, address token) internal view returns (uint256) {
        uint8 decimals = getTokenDecimals(token);
        
        if (decimals == 18) {
            return amount;
        } else if (decimals < 18) {
            // Scale up to 18 decimals
            return amount * (10 ** (18 - decimals));
        } else {
            // Scale down from >18 decimals to 18 (rare case)
            return amount / (10 ** (decimals - 18));
        }
    }
}
