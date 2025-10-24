// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title IUnifiedRouter
 * @notice Unified interface for 1inch Router
 * @dev All router types (aggregation, unoswap, clipper, generic) use the same contract address
 */
interface IUnifiedRouter {
    // ============ STRUCTS ============
    
    struct SwapDescription {
        address srcToken;
        address dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    // ============ AGGREGATION ROUTER FUNCTIONS ============
    
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

    // ============ UNOSWAP ROUTER FUNCTIONS ============
    
    /**
     * @notice Performs an optimized single-DEX swap
     * @param srcToken Source token address (use address(0) for ETH)
     * @param amount Amount of source tokens
     * @param minReturn Minimum amount of destination tokens
     * @param pools Array of pool data for the swap path
     * @return returnAmount Amount of destination tokens received
     */
    function unoswap(
        address srcToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools
    ) external payable returns (uint256 returnAmount);

    /**
     * @notice Performs an optimized swap with one intermediate token (2 hops)
     * @param srcToken Source token address (use address(0) for ETH)
     * @param amount Amount of source tokens
     * @param minReturn Minimum amount of destination tokens
     * @param pools Array of pool data for the swap path
     * @return returnAmount Amount of destination tokens received
     */
    function unoswapWithPools(
        address srcToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata pools
    ) external payable returns (uint256 returnAmount);

    // ============ CLIPPER ROUTER FUNCTIONS ============
    
    /**
     * @notice Performs a swap through Clipper exchange
     * @param clipperExchange Address of Clipper exchange
     * @param srcToken Source token address
     * @param dstToken Destination token address
     * @param inputAmount Amount of source tokens
     * @param outputAmount Expected amount of destination tokens
     * @param goodUntil Timestamp until which the swap is valid
     * @param r Signature parameter r
     * @param vs Signature parameters v and s combined
     * @return returnAmount Amount of destination tokens received
     */
    function clipperSwap(
        address clipperExchange,
        address srcToken,
        address dstToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 goodUntil,
        bytes32 r,
        bytes32 vs
    ) external payable returns (uint256 returnAmount);

    // ============ GENERIC ROUTER FUNCTIONS ============
    
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
}
