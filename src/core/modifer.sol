// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {KlyraErrors} from "../dataTypes/errors.sol";
import {KlyraConstants} from "../dataTypes/constants.sol";

/**
 * @title KlyraModifiers
 * @notice Reusable modifiers for Klyra contracts
 */
abstract contract KlyraModifiers {
    modifier validAmount(uint256 amount) {
        if (amount == 0) revert KlyraErrors.InvalidAmount();
        _;
    }

    modifier validAddress(address addr) {
        if (addr == address(0)) revert KlyraErrors.InvalidAddress();
        _;
    }

    modifier validEthPayment(address token, uint256 amount) {
        if (token == KlyraConstants.ETH_ADDRESS && msg.value != amount) {
            revert KlyraErrors.InvalidAmount();
        }
        _;
    }
}
