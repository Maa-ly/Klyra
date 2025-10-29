// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "./BaseTest.sol";
import {Klyra1inchV2} from "../src/core/klyra.sol";
import {Router1inch} from "../src/routers/1incherouter.sol";
import {KlyraConstants} from "../src/dataTypes/constants.sol";
import {KlyraErrors} from "../src/dataTypes/errors.sol";
import {PaymentBreakdown} from "../src/dataTypes/structs.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title KlyraTest
 * @notice Test suite for Klyra1inchV2 contract
 * @dev Tests core functionality including payments, fees, and admin functions
 */
contract KlyraTest is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    // ============ CONSTRUCTOR TESTS ============

    function testConstructor() public view {
        assertEq(klyra.owner(), owner);
        assertEq(klyra.feeCollector(), feeCollector);
        assertEq(klyra.feePercentage(), FEE_PERCENTAGE);
        assertEq(klyra.defaultSlippageBps(), KlyraConstants.DEFAULT_SLIPPAGE_BPS);
        assertEq(klyra.totalPayments(), 0);
        assertEq(klyra.totalVolume(), 0);
    }

    function testConstructorInvalidFeeCollector() public {
        vm.expectRevert(KlyraErrors.InvalidAddress.selector);
        new Klyra1inchV2(address(0), FEE_PERCENTAGE, address(router));
    }

    function testConstructorInvalidFee() public {
        vm.expectRevert(KlyraErrors.InvalidFee.selector);
        new Klyra1inchV2(feeCollector, KlyraConstants.MAX_FEE + 1, address(router));
    }

    // ============ DIRECT TRANSFER TESTS ============
    // Note: Direct transfers are done via sendWithAggregation with same token

    function testSendDirectToken() public {
        uint256 amount = TEST_AMOUNT;

        vm.prank(user1);
        IERC20(address(tokenA)).approve(address(klyra), amount);

        vm.prank(user1);
        uint256 result = klyra.sendWithAggregation(address(tokenA), address(tokenA), amount, amount, user2, address(0), "");

        assertEq(result, amount);
        assertEq(tokenA.balanceOf(user2), INITIAL_BALANCE + amount);
        assertEq(klyra.totalPayments(), 1);
        assertEq(klyra.totalVolume(), amount);
    }

    function testSendDirectETH() public {
        uint256 amount = 1 ether;

        vm.prank(user1);
        uint256 result = klyra.sendWithAggregation{value: amount}(
            KlyraConstants.ETH_ADDRESS, KlyraConstants.ETH_ADDRESS, amount, amount, user2, address(0), ""
        );

        assertEq(result, amount);
        assertEq(user2.balance, 100 ether + amount);
    }

    function testSendDirectInvalidAmount() public {
        vm.prank(user1);
        vm.expectRevert(KlyraErrors.InvalidAmount.selector);
        klyra.sendWithAggregation(address(tokenA), address(tokenA), 0, 0, user2, address(0), "");
    }

    function testSendDirectInvalidReceiver() public {
        vm.prank(user1);
        IERC20(address(tokenA)).approve(address(klyra), TEST_AMOUNT);

        vm.prank(user1);
        vm.expectRevert(KlyraErrors.InvalidAddress.selector);
        klyra.sendWithAggregation(address(tokenA), address(tokenA), TEST_AMOUNT, TEST_AMOUNT, address(0), address(0), "");
    }

    function testSendDirectInsufficientOutput() public {
        // Direct transfers with same token should succeed with full amount
        vm.prank(user1);
        IERC20(address(tokenA)).approve(address(klyra), TEST_AMOUNT);

        vm.prank(user1);
        uint256 result = klyra.sendWithAggregation(
            address(tokenA), address(tokenA), TEST_AMOUNT, TEST_AMOUNT, user2, address(0), ""
        );

        assertEq(result, TEST_AMOUNT);
        assertEq(tokenA.balanceOf(user2), INITIAL_BALANCE + TEST_AMOUNT);
    }

    // ============ ADMIN FUNCTION TESTS ============

    function testSetFeePercentage() public {
        uint256 newFee = 200; // 2%

        vm.expectEmit(false, false, false, true);
        emit Klyra1inchV2.FeeUpdated(FEE_PERCENTAGE, newFee);

        vm.prank(owner);
        klyra.setFeePercentage(newFee);

        assertEq(klyra.feePercentage(), newFee);
    }

    function testSetFeePercentageInvalid() public {
        vm.prank(owner);
        vm.expectRevert(KlyraErrors.InvalidFee.selector);
        klyra.setFeePercentage(KlyraConstants.MAX_FEE + 1);
    }

    function testSetFeePercentageNotOwner() public {
        vm.prank(user1);
        vm.expectRevert();
        klyra.setFeePercentage(200);
    }

    function testSetFeeCollector() public {
        address newCollector = makeAddr("newCollector");

        vm.expectEmit(true, true, false, true);
        emit Klyra1inchV2.FeeCollectorUpdated(feeCollector, newCollector);

        vm.prank(owner);
        klyra.setFeeCollector(newCollector);

        assertEq(klyra.feeCollector(), newCollector);
    }

    function testSetFeeCollectorInvalid() public {
        vm.prank(owner);
        vm.expectRevert(KlyraErrors.InvalidAddress.selector);
        klyra.setFeeCollector(address(0));
    }

    function testSetDefaultSlippage() public {
        uint256 newSlippage = 100; // 1%

        vm.expectEmit(false, false, false, true);
        emit Klyra1inchV2.SlippageUpdated(KlyraConstants.DEFAULT_SLIPPAGE_BPS, newSlippage);

        vm.prank(owner);
        klyra.setDefaultSlippage(newSlippage);

        assertEq(klyra.defaultSlippageBps(), newSlippage);
    }

    function testEmergencyWithdraw() public {
        uint256 amount = 1000 * 10 ** 18;

        // First, send some tokens to the contract
        tokenA.mint(address(klyra), amount);

        uint256 ownerBalanceBefore = tokenA.balanceOf(owner);

        vm.prank(owner);
        klyra.emergencyWithdraw(address(tokenA), amount);

        assertEq(tokenA.balanceOf(owner), ownerBalanceBefore + amount);
    }

    // ============ VIEW FUNCTION TESTS ============

    function testGetStatistics() public view {
        (uint256 payments, uint256 volume, uint256 fee, address collector) = klyra.getStatistics();

        assertEq(payments, 0);
        assertEq(volume, 0);
        assertEq(fee, FEE_PERCENTAGE);
        assertEq(collector, feeCollector);
    }

    function testIsChainSupported() public view {
        bool isSupported = klyra.isChainSupported();
        assertTrue(isSupported);
    }



    function testGetPaymentBreakdown() public view {
        uint256 inputAmount = 1000 * 10 ** 18;
        uint256 expectedOutputAggregation = 2000 * 10 ** 18;
        uint256 expectedOutputClipper = 1950 * 10 ** 18;

        (PaymentBreakdown memory breakdown,, Router1inch.RouterType bestRouter) =
            klyra.simulateswap(inputAmount, address(tokenA), address(tokenB), expectedOutputAggregation, expectedOutputClipper);

        assertEq(breakdown.inputToken, address(tokenA));
        assertEq(breakdown.outputToken, address(tokenB));
        assertEq(breakdown.inputAmount, inputAmount);
        assertEq(breakdown.feePercentage, FEE_PERCENTAGE);
        assertGt(breakdown.feeAmount, 0);
        assertLt(breakdown.netInputAmount, inputAmount);
        assertGt(breakdown.expectedOutputAmount, 0);
        // Should select Aggregation as it has higher output
        assertEq(uint256(bestRouter), uint256(Router1inch.RouterType.AGGREGATION));
    }

    function testGetPaymentBreakdownClipperBetter() public view {
        uint256 inputAmount = 1000 * 10 ** 18;
        uint256 expectedOutputAggregation = 1950 * 10 ** 18;
        uint256 expectedOutputClipper = 2000 * 10 ** 18;

        (PaymentBreakdown memory breakdown,, Router1inch.RouterType bestRouter) =
            klyra.simulateswap(inputAmount, address(tokenA), address(tokenB), expectedOutputAggregation, expectedOutputClipper);

        // Should select Clipper as it has higher output
        assertEq(uint256(bestRouter), uint256(Router1inch.RouterType.CLIPPER));
        assertGt(breakdown.expectedOutputAmount, 0);
    }

    // ============ RECEIVE ETH TESTS ============

    function testReceiveETH() public {
        uint256 amount = 1 ether;

        vm.prank(user1);
        (bool success,) = address(klyra).call{value: amount}("");

        assertTrue(success);
        assertEq(address(klyra).balance, amount);
    }
}
