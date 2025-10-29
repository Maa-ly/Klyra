// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
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
    uint256 public totalFeesCollected;

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

        // CHECKS: If same token, do direct transfer
        if (tokenFrom == tokenTo) {
            return _directTransferInternal(tokenFrom, receiver, amount);
        }

        // EFFECTS: Calculate fees
        (uint256 feeAmount, uint256 swapAmount) = KlyraHelpers.calculateFee(amount, feePercentage);
        KlyraHelpers.approveRouter(tokenFrom, address(router), swapAmount);

        // INTERACTIONS: Execute swap
        uint256 output =
            _executeAggregationSwap(tokenFrom, tokenTo, swapAmount, requiredOutputAmount, receiver, executor, swapData);

        // EFFECTS: Handle post-swap operations
        _handlePostSwap(tokenFrom, tokenTo, amount, output, feeAmount, receiver, RouterType.AGGREGATION);
        return output;
    }



    /**
     * @notice Send with Clipper router (optimized for smaller swaps)
     * @dev swapData should be encoded as: abi.encode(clipperExchange, goodUntil, r, vs)
     */
    function sendWithClipper(
        address tokenFrom,
        address tokenTo,
        uint256 amount,
        uint256 requiredOutputAmount,
        address receiver,
        address /* executor */,
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

        // CHECKS: If same token, do direct transfer
        if (tokenFrom == tokenTo) {
            return _directTransferInternal(tokenFrom, receiver, amount);
        }

        // EFFECTS: Calculate fees
        (uint256 feeAmount, uint256 swapAmount) = KlyraHelpers.calculateFee(amount, feePercentage);
        KlyraHelpers.approveRouter(tokenFrom, address(router), swapAmount);

        // INTERACTIONS: Execute Clipper swap
        uint256 output = _executeClipperSwap(
            tokenFrom, tokenTo, swapAmount, requiredOutputAmount, receiver, swapData
        );

        // EFFECTS: Handle post-swap operations
        _handlePostSwap(tokenFrom, tokenTo, amount, output, feeAmount, receiver, RouterType.CLIPPER);
        return output;
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
        KlyraHelpers.transferToken(token, feeCollector, amount);
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
     * @notice Simulate swaps using all available swap paths and return the best quote
     * @dev Compares Aggregation and Clipper router quotes and returns the one with highest output
     * @param inputAmount Amount of input tokens
     * @param inputToken Address of input token (use address(0) for ETH)
     * @param outputToken Address of output token
     * @param expectedOutputAggregation Expected output from Aggregation router API quote
     * @param expectedOutputClipper Expected output from Clipper router API quote
     * @return breakdown Payment breakdown for the best route
     * @return minOutput Minimum output amount after slippage for the best route
     * @return bestRouterType The router type that gives the best quote
     */
    function simulateswap(
        uint256 inputAmount,
        address inputToken,
        address outputToken,
        uint256 expectedOutputAggregation,
        uint256 expectedOutputClipper
    )
        public
        view
        returns (PaymentBreakdown memory breakdown, uint256 minOutput, RouterType bestRouterType)
    {
        // Calculate fees (same for both routes)
        (uint256 feeAmount, uint256 netInputAmount) = KlyraHelpers.calculateFee(inputAmount, feePercentage);

        // Calculate expected outputs after fees for both routes
        uint256 expectedOutputAfterFeeAggregation = (expectedOutputAggregation * netInputAmount) / inputAmount;
        uint256 expectedOutputAfterFeeClipper = (expectedOutputClipper * netInputAmount) / inputAmount;

        // Determine which route gives better output
        RouterType selectedRouter;
        uint256 bestExpectedOutput;

        if (expectedOutputAfterFeeAggregation >= expectedOutputAfterFeeClipper) {
            selectedRouter = RouterType.AGGREGATION;
            bestExpectedOutput = expectedOutputAfterFeeAggregation;
        } else {
            selectedRouter = RouterType.CLIPPER;
            bestExpectedOutput = expectedOutputAfterFeeClipper;
        }

        // Calculate minimum output with slippage
        minOutput = bestExpectedOutput - (bestExpectedOutput * defaultSlippageBps) / KlyraConstants.SLIPPAGE_DENOMINATOR;

        // Build breakdown
        breakdown = PaymentBreakdown({
            inputToken: inputToken,
            outputToken: outputToken,
            inputAmount: inputAmount,
            feeAmount: feeAmount,
            netInputAmount: netInputAmount,
            expectedOutputAmount: bestExpectedOutput,
            feePercentage: feePercentage,
            minOutputWithSlippage: minOutput,
            slippageBps: defaultSlippageBps
        });

        return (breakdown, minOutput, selectedRouter);
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

    function _executeClipperSwap(
        address tokenFrom,
        address tokenTo,
        uint256 swapAmount,
        uint256 minReturn,
        address receiver,
        bytes calldata swapData
    ) internal returns (uint256) {
        // Decode swapData: abi.encode(clipperExchange, goodUntil, r, vs)
        (address clipperExchange, uint256 goodUntil, bytes32 r, bytes32 vs) =
            abi.decode(swapData, (address, uint256, bytes32, bytes32));

        // Get balance before swap
        uint256 balanceBefore = KlyraHelpers.getBalance(tokenTo, address(this));

        // Execute Clipper swap
        try router.clipperSwap{value: tokenFrom == KlyraConstants.ETH_ADDRESS ? swapAmount : 0}(
            clipperExchange, tokenFrom, tokenTo, swapAmount, minReturn, goodUntil, r, vs
        ) returns (uint256) {
            uint256 output = KlyraHelpers.getBalance(tokenTo, address(this)) - balanceBefore;
            KlyraHelpers.validateOutput(output, minReturn);
            KlyraHelpers.transferToken(tokenTo, receiver, output);
            return output;
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
        //@ToDO: Add Fee collection logic, fee accumulation
        // if (feeAmount > 0) {
        //     KlyraHelpers.transferToken(tokenFrom, feeCollector, feeAmount);
        //     emit FeeCollected(feeCollector, tokenFrom, feeAmount);
        // }

        // Normalize all token amounts to 18 decimals for consistent calculations
        uint256 inputAmountNormalized = KlyraHelpers.normalizeTo18Decimals(inputAmount, tokenFrom);
        uint256 outputAmountNormalized = KlyraHelpers.normalizeTo18Decimals(outputAmount, tokenTo);

        totalPayments++;
        totalVolume += inputAmountNormalized;
        totalFeesCollected += feeAmount;

        emit PaymentExecuted(msg.sender, receiver, tokenFrom, tokenTo, inputAmount, outputAmount, routerType, feeAmount);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getTokenBalance(address token) external view returns (uint256) {
        return KlyraHelpers.getBalance(token, address(this));
    }

    // Receive ETH
    receive() external payable {}
}
