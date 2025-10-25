// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Router1inch} from "../routers/1incherouter.sol";
import {KlyraModifiers} from "./modifer.sol";
import {KlyraHelpers} from "./helper.sol";
import {KlyraErrors} from "../dataTypes/errors.sol";
import {KlyraConstants} from "../dataTypes/constants.sol";
import {PaymentBreakdown} from "../dataTypes/structs.sol";
import {IUnifiedRouter} from "../interface/IUnifiedRouter.sol";

/**
 * @title Klyra1inchV2
 * @notice Streamlined payment abstraction service using 1inch
 * @dev Modular design with separated concerns
 */
contract Klyra1inchV2 is Router1inch, ReentrancyGuard, KlyraModifiers {
    // State variables
    uint256 public immutable CHAIN_ID;
    uint256 public feePercentage;
    address public feeCollector;
    uint256 public defaultSlippageBps;

    // Supported chains mapping
    mapping(uint256 => bool) public supportedChains;

    // Statistics
    uint256 public totalPayments;
    uint256 public totalVolume;

    // Events
    event PaymentExecuted(
        address indexed sender,
        address indexed receiver,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        RouterType routerType,
        uint256 feeAmount
    );

    event DirectTransfer(address indexed sender, address indexed receiver, address token, uint256 amount);

    event FeeCollected(address indexed collector, address token, uint256 amount);
    event FeeUpdated(uint256 oldFee, uint256 newFee);
    event FeeCollectorUpdated(address indexed oldCollector, address indexed newCollector);
    event SlippageUpdated(uint256 oldSlippage, uint256 newSlippage);

    /**
     * @notice Constructor
     */
    constructor(address _feeCollector, uint256 _feePercentage, address _routerAddress) Router1inch(_routerAddress) {
        if (_feeCollector == address(0)) revert KlyraErrors.InvalidAddress();
        if (_feePercentage > KlyraConstants.MAX_FEE) revert KlyraErrors.InvalidFee();

        // Initialize supported chains
        _initializeSupportedChains();

        CHAIN_ID = block.chainid;

        // Check if current chain is supported
        if (!supportedChains[CHAIN_ID]) {
            revert KlyraErrors.UnsupportedChain();
        }
        feeCollector = _feeCollector;
        feePercentage = _feePercentage;
        defaultSlippageBps = KlyraConstants.DEFAULT_SLIPPAGE_BPS;
    }

    // ============ SINGLE RECIPIENT FUNCTIONS ============

    /**
     * @notice Send with aggregation router
     */
    function sendWithAggregation(
        address tokenFrom,
        address tokenTo,
        uint256 amount,
        uint256 requiredOutputAmount,
        address receiver,
        address executor,
        bytes calldata swapData
    )
        external
        payable
        nonReentrant
        validAmount(amount)
        validAddress(receiver)
        validEthPayment(tokenFrom, amount)
        returns (uint256)
    {
        // CHECKS: Handle token input and validate
        KlyraHelpers.handleTokenInput(tokenFrom, amount, msg.sender, address(this));
        KlyraHelpers.approveRouter(tokenFrom, address(router), amount);

        // CHECKS: If same token, do direct transfer
        if (tokenFrom == tokenTo) {
            return _directTransferInternal(tokenFrom, receiver, amount);
        }

        // EFFECTS: Calculate fees
        (uint256 feeAmount, uint256 swapAmount) = KlyraHelpers.calculateFee(amount, feePercentage);

        // INTERACTIONS: Execute swap
        uint256 output =
            _executeAggregationSwap(tokenFrom, tokenTo, swapAmount, requiredOutputAmount, receiver, executor, swapData);

        // EFFECTS: Handle post-swap operations
        _handlePostSwap(tokenFrom, tokenTo, amount, output, feeAmount, receiver, RouterType.AGGREGATION);
        return output;
    }

    /**
     * @notice Send with unoswap router
     */
    function sendWithUnoswap(
        address tokenFrom,
        uint256 amount,
        uint256 requiredOutputAmount,
        uint256 dexData,
        address payable receiver
    ) external payable nonReentrant validAmount(amount) validAddress(receiver) returns (uint256) {
        // CHECKS: Handle token input and validate
        KlyraHelpers.handleTokenInput(tokenFrom, amount, msg.sender, address(this));

        // EFFECTS: Calculate fees
        (uint256 feeAmount, uint256 swapAmount) = KlyraHelpers.calculateFee(amount, feePercentage);
        KlyraHelpers.approveRouter(tokenFrom, address(router), swapAmount);
        // INTERACTIONS: Execute swap
        uint256 output = _executeUnoswap(tokenFrom, swapAmount, requiredOutputAmount, dexData, receiver);

        // EFFECTS: Handle post-swap operations
        _handlePostSwap(tokenFrom, address(0), amount, output, feeAmount, receiver, RouterType.UNOSWAP);
        return output;
    }

    /**
     * @notice Send direct ETH transfer (no swap)
     */
    function sendDirectETH(address receiver)
        external
        payable
        nonReentrant
        validAmount(msg.value)
        validAddress(receiver)
        returns (uint256)
    {
        return _directTransferInternal(KlyraConstants.ETH_ADDRESS, receiver, msg.value);
    }

    /**
     * @notice Send direct token transfer (no swap)
     */
    function sendDirectToken(address token, address receiver, uint256 amount)
        external
        nonReentrant
        validAmount(amount)
        validAddress(receiver)
        returns (uint256)
    {
        // CHECKS: Handle token input and validate
        KlyraHelpers.handleTokenInput(token, amount, msg.sender, address(this));

        // INTERACTIONS: Execute direct transfer
        return _directTransferInternal(token, receiver, amount);
    }

    /**
     * @notice Approve an address to spend tokens on behalf of msg.sender
     * @param token The token address to approve
     * @param spender The address to approve
     * @param amount The amount to approve
     */
    function approveToken(address token, address spender, uint256 amount)
        external
        validAddress(token)
        validAddress(spender)
        validAmount(amount)
    {
        // CHECKS: Validate inputs (done by modifiers)

        // INTERACTIONS: Approve the spender to spend tokens
        IERC20(token).approve(spender, amount);
    }

    // ============ ADMIN FUNCTIONS ============

    function setFeePercentage(uint256 newFee) external onlyOwner {
        // CHECKS: Validate input
        if (newFee > KlyraConstants.MAX_FEE) revert KlyraErrors.InvalidFee();

        // EFFECTS: Update state and emit event
        emit FeeUpdated(feePercentage, newFee);
        feePercentage = newFee;
    }

    function setFeeCollector(address newCollector) external onlyOwner {
        // CHECKS: Validate input
        if (newCollector == address(0)) revert KlyraErrors.InvalidAddress();

        // EFFECTS: Update state and emit event
        emit FeeCollectorUpdated(feeCollector, newCollector);
        feeCollector = newCollector;
    }

    function setDefaultSlippage(uint256 newSlippageBps) external onlyOwner {
        // CHECKS: Validate input
        if (newSlippageBps > KlyraConstants.SLIPPAGE_DENOMINATOR) revert KlyraErrors.InvalidFee();

        // EFFECTS: Update state and emit event
        emit SlippageUpdated(defaultSlippageBps, newSlippageBps);
        defaultSlippageBps = newSlippageBps;
    }

    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        KlyraHelpers.transferToken(token, owner(), amount);
    }

    // ============ VIEW/GETTER FUNCTIONS ============

    /**
     * @notice Get contract statistics
     */
    function getStatistics() external view returns (uint256 payments, uint256 volume, uint256 fee, address collector) {
        return (totalPayments, totalVolume, feePercentage, feeCollector);
    }

    /**
     * @notice Initialize supported chains
     * @dev Sets up the default supported chains
     */
    function _initializeSupportedChains() internal {
        supportedChains[KlyraConstants.ETHEREUM_CHAIN_ID] = true;
        supportedChains[KlyraConstants.BASE_CHAIN_ID] = true;
        supportedChains[KlyraConstants.ETHEREUM_SEPOLIA_CHAIN_ID] = true;
        supportedChains[KlyraConstants.BASE_SEPOLIA_CHAIN_ID] = true;
    }

    /**
     * @notice Check if chain is supported
     */
    function isChainSupported() external view returns (bool) {
        return supportedChains[CHAIN_ID];
    }

    /**
     * @notice Add or remove supported chain
     * @param chainId The chain ID to modify
     * @param supported Whether the chain should be supported
     */
    function setChainSupport(uint256 chainId, bool supported) external onlyOwner {
        supportedChains[chainId] = supported;
    }

    /**
     * @notice Calculate expected output amount after fees
     */
    function calculateExpectedOutput(uint256 inputAmount, uint256 expectedOutputBeforeFees)
        public
        view
        returns (uint256 netInputAmount, uint256 expectedOutputAmount, uint256 feeAmount)
    {
        (feeAmount, netInputAmount) = KlyraHelpers.calculateFee(inputAmount, feePercentage);
        expectedOutputAmount = (expectedOutputBeforeFees * netInputAmount) / inputAmount;
        return (netInputAmount, expectedOutputAmount, feeAmount);
    }

    /**
     * @notice Validate if user's input amount will meet required output
     */
    function validatePaymentAmount(uint256 inputAmount, uint256 requiredOutputAmount, uint256 expectedOutputFromQuote)
        public
        view
        returns (bool isValid, uint256 actualOutput, uint256 shortfall)
    {
        (, uint256 expectedOutput,) = calculateExpectedOutput(inputAmount, expectedOutputFromQuote);
        actualOutput = expectedOutput;

        if (actualOutput >= requiredOutputAmount) {
            isValid = true;
            shortfall = 0;
        } else {
            isValid = false;
            shortfall = requiredOutputAmount - actualOutput;
        }

        return (isValid, actualOutput, shortfall);
    }

    /**
     * @notice Calculate required input amount to get desired output
     */
    function calculateRequiredInput(uint256 desiredOutputAmount, uint256 quotedRate)
        public
        view
        returns (uint256 requiredInputAmount)
    {
        uint256 inputBeforeFees = (desiredOutputAmount * 1e18) / quotedRate;
        requiredInputAmount =
            (inputBeforeFees * KlyraConstants.FEE_DENOMINATOR) / (KlyraConstants.FEE_DENOMINATOR - feePercentage);
        return requiredInputAmount;
    }

    /**
     * @notice Get quote breakdown for a payment
     */
    function getPaymentBreakdown(
        uint256 inputAmount,
        address inputToken,
        address outputToken,
        uint256 expectedOutputFromApi
    ) external view returns (PaymentBreakdown memory breakdown) {
        (uint256 feeAmount, uint256 netInputAmount) = KlyraHelpers.calculateFee(inputAmount, feePercentage);
        uint256 expectedOutput = (expectedOutputFromApi * netInputAmount) / inputAmount;
        uint256 minOutput = expectedOutput - (expectedOutput * defaultSlippageBps) / KlyraConstants.SLIPPAGE_DENOMINATOR;

        breakdown = PaymentBreakdown({
            inputToken: inputToken,
            outputToken: outputToken,
            inputAmount: inputAmount,
            feeAmount: feeAmount,
            netInputAmount: netInputAmount,
            expectedOutputAmount: expectedOutput,
            feePercentage: feePercentage,
            minOutputWithSlippage: minOutput,
            slippageBps: defaultSlippageBps
        });

        return breakdown;
    }

    // ============ INTERNAL FUNCTIONS ============

    function _executeAggregationSwap(
        address tokenFrom,
        address tokenTo,
        uint256 swapAmount,
        uint256 minReturn,
        address receiver,
        address executor,
        bytes calldata swapData
    ) internal returns (uint256) {
        IUnifiedRouter.SwapDescription memory desc = IUnifiedRouter.SwapDescription({
            srcToken: tokenFrom,
            dstToken: tokenTo,
            srcReceiver: payable(executor),
            dstReceiver: payable(address(this)),
            amount: swapAmount,
            minReturnAmount: minReturn,
            flags: 0
        });

        uint256 balanceBefore = KlyraHelpers.getBalance(tokenTo, address(this));

        try router.swap{value: tokenFrom == KlyraConstants.ETH_ADDRESS ? swapAmount : 0}(executor, desc, "", swapData)
        returns (uint256, uint256) {
            uint256 output = KlyraHelpers.getBalance(tokenTo, address(this)) - balanceBefore;
            KlyraHelpers.validateOutput(output, minReturn);
            KlyraHelpers.transferToken(tokenTo, receiver, output);
            return output;
        } catch {
            revert KlyraErrors.SwapFailed();
        }
    }

    function _executeUnoswap(
        address tokenFrom,
        uint256 swapAmount,
        uint256 minReturn,
        uint256 dexData,
        address payable receiver
    ) internal returns (uint256) {
        uint256[] memory pools = new uint256[](1);
        pools[0] = dexData;

        try router.unoswap{value: tokenFrom == KlyraConstants.ETH_ADDRESS ? swapAmount : 0}(
            tokenFrom, swapAmount, minReturn, pools
        ) returns (uint256 returnAmount) {
            KlyraHelpers.validateOutput(returnAmount, minReturn);

            // Transfer tokens to receiver after swap
            if (tokenFrom == KlyraConstants.ETH_ADDRESS) {
                // For ETH swaps, transfer ETH to receiver
                (bool success,) = receiver.call{value: returnAmount}("");
                if (!success) revert KlyraErrors.TransferFailed();
            } else {
                // For token swaps, transfer tokens to receiver
                KlyraHelpers.transferToken(tokenFrom, receiver, returnAmount);
            }

            return returnAmount;
        } catch {
            revert KlyraErrors.SwapFailed();
        }
    }

    function _directTransferInternal(address token, address receiver, uint256 amount) internal returns (uint256) {
        // EFFECTS: Update statistics
        totalPayments++;
        totalVolume += amount;

        // INTERACTIONS: Transfer token
        KlyraHelpers.transferToken(token, receiver, amount);

        // EFFECTS: Emit event
        emit DirectTransfer(msg.sender, receiver, token, amount);

        return amount;
    }

    function _handlePostSwap(
        address tokenFrom,
        address tokenTo,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 feeAmount,
        address receiver,
        RouterType routerType
    ) internal {
        if (feeAmount > 0) {
            KlyraHelpers.transferToken(tokenFrom, feeCollector, feeAmount);
            emit FeeCollected(feeCollector, tokenFrom, feeAmount);
        }

        totalPayments++;
        totalVolume += inputAmount;

        emit PaymentExecuted(msg.sender, receiver, tokenFrom, tokenTo, inputAmount, outputAmount, routerType, feeAmount);
    }

    // Receive ETH
    receive() external payable {}
}
