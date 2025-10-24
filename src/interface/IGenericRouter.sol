// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title IGenericRouter
 * @notice Interface for 1inch Generic Router
 * @dev Used for complex routing logic and custom swap paths
 */
interface IGenericRouter {
    /**
     * @notice Performs a generic swap with custom routing
     * @param executor Address that will execute the swap
     * @param srcToken Source token address
     * @param dstToken Destination token address
     * @param srcReceiver Address that will receive source tokens (usually executor)
     * @param dstReceiver Address that will receive destination tokens
     * @param amount Amount of source tokens
     * @param minReturnAmount Minimum amount of destination tokens
     * @param flags Flags for special swap behaviors
     * @param data Encoded routing data
     * @return returnAmount Amount of destination tokens received
     */
    function swap(
        address executor,
        address srcToken,
        address dstToken,
        address payable srcReceiver,
        address payable dstReceiver,
        uint256 amount,
        uint256 minReturnAmount,
        uint256 flags,
        bytes calldata data
    ) external payable returns (uint256 returnAmount);

    /**
     * @notice Performs a generic swap with permit
     * @param executor Address that will execute the swap
     * @param srcToken Source token address
     * @param dstToken Destination token address
     * @param srcReceiver Address that will receive source tokens
     * @param dstReceiver Address that will receive destination tokens
     * @param amount Amount of source tokens
     * @param minReturnAmount Minimum amount of destination tokens
     * @param flags Flags for special swap behaviors
     * @param permit Permit data for token approval
     * @param data Encoded routing data
     * @return returnAmount Amount of destination tokens received
     */
    function swapWithPermit(
        address executor,
        address srcToken,
        address dstToken,
        address payable srcReceiver,
        address payable dstReceiver,
        uint256 amount,
        uint256 minReturnAmount,
        uint256 flags,
        bytes calldata permit,
        bytes calldata data
    ) external payable returns (uint256 returnAmount);
}


