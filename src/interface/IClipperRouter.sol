// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title IClipperRouter
 * @notice Interface for 1inch Clipper Router
 * @dev Clipper is optimized for retail traders with better prices for smaller trades
 */
interface IClipperRouter {
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

    /**
     * @notice Performs a swap through Clipper exchange to a specific receiver
     * @param clipperExchange Address of Clipper exchange
     * @param recipient Address that will receive the destination tokens
     * @param srcToken Source token address
     * @param dstToken Destination token address
     * @param inputAmount Amount of source tokens
     * @param outputAmount Expected amount of destination tokens
     * @param goodUntil Timestamp until which the swap is valid
     * @param r Signature parameter r
     * @param vs Signature parameters v and s combined
     * @return returnAmount Amount of destination tokens received
     */
    function clipperSwapTo(
        address clipperExchange,
        address payable recipient,
        address srcToken,
        address dstToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 goodUntil,
        bytes32 r,
        bytes32 vs
    ) external payable returns (uint256 returnAmount);

    /**
     * @notice Performs a swap through Clipper exchange with permit
     * @param clipperExchange Address of Clipper exchange
     * @param srcToken Source token address
     * @param dstToken Destination token address
     * @param inputAmount Amount of source tokens
     * @param outputAmount Expected amount of destination tokens
     * @param goodUntil Timestamp until which the swap is valid
     * @param r Signature parameter r
     * @param vs Signature parameters v and s combined
     * @param permit Permit data for token approval
     * @return returnAmount Amount of destination tokens received
     */
    function clipperSwapToWithPermit(
        address clipperExchange,
        address payable recipient,
        address srcToken,
        address dstToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 goodUntil,
        bytes32 r,
        bytes32 vs,
        bytes calldata permit
    ) external returns (uint256 returnAmount);
}


