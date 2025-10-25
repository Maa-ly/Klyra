// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "../src/test/MockERC20.sol";
import {Klyra1inchV2} from "../src/core/klyra.sol";

/**
 * @title MockERC20Test
 * @notice Test contract for MockERC20 token
 */
contract MockERC20Test is Test {
    MockERC20 public mockToken;
    Klyra1inchV2 public klyra;
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public feeCollector = address(0x3);
    
    function setUp() public {
        // Deploy mock token
        mockToken = new MockERC20(
            "Test Token",
            "TEST",
            18,
            1000000 * 10**18 // 1M tokens
        );
        
        // Deploy Klyra contract
        klyra = new Klyra1inchV2(
            feeCollector,
            100, // 1% fee
            address(0x111111125421cA6dc452d289314280a0f8842A65) // 1inch router
        );
        
        // Give users some tokens
        mockToken.mint(user1, 1000 * 10**18);
        mockToken.mint(user2, 1000 * 10**18);
    }
    
    function testMint() public {
        uint256 amount = 100 * 10**18;
        mockToken.mint(user1, amount);
        
        assertEq(mockToken.balanceOf(user1), 1100 * 10**18);
    }
    
    function testApprove() public {
        uint256 amount = 100 * 10**18;
        
        vm.prank(user1);
        bool success = mockToken.approve(address(klyra), amount);
        assertTrue(success);
        
        assertEq(mockToken.allowance(user1, address(klyra)), amount);
    }
    
    function testTransferFrom() public {
        uint256 amount = 100 * 10**18;
        
        // User1 approves Klyra to spend tokens
        vm.prank(user1);
        mockToken.approve(address(klyra), amount);
        
        // Klyra transfers tokens from user1 to user2
        vm.prank(address(klyra));
        bool success = mockToken.transferFrom(user1, user2, amount);
        assertTrue(success);
        
        assertEq(mockToken.balanceOf(user1), 900 * 10**18);
        assertEq(mockToken.balanceOf(user2), 1100 * 10**18);
    }
    
    function testTokenInfo() public {
        (string memory name, string memory symbol, uint8 decimals, uint256 totalSupply) = mockToken.getTokenInfo();
        
        assertEq(name, "Test Token");
        assertEq(symbol, "TEST");
        assertEq(decimals, 18);
        assertEq(totalSupply, 1000000 * 10**18);
    }
}
