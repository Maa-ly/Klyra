// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title KlyraErrors
 * @notice Custom errors for Klyra contracts
 */
library KlyraErrors {
    error InvalidAmount();
    error InvalidAddress();
    error InvalidToken();
    error UnsupportedChain();
    error SwapFailed();
    error InsufficientOutput();
    error InvalidFee();
    error TransferFailed();
    error InsufficientInputForRequiredOutput();
}


