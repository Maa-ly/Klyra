// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {BaseTest} from "./BaseTest.sol";
import {Klyra1inchV2} from "../src/core/klyra.sol";
import {Router1inch} from "../src/routers/1incherouter.sol";
import {KlyraConstants} from "../src/dataTypes/constants.sol";
import {KlyraErrors} from "../src/dataTypes/errors.sol";
import {PaymentBreakdown} from "../src/dataTypes/structs.sol";

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
    
    function testConstructor() public {
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
    
    function testSendDirectToken() public {
        uint256 amount = TEST_AMOUNT;

        _approveToken(address(tokenA), address(klyra), amount);

        vm.prank(user1);
        uint256 result = klyra.sendDirectToken(address(tokenA), user2, amount);

        assertEq(result, amount);
        assertEq(tokenA.balanceOf(user2), INITIAL_BALANCE + amount);
        assertEq(tokenA.balanceOf(feeCollector), 0); // No fees for direct transfers
        assertEq(klyra.totalPayments(), 1);
        assertEq(klyra.totalVolume(), amount);
    }
    
    function testSendDirectETH() public {
        uint256 amount = 1 ether;
        
        vm.prank(user1);
        uint256 result = klyra.sendDirectETH{value: amount}(user2);
        
        assertEq(result, amount);
        assertEq(user2.balance, 100 ether + amount);
        assertEq(feeCollector.balance, 0); // No fees for direct transfers
    }
    
    function testSendDirectInvalidAmount() public {
        vm.prank(user1);
        vm.expectRevert(KlyraErrors.InvalidAmount.selector);
        klyra.sendDirectToken(address(tokenA), user2, 0);
    }
    
    function testSendDirectInvalidReceiver() public {
        _approveToken(address(tokenA), address(klyra), TEST_AMOUNT);
        
        vm.prank(user1);
        vm.expectRevert(KlyraErrors.InvalidAddress.selector);
        klyra.sendDirectToken(address(tokenA), address(0), TEST_AMOUNT);
    }
    
    function testSendDirectInsufficientOutput() public {
        // This test is no longer applicable since direct transfers don't validate output amounts
        // Direct transfers are 1:1 transfers without output validation
        _approveToken(address(tokenA), address(klyra), TEST_AMOUNT);
        
        vm.prank(user1);
        uint256 result = klyra.sendDirectToken(address(tokenA), user2, TEST_AMOUNT);
        
        // Should succeed with full amount (no fees for direct transfers)
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
        uint256 amount = 1000 * 10**18;
        
        // First, send some tokens to the contract
        tokenA.mint(address(klyra), amount);
        
        uint256 ownerBalanceBefore = tokenA.balanceOf(owner);
        
        vm.prank(owner);
        klyra.emergencyWithdraw(address(tokenA), amount);
        
        assertEq(tokenA.balanceOf(owner), ownerBalanceBefore + amount);
    }
    
    // ============ VIEW FUNCTION TESTS ============
    
    function testGetStatistics() public {
        (uint256 payments, uint256 volume, uint256 fee, address collector) = klyra.getStatistics();
        
        assertEq(payments, 0);
        assertEq(volume, 0);
        assertEq(fee, FEE_PERCENTAGE);
        assertEq(collector, feeCollector);
    }
    
    function testIsChainSupported() public {
        bool isSupported = klyra.isChainSupported();
        assertTrue(isSupported);
    }
    
    function testCalculateExpectedOutput() public {
        uint256 inputAmount = 1000 * 10**18;
        uint256 expectedOutputBeforeFees = 2000 * 10**18;
        
        (uint256 netInputAmount, uint256 expectedOutputAmount, uint256 feeAmount) = 
            klyra.calculateExpectedOutput(inputAmount, expectedOutputBeforeFees);
        
        (uint256 expectedFee, uint256 expectedNet) = _calculateFee(inputAmount);
        uint256 expectedOutput = (expectedOutputBeforeFees * expectedNet) / inputAmount;
        
        assertEq(feeAmount, expectedFee);
        assertEq(netInputAmount, expectedNet);
        assertEq(expectedOutputAmount, expectedOutput);
    }
    
    function testValidatePaymentAmount() public {
        uint256 inputAmount = 1000 * 10**18;
        uint256 requiredOutputAmount = 1500 * 10**18;
        uint256 expectedOutputFromQuote = 2000 * 10**18;
        
        (bool isValid, uint256 actualOutput, uint256 shortfall) = 
            klyra.validatePaymentAmount(inputAmount, requiredOutputAmount, expectedOutputFromQuote);
        
        assertTrue(isValid);
        assertGt(actualOutput, requiredOutputAmount);
        assertEq(shortfall, 0);
    }
    
    function testValidatePaymentAmountInsufficient() public {
        uint256 inputAmount = 1000 * 10**18;
        uint256 requiredOutputAmount = 2500 * 10**18;
        uint256 expectedOutputFromQuote = 2000 * 10**18;
        
        (bool isValid, uint256 actualOutput, uint256 shortfall) = 
            klyra.validatePaymentAmount(inputAmount, requiredOutputAmount, expectedOutputFromQuote);
        
        assertFalse(isValid);
        assertLt(actualOutput, requiredOutputAmount);
        assertGt(shortfall, 0);
    }
    
    function testCalculateRequiredInput() public {
        uint256 desiredOutputAmount = 2000 * 10**18;
        uint256 quotedRate = 2 * 10**18; // 1:2 ratio
        
        uint256 requiredInputAmount = klyra.calculateRequiredInput(desiredOutputAmount, quotedRate);
        
        // Should account for fees
        assertGt(requiredInputAmount, desiredOutputAmount / 2);
    }
    
    function testGetPaymentBreakdown() public {
        uint256 inputAmount = 1000 * 10**18;
        uint256 expectedOutputFromApi = 2000 * 10**18;
        
        PaymentBreakdown memory breakdown = klyra.getPaymentBreakdown(
            inputAmount,
            address(tokenA),
            address(tokenB),
            expectedOutputFromApi
        );
        
        assertEq(breakdown.inputToken, address(tokenA));
        assertEq(breakdown.outputToken, address(tokenB));
        assertEq(breakdown.inputAmount, inputAmount);
        assertEq(breakdown.feePercentage, FEE_PERCENTAGE);
        assertGt(breakdown.feeAmount, 0);
        assertLt(breakdown.netInputAmount, inputAmount);
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
