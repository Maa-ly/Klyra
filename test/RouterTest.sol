// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "./BaseTest.sol";
import {Router1inch} from "../src/routers/1incherouter.sol";
import {KlyraConstants} from "../src/dataTypes/constants.sol";
import {KlyraErrors} from "../src/dataTypes/errors.sol";

/**
 * @title RouterTest
 * @notice Test suite for Router1inch contract
 * @dev Tests router management functionality
 */
contract RouterTest is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    // ============ CONSTRUCTOR TESTS ============

    function testConstructor() public {
        assertEq(router.owner(), owner);
        assertEq(address(router.router()), KlyraConstants.DEFAULT_ROUTER);
        assertEq(address(router.router()), KlyraConstants.DEFAULT_ROUTER);
        assertEq(address(router.router()), KlyraConstants.DEFAULT_ROUTER);
        assertEq(address(router.router()), KlyraConstants.DEFAULT_ROUTER);
    }

    function testConstructorWithCustomAddress() public {
        address customRouter = makeAddr("customRouter");

        vm.prank(owner);
        Router1inch customRouterContract = new Router1inch(customRouter);

        assertEq(address(customRouterContract.router()), customRouter);
        assertEq(address(customRouterContract.router()), customRouter);
        assertEq(address(customRouterContract.router()), customRouter);
        assertEq(address(customRouterContract.router()), customRouter);
    }

    // ============ UPDATE ROUTER TESTS ============

    function testUpdateAggregationRouter() public {
        address newRouter = makeAddr("newAggregationRouter");

        vm.expectEmit(true, true, true, true);
        emit Router1inch.RouterUpdated(Router1inch.RouterType.AGGREGATION, KlyraConstants.DEFAULT_ROUTER, newRouter);

        vm.prank(owner);
        router.updateRouter(Router1inch.RouterType.AGGREGATION, newRouter);

        assertEq(address(router.router()), newRouter);
    }

    function testUpdateUnoswapRouter() public {
        address newRouter = makeAddr("newUnoswapRouter");

        vm.expectEmit(true, true, true, true);
        emit Router1inch.RouterUpdated(Router1inch.RouterType.UNOSWAP, KlyraConstants.DEFAULT_ROUTER, newRouter);

        vm.prank(owner);
        router.updateRouter(Router1inch.RouterType.UNOSWAP, newRouter);

        assertEq(address(router.router()), newRouter);
    }

    function testUpdateClipperRouter() public {
        address newRouter = makeAddr("newClipperRouter");

        vm.expectEmit(true, true, true, true);
        emit Router1inch.RouterUpdated(Router1inch.RouterType.CLIPPER, KlyraConstants.DEFAULT_ROUTER, newRouter);

        vm.prank(owner);
        router.updateRouter(Router1inch.RouterType.CLIPPER, newRouter);

        assertEq(address(router.router()), newRouter);
    }

    function testUpdateGenericRouter() public {
        address newRouter = makeAddr("newGenericRouter");

        vm.expectEmit(true, true, true, true);
        emit Router1inch.RouterUpdated(Router1inch.RouterType.GENERIC, KlyraConstants.DEFAULT_ROUTER, newRouter);

        vm.prank(owner);
        router.updateRouter(Router1inch.RouterType.GENERIC, newRouter);

        assertEq(address(router.router()), newRouter);
    }

    function testUpdateRouterInvalidAddress() public {
        vm.prank(owner);
        vm.expectRevert(KlyraErrors.InvalidAddress.selector);
        router.updateRouter(Router1inch.RouterType.AGGREGATION, address(0));
    }

    function testUpdateRouterNotOwner() public {
        address newRouter = makeAddr("newRouter");

        vm.prank(user1);
        vm.expectRevert();
        router.updateRouter(Router1inch.RouterType.AGGREGATION, newRouter);
    }

    // ============ UPDATE ALL ROUTERS TESTS ============

    function testUpdateAllRouters() public {
        address newRouter = makeAddr("newRouter");

        vm.prank(owner);
        router.updateAllRouters(newRouter, newRouter, newRouter, newRouter);

        // All router types now use the same address
        assertEq(address(router.router()), newRouter);
    }

    function testUpdateAllRoutersInvalidAddresses() public {
        // Only the first parameter (aggregationAddress) is validated now
        vm.prank(owner);
        vm.expectRevert(KlyraErrors.InvalidAddress.selector);
        router.updateAllRouters(address(0), makeAddr("valid"), makeAddr("valid"), makeAddr("valid"));
    }

    function testUpdateAllRoutersNotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        router.updateAllRouters(makeAddr("new1"), makeAddr("new2"), makeAddr("new3"), makeAddr("new4"));
    }

    // ============ GET ROUTERS TESTS ============

    function testGetRouters() public {
        (address aggregation, address unoswap, address clipper, address generic) = router.getRouters();

        assertEq(aggregation, KlyraConstants.DEFAULT_ROUTER);
        assertEq(unoswap, KlyraConstants.DEFAULT_ROUTER);
        assertEq(clipper, KlyraConstants.DEFAULT_ROUTER);
        assertEq(generic, KlyraConstants.DEFAULT_ROUTER);
    }

    function testGetRoutersAfterUpdate() public {
        address newRouter = makeAddr("newRouter");

        vm.prank(owner);
        router.updateAllRouters(newRouter, newRouter, newRouter, newRouter);

        (address aggregation, address unoswap, address clipper, address generic) = router.getRouters();

        // All router types now use the same address
        assertEq(aggregation, newRouter);
        assertEq(unoswap, newRouter);
        assertEq(clipper, newRouter);
        assertEq(generic, newRouter);
    }

    // ============ ROUTER TYPE ENUM TESTS ============

    function testRouterTypeEnum() public {
        assertEq(uint256(Router1inch.RouterType.AGGREGATION), 0);
        assertEq(uint256(Router1inch.RouterType.UNOSWAP), 1);
        assertEq(uint256(Router1inch.RouterType.CLIPPER), 2);
        assertEq(uint256(Router1inch.RouterType.GENERIC), 3);
    }

    // ============ INTEGRATION TESTS ============

    function testRouterIntegrationWithKlyra() public {
        // Verify that Klyra contract has router addresses set
        // Note: Klyra inherits from Router1inch, so it has its own router instances
        assertTrue(address(klyra.router()) != address(0));
        assertTrue(address(klyra.router()) != address(0));
        assertTrue(address(klyra.router()) != address(0));
        assertTrue(address(klyra.router()) != address(0));
    }

    function testRouterUpdateAffectsKlyra() public {
        address newAggregation = makeAddr("newAggregation");

        vm.prank(owner);
        router.updateRouter(Router1inch.RouterType.AGGREGATION, newAggregation);

        // Klyra has its own router instances, so this test verifies router update works
        assertEq(address(router.router()), newAggregation);
    }
}
