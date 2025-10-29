// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IUnifiedRouter} from "../interface/IUnifiedRouter.sol";
import {KlyraErrors} from "../dataTypes/errors.sol";
import {KlyraConstants} from "../dataTypes/constants.sol";

/**
 * @title Router1inch
 * @notice Manages 1inch router instances and configurations
 */
contract Router1inch is Ownable {
    // Router type enum
    enum RouterType {
        AGGREGATION,
        UNOSWAP,
        CLIPPER,
        GENERIC
    }

    // Router instance - all router types use the same address
    IUnifiedRouter public router;

    // Events
    event RouterUpdated(RouterType indexed routerType, address indexed oldRouter, address indexed newRouter);

    /**
     * @notice Constructor
     * @param _routerAddress 1inch router address (use 0x0 for default)
     * @dev All router types use the same address as 1inch handles all router functions in one contract
     */
    constructor(address _routerAddress) Ownable(msg.sender) {
        address routerAddress = _routerAddress == address(0) ? KlyraConstants.DEFAULT_ROUTER : _routerAddress;

        router = IUnifiedRouter(routerAddress);
    }

    /**
     * @notice Update a specific router
     */
    function updateRouter(RouterType routerType, address newRouter) external onlyOwner {
        // CHECKS: Validate input
        if (newRouter == address(0)) revert KlyraErrors.InvalidAddress();

        // EFFECTS: Store old router and update state
        address oldRouter = address(router);
        router = IUnifiedRouter(newRouter);

        // EFFECTS: Emit event
        emit RouterUpdated(routerType, oldRouter, newRouter);
    }

    /**
     * @notice Update the router address
     * @dev Since all router types use the same address, this updates all types
     */
    function updateAllRouters(
        address aggregationAddress,
        address, /* unoswapAddress */
        address, /* clipperAddress */
        address /* genericAddress */
    ) external onlyOwner {
        // CHECKS: Validate input
        if (aggregationAddress == address(0)) revert KlyraErrors.InvalidAddress();

        // EFFECTS: Store old router and update state
        address oldRouter = address(router);
        router = IUnifiedRouter(aggregationAddress);

        // EFFECTS: Emit events
        emit RouterUpdated(RouterType.AGGREGATION, oldRouter, aggregationAddress);
        emit RouterUpdated(RouterType.UNOSWAP, oldRouter, aggregationAddress);
        emit RouterUpdated(RouterType.CLIPPER, oldRouter, aggregationAddress);
        emit RouterUpdated(RouterType.GENERIC, oldRouter, aggregationAddress);
    }

    /**
     * @notice Get all router addresses
     */
    function getRouters()
        external
        view
        returns (address aggregation, address unoswap, address clipper, address generic)
    {
        return (address(router), address(router), address(router), address(router));
    }
}
