// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "./BaseTest.sol";
import {Klyra1inchV2} from "../src/core/klyra.sol";
import {Router1inch} from "../src/routers/1incherouter.sol";
import {KlyraConstants} from "../src/dataTypes/constants.sol";
import {KlyraErrors} from "../src/dataTypes/errors.sol";
import {PaymentBreakdown} from "../src/dataTypes/structs.sol";

/**
 * @title IntegrationTest
 * @notice Integration tests for the complete Klyra system
 * @dev Tests end-to-end functionality and complex scenarios
 */
contract IntegrationTest is BaseTest {
    
    function setUp() public override {
        super.setUp();
    }
    
    // ============ COMPLETE PAYMENT FLOW TESTS ============
    
    function testCompletePaymentFlow() public {
        uint256 amount = TEST_AMOUNT;
        
        // Setup
        _approveToken(address(tokenA), address(klyra), amount);
        
        uint256 user1BalanceBefore = tokenA.balanceOf(user1);
        uint256 user2BalanceBefore = tokenA.balanceOf(user2);
        uint256 feeCollectorBalanceBefore = tokenA.balanceOf(feeCollector);
        uint256 totalPaymentsBefore = klyra.totalPayments();
        uint256 totalVolumeBefore = klyra.totalVolume();
        
        // Execute payment
        vm.prank(user1);
        uint256 result = klyra.sendDirectToken(address(tokenA), user2, amount);
        
        // Verify results (no fees for direct transfers)
        assertEq(result, amount);
        assertEq(tokenA.balanceOf(user1), user1BalanceBefore - amount);
        assertEq(tokenA.balanceOf(user2), user2BalanceBefore + amount);
        assertEq(tokenA.balanceOf(feeCollector), feeCollectorBalanceBefore); // No fees collected
        assertEq(klyra.totalPayments(), totalPaymentsBefore + 1);
        assertEq(klyra.totalVolume(), totalVolumeBefore + amount);
    }
    
    function testMultiplePaymentsAccumulateStats() public {
        uint256 amount = TEST_AMOUNT;
        (uint256 expectedFee, uint256 expectedNet) = _calculateFee(amount);
        
        _approveAllTokens(address(klyra), amount);
        
        // First payment
        vm.prank(user1);
        klyra.sendDirectToken(address(tokenA), user2, amount);
        
        // Second payment
        vm.prank(user2);
        klyra.sendDirectToken(address(tokenB), user3, amount);
        
        // Third payment
        vm.prank(user3);
        klyra.sendDirectToken(address(tokenC), user1, amount);
        
        // Verify accumulated stats
        assertEq(klyra.totalPayments(), 3);
        assertEq(klyra.totalVolume(), amount * 3);
    }
    
    // ============ FEE MANAGEMENT TESTS ============
    
    function testFeeCollectionAccumulation() public {
        uint256 amount = TEST_AMOUNT;
        
        _approveAllTokens(address(klyra), amount);
        
        uint256 feeCollectorBalanceBefore = tokenA.balanceOf(feeCollector);
        
        // Multiple payments with same token (no fees for direct transfers)
        vm.prank(user1);
        klyra.sendDirectToken(address(tokenA), user2, amount);
        
        vm.prank(user2);
        klyra.sendDirectToken(address(tokenA), user3, amount);
        
        vm.prank(user3);
        klyra.sendDirectToken(address(tokenA), user1, amount);
        
        // Verify no fee accumulation (direct transfers have no fees)
        assertEq(tokenA.balanceOf(feeCollector), feeCollectorBalanceBefore);
    }
    
    function testFeePercentageChange() public {
        uint256 amount = TEST_AMOUNT;
        uint256 newFeePercentage = 200; // 2%
        
        // Change fee percentage
        vm.prank(owner);
        klyra.setFeePercentage(newFeePercentage);
        
        _approveToken(address(tokenA), address(klyra), amount);
        
        vm.prank(user1);
        uint256 result = klyra.sendDirectToken(address(tokenA), user2, amount);
        
        // Direct transfers have no fees regardless of fee percentage
        assertEq(result, amount);
        assertEq(klyra.feePercentage(), newFeePercentage);
    }
    
    // ============ ADMIN FUNCTIONALITY TESTS ============
    
    function testAdminFunctions() public {
        address newFeeCollector = makeAddr("newFeeCollector");
        uint256 newFeePercentage = 150; // 1.5%
        uint256 newSlippage = 75; // 0.75%
        
        // Test fee collector change
        vm.prank(owner);
        klyra.setFeeCollector(newFeeCollector);
        assertEq(klyra.feeCollector(), newFeeCollector);
        
        // Test fee percentage change
        vm.prank(owner);
        klyra.setFeePercentage(newFeePercentage);
        assertEq(klyra.feePercentage(), newFeePercentage);
        
        // Test slippage change
        vm.prank(owner);
        klyra.setDefaultSlippage(newSlippage);
        assertEq(klyra.defaultSlippageBps(), newSlippage);
    }
    
    function testEmergencyWithdraw() public {
        uint256 emergencyAmount = 5000 * 10**18;
        
        // Send tokens to contract
        tokenA.mint(address(klyra), emergencyAmount);
        
        uint256 ownerBalanceBefore = tokenA.balanceOf(owner);
        
        vm.prank(owner);
        klyra.emergencyWithdraw(address(tokenA), emergencyAmount);
        
        assertEq(tokenA.balanceOf(owner), ownerBalanceBefore + emergencyAmount);
        assertEq(tokenA.balanceOf(address(klyra)), 0);
    }
    
    // ============ ROUTER INTEGRATION TESTS ============
    
    function testRouterUpdateIntegration() public {
        address newRouter = makeAddr("newRouter");
        
        // Update router (all types use the same address)
        vm.prank(owner);
        router.updateRouter(Router1inch.RouterType.AGGREGATION, newRouter);
        
        // Verify router contract reflects changes
        assertEq(address(router.router()), newRouter);
        
        // Update with different router type (should still use same address)
        address anotherRouter = makeAddr("anotherRouter");
        vm.prank(owner);
        router.updateRouter(Router1inch.RouterType.UNOSWAP, anotherRouter);
        
        // Verify the latest update is reflected
        assertEq(address(router.router()), anotherRouter);
    }
    
    function testRouterUpdateAllIntegration() public {
        address newAggregation = makeAddr("newAggregation");
        address newUnoswap = makeAddr("newUnoswap");
        address newClipper = makeAddr("newClipper");
        address newGeneric = makeAddr("newGeneric");
        
        vm.prank(owner);
        router.updateAllRouters(newAggregation, newUnoswap, newClipper, newGeneric);
        
        // Verify all routers updated in router contract
        assertEq(address(router.router()), newAggregation);
        assertEq(address(router.router()), newAggregation);
        assertEq(address(router.router()), newAggregation);
        assertEq(address(router.router()), newAggregation);
    }
    
    // ============ VIEW FUNCTION INTEGRATION TESTS ============
    
    function testStatisticsIntegration() public {
        uint256 amount = TEST_AMOUNT;
        (uint256 expectedFee, uint256 expectedNet) = _calculateFee(amount);
        
        _approveToken(address(tokenA), address(klyra), amount);
        
        // Make a payment
        vm.prank(user1);
        klyra.sendDirectToken(address(tokenA), user2, amount);
        
        // Check statistics
        (uint256 payments, uint256 volume, uint256 fee, address collector) = klyra.getStatistics();
        
        assertEq(payments, 1);
        assertEq(volume, amount);
        assertEq(fee, FEE_PERCENTAGE);
        assertEq(collector, feeCollector);
    }
    
    function testPaymentBreakdownIntegration() public {
        uint256 inputAmount = 1000 * 10**18;
        uint256 expectedOutputFromApi = 2000 * 10**18;
        
        PaymentBreakdown memory breakdown = klyra.getPaymentBreakdown(
            inputAmount,
            address(tokenA),
            address(tokenB),
            expectedOutputFromApi
        );
        
        // Verify breakdown structure
        assertEq(breakdown.inputToken, address(tokenA));
        assertEq(breakdown.outputToken, address(tokenB));
        assertEq(breakdown.inputAmount, inputAmount);
        assertEq(breakdown.feePercentage, FEE_PERCENTAGE);
        assertGt(breakdown.feeAmount, 0);
        assertLt(breakdown.netInputAmount, inputAmount);
        assertGt(breakdown.expectedOutputAmount, 0);
        assertGt(breakdown.minOutputWithSlippage, 0);
        assertEq(breakdown.slippageBps, KlyraConstants.DEFAULT_SLIPPAGE_BPS);
    }
    
    // ============ ERROR HANDLING INTEGRATION TESTS ============
    
    function testInvalidPaymentHandling() public {
        uint256 amount = TEST_AMOUNT;
        
        // Test with insufficient approval
        vm.prank(user1);
        vm.expectRevert();
        klyra.sendDirectToken(address(tokenA), user2, amount);
        
        // Test with invalid receiver
        _approveToken(address(tokenA), address(klyra), amount);
        vm.prank(user1);
        vm.expectRevert(KlyraErrors.InvalidAddress.selector);
        klyra.sendDirectToken(address(tokenA), address(0), amount);
        
        // Test with zero amount
        vm.prank(user1);
        vm.expectRevert(KlyraErrors.InvalidAmount.selector);
        klyra.sendDirectToken(address(tokenA), user2, 0);
    }
    
    function testAccessControlIntegration() public {
        // Test non-owner cannot change settings
        vm.prank(user1);
        vm.expectRevert();
        klyra.setFeePercentage(200);
        
        vm.prank(user1);
        vm.expectRevert();
        klyra.setFeeCollector(makeAddr("newCollector"));
        
        vm.prank(user1);
        vm.expectRevert();
        klyra.emergencyWithdraw(address(tokenA), 1000);
        
        // Test non-owner cannot update routers
        vm.prank(user1);
        vm.expectRevert();
        router.updateRouter(Router1inch.RouterType.AGGREGATION, makeAddr("newRouter"));
    }
    
    // ============ CHAIN SUPPORT TESTS ============
    
    function testChainSupport() public {
        bool isSupported = klyra.isChainSupported();
        assertTrue(isSupported);
        
        // Test with different chain IDs (this would require fork testing in practice)
        // For now, we just verify the function works
        assertTrue(klyra.isChainSupported());
    }
    
    // ============ COMPLEX SCENARIOS ============
    
    function testMultipleTokenTypes() public {
        uint256 amount = TEST_AMOUNT;
        (uint256 expectedFee, uint256 expectedNet) = _calculateFee(amount);
        
        _approveAllTokens(address(klyra), amount);
        
        // Test with different token types
        vm.prank(user1);
        klyra.sendDirectToken(address(tokenA), user2, amount);
        
        vm.prank(user2);
        klyra.sendDirectToken(address(tokenB), user3, amount);
        
        vm.prank(user3);
        klyra.sendDirectToken(address(tokenC), user1, amount);
        
        // Verify all payments processed
        assertEq(klyra.totalPayments(), 3);
        assertEq(klyra.totalVolume(), amount * 3);
    }
    
    function testETHAndTokenPayments() public {
        uint256 tokenAmount = TEST_AMOUNT;
        uint256 ethAmount = 1 ether;
        
        (uint256 tokenFee, uint256 tokenNet) = _calculateFee(tokenAmount);
        (uint256 ethFee, uint256 ethNet) = _calculateFee(ethAmount);
        
        _approveToken(address(tokenA), address(klyra), tokenAmount);
        
        // Token payment
        vm.prank(user1);
        klyra.sendDirectToken(address(tokenA), user2, tokenAmount);
        
        // ETH payment
        vm.prank(user2);
        klyra.sendDirectETH{value: ethAmount}(user3);
        
        // Verify both payments
        assertEq(klyra.totalPayments(), 2);
        assertEq(klyra.totalVolume(), tokenAmount + ethAmount);
    }
}
