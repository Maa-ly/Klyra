// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title IAggregationRouterV6
 * @notice Interface for 1inch Aggregation Router V6
 * @dev This is the main router that aggregates liquidity from multiple DEXs
 */
interface IAggregationRouterV6 {
    struct SwapDescription {
        address srcToken;
        address dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    /**
     * @notice Performs a swap using the aggregation protocol
     * @param executor Address that will execute the swap
     * @param desc Swap description
     * @param permit Permit data for token approval (can be empty)
     * @param data Encoded swap data
     * @return returnAmount Amount of destination tokens received
     * @return spentAmount Amount of source tokens spent
     */
    function swap(
        address executor,
        SwapDescription calldata desc,
        bytes calldata permit,
        bytes calldata data
    ) external payable returns (uint256 returnAmount, uint256 spentAmount);

    /**
     * @notice Performs an optimized unswap (direct swap without aggregation)
     * @param srcToken Source token address
     * @param amount Amount of source tokens
     * @param minReturn Minimum amount of destination tokens
     * @param dex DEX identifier
     * @return returnAmount Amount of destination tokens received
     */
    function unoswap(
        address srcToken,
        uint256 amount,
        uint256 minReturn,
        uint256 dex
    ) external payable returns (uint256 returnAmount);

    /**
     * @notice Performs an optimized unswap with intermediate token
     * @param srcToken Source token address
     * @param amount Amount of source tokens
     * @param minReturn Minimum amount of destination tokens
     * @param dex First DEX identifier
     * @param dex2 Second DEX identifier
     * @return returnAmount Amount of destination tokens received
     */
    function unoswap2(
        address srcToken,
        uint256 amount,
        uint256 minReturn,
        uint256 dex,
        uint256 dex2
    ) external payable returns (uint256 returnAmount);

    /**
     * @notice Performs an optimized unswap with two intermediate tokens
     * @param srcToken Source token address
     * @param amount Amount of source tokens
     * @param minReturn Minimum amount of destination tokens
     * @param dex First DEX identifier
     * @param dex2 Second DEX identifier
     * @param dex3 Third DEX identifier
     * @return returnAmount Amount of destination tokens received
     */
    function unoswap3(
        address srcToken,
        uint256 amount,
        uint256 minReturn,
        uint256 dex,
        uint256 dex2,
        uint256 dex3
    ) external payable returns (uint256 returnAmount);

    /**
     * @notice Rescues stuck tokens from the contract
     * @param token Token address to rescue
     * @param amount Amount to rescue
     */
    function rescueFunds(address token, uint256 amount) external;

    /**
     * @notice Destroys the contract and sends funds to owner
     */
    function destroy() external;
}


