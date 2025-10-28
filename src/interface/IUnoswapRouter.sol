// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title IUnoswapRouter
 * @notice Interface for 1inch Unoswap Router
 * @dev Optimized for single-source swaps (e.g., only Uniswap or only Sushiswap)
 * Lower gas costs when you know the best route is through a single DEX
 */
interface IUnoswapRouter {
    /**
     * @notice Performs an optimized single-DEX swap
     * @param srcToken Source token address (use address(0) for ETH)
     * @param amount Amount of source tokens
     * @param minReturn Minimum amount of destination tokens
     * @param dex Encoded DEX identifier and pool data
     * @return returnAmount Amount of destination tokens received
     */
    function unoswap(address srcToken, uint256 amount, uint256 minReturn, uint256 dex)
        external
        payable
        returns (uint256 returnAmount);

    /**
     * @notice Performs an optimized swap with one intermediate token (2 hops)
     * @param srcToken Source token address (use address(0) for ETH)
     * @param amount Amount of source tokens
     * @param minReturn Minimum amount of destination tokens
     * @param dex First DEX identifier and pool data
     * @param dex2 Second DEX identifier and pool data
     * @return returnAmount Amount of destination tokens received
     */
    function unoswap2(address srcToken, uint256 amount, uint256 minReturn, uint256 dex, uint256 dex2)
        external
        payable
        returns (uint256 returnAmount);

    /**
     * @notice Performs an optimized swap with two intermediate tokens (3 hops)
     * @param srcToken Source token address (use address(0) for ETH)
     * @param amount Amount of source tokens
     * @param minReturn Minimum amount of destination tokens
     * @param dex First DEX identifier and pool data
     * @param dex2 Second DEX identifier and pool data
     * @param dex3 Third DEX identifier and pool data
     * @return returnAmount Amount of destination tokens received
     */
    function unoswap3(address srcToken, uint256 amount, uint256 minReturn, uint256 dex, uint256 dex2, uint256 dex3)
        external
        payable
        returns (uint256 returnAmount);

    /**
     * @notice Performs a swap to a specific receiver
     * @param srcToken Source token address
     * @param amount Amount of source tokens
     * @param minReturn Minimum amount of destination tokens
     * @param dex DEX identifier and pool data
     * @param recipient Address that will receive destination tokens
     * @return returnAmount Amount of destination tokens received
     */
    function unoswapTo(address srcToken, uint256 amount, uint256 minReturn, uint256 dex, address payable recipient)
        external
        payable
        returns (uint256 returnAmount);

    /**
     * @notice Performs a 2-hop swap to a specific receiver
     * @param srcToken Source token address
     * @param amount Amount of source tokens
     * @param minReturn Minimum amount of destination tokens
     * @param dex First DEX identifier and pool data
     * @param dex2 Second DEX identifier and pool data
     * @param recipient Address that will receive destination tokens
     * @return returnAmount Amount of destination tokens received
     */
    function unoswapTo2(
        address srcToken,
        uint256 amount,
        uint256 minReturn,
        uint256 dex,
        uint256 dex2,
        address payable recipient
    ) external payable returns (uint256 returnAmount);

    /**
     * @notice Performs a 3-hop swap to a specific receiver
     * @param srcToken Source token address
     * @param amount Amount of source tokens
     * @param minReturn Minimum amount of destination tokens
     * @param dex First DEX identifier and pool data
     * @param dex2 Second DEX identifier and pool data
     * @param dex3 Third DEX identifier and pool data
     * @param recipient Address that will receive destination tokens
     * @return returnAmount Amount of destination tokens received
     */
    function unoswapTo3(
        address srcToken,
        uint256 amount,
        uint256 minReturn,
        uint256 dex,
        uint256 dex2,
        uint256 dex3,
        address payable recipient
    ) external payable returns (uint256 returnAmount);
}
