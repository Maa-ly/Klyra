// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {Klyra1inchV2} from "../src/core/klyra.sol";
import {Router1inch} from "../src/routers/1incherouter.sol";
import {KlyraConstants} from "../src/dataTypes/constants.sol";
import {KlyraErrors} from "../src/dataTypes/errors.sol";
import {PaymentBreakdown} from "../src/dataTypes/structs.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

/**
 * @title BaseTest
 * @notice Base test contract with common setup and utilities
 * @dev Provides shared test infrastructure for all Klyra tests
 */
abstract contract BaseTest is Test {
    // Test contracts
    Klyra1inchV2 public klyra;
    Router1inch public router;
    
    // Test accounts
    address public owner;
    address public feeCollector;
    address public user1;
    address public user2;
    address public user3;
    
    // Test tokens
    ERC20Mock public tokenA;
    ERC20Mock public tokenB;
    ERC20Mock public tokenC;
    
    // Test amounts
    uint256 public constant INITIAL_BALANCE = 1000000 * 10**18;
    uint256 public constant TEST_AMOUNT = 1000 * 10**18;
    uint256 public constant FEE_PERCENTAGE = 100; // 1%
    
    // Events for testing
    event PaymentExecuted(
        address indexed sender,
        address indexed receiver,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        Router1inch.RouterType routerType,
        uint256 feeAmount
    );
    
    event DirectTransfer(
        address indexed sender,
        address indexed receiver,
        address token,
        uint256 amount
    );
    
    event FeeCollected(address indexed collector, address token, uint256 amount);
    
    /**
     * @notice Set up test environment
     */
    function setUp() public virtual {
        // Set up test environment with supported chain ID
        vm.chainId(KlyraConstants.ETHEREUM_CHAIN_ID);
        
        // Create test accounts
        owner = makeAddr("owner");
        feeCollector = makeAddr("feeCollector");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        
        // Deploy test tokens
        tokenA = new ERC20Mock();
        tokenB = new ERC20Mock();
        tokenC = new ERC20Mock();
        
        // Deploy router
        vm.prank(owner);
        router = new Router1inch(address(0)); // Use default router address
        
        // Deploy Klyra contract
        vm.prank(owner);
        klyra = new Klyra1inchV2(
            feeCollector,
            FEE_PERCENTAGE,
            address(router)
        );
        
        // Set up initial balances
        _setupInitialBalances();
    }
    
    /**
     * @notice Set up initial token balances for test accounts
     */
    function _setupInitialBalances() internal {
        // Mint tokens to users
        tokenA.mint(user1, INITIAL_BALANCE);
        tokenA.mint(user2, INITIAL_BALANCE);
        tokenA.mint(user3, INITIAL_BALANCE);
        
        tokenB.mint(user1, INITIAL_BALANCE);
        tokenB.mint(user2, INITIAL_BALANCE);
        tokenB.mint(user3, INITIAL_BALANCE);
        
        tokenC.mint(user1, INITIAL_BALANCE);
        tokenC.mint(user2, INITIAL_BALANCE);
        tokenC.mint(user3, INITIAL_BALANCE);
        
        // Give users some ETH
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(user3, 100 ether);
    }
    
    /**
     * @notice Helper to approve token spending
     */
    function _approveToken(address token, address spender, uint256 amount) internal {
        vm.prank(user1);
        IERC20(token).approve(spender, amount);
        
        vm.prank(user2);
        IERC20(token).approve(spender, amount);
        
        vm.prank(user3);
        IERC20(token).approve(spender, amount);
    }
    
    /**
     * @notice Helper to approve all tokens for a spender
     */
    function _approveAllTokens(address spender, uint256 amount) internal {
        _approveToken(address(tokenA), spender, amount);
        _approveToken(address(tokenB), spender, amount);
        _approveToken(address(tokenC), spender, amount);
    }
    
    /**
     * @notice Helper to get token balance
     */
    function _getBalance(address token, address account) internal view returns (uint256) {
        if (token == KlyraConstants.ETH_ADDRESS) {
            return account.balance;
        } else {
            return IERC20(token).balanceOf(account);
        }
    }
    
    /**
     * @notice Helper to transfer tokens
     */
    function _transferToken(address token, address to, uint256 amount) internal {
        if (token == KlyraConstants.ETH_ADDRESS) {
            vm.deal(to, to.balance + amount);
        } else {
            IERC20(token).transfer(to, amount);
        }
    }
    
    /**
     * @notice Helper to expect payment executed event
     */
    function _expectPaymentExecuted(
        address sender,
        address receiver,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        Router1inch.RouterType routerType,
        uint256 feeAmount
    ) internal {
        vm.expectEmit(true, true, false, true);
        emit PaymentExecuted(sender, receiver, inputToken, outputToken, inputAmount, outputAmount, routerType, feeAmount);
    }
    
    /**
     * @notice Helper to expect direct transfer event
     */
    function _expectDirectTransfer(
        address sender,
        address receiver,
        address token,
        uint256 amount
    ) internal {
        vm.expectEmit(true, true, false, true);
        emit DirectTransfer(sender, receiver, token, amount);
    }
    
    /**
     * @notice Helper to expect fee collected event
     */
    function _expectFeeCollected(
        address collector,
        address token,
        uint256 amount
    ) internal {
        vm.expectEmit(true, false, false, true);
        emit FeeCollected(collector, token, amount);
    }
    
    /**
     * @notice Helper to calculate expected fee
     */
    function _calculateFee(uint256 amount) internal pure returns (uint256 feeAmount, uint256 netAmount) {
        feeAmount = (amount * FEE_PERCENTAGE) / KlyraConstants.FEE_DENOMINATOR;
        netAmount = amount - feeAmount;
    }
    
    /**
     * @notice Helper to assert balance changes
     */
    function _assertBalanceChange(
        address token,
        address account,
        uint256 expectedChange,
        uint256 tolerance
    ) internal {
        uint256 balance = _getBalance(token, account);
        assertApproxEqAbs(balance, expectedChange, tolerance, "Balance change mismatch");
    }
}
