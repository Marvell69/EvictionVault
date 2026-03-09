// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/EvictionVault.sol";

contract VaultTest is Test {

    EvictionVault vault;

    address owner1 = address(1);
    address owner2 = address(2);
    address user = address(3);

    function setUp() public {
        address[] memory owners = new address[](2);
        owners[0] = owner1;
        owners[1] = owner2;

        vault = new EvictionVault(owners, 2);
    }

    // Test 1: Basic deposit functionality
    function testDeposit() public {
        vm.deal(user, 1 ether);

        vm.prank(user);
        vault.deposit{value: 1 ether}();

        assertEq(vault.balances(user), 1 ether);
        assertEq(vault.totalVaultValue(), 1 ether);
    }

    // Test 2: Withdrawal with correct amount transfer
    function testWithdraw() public {
        vm.deal(user, 1 ether);

        vm.prank(user);
        vault.deposit{value: 1 ether}();

        uint256 balanceBefore = user.balance;

        vm.prank(user);
        vault.withdraw(1 ether);

        assertEq(vault.balances(user), 0);
        assertEq(user.balance, balanceBefore + 1 ether);
        assertEq(vault.totalVaultValue(), 0);
    }

    // Test 3: Pause/Unpause restricted to owners
    function testPauseUnpauseOwner() public {
        vm.prank(owner1);
        vault.pause();
        assertTrue(vault.paused());

        vm.prank(owner1);
        vault.unpause();
        assertFalse(vault.paused());
    }

    // Test 4: Non-owner cannot pause
    function testPauseRejectNonOwner() public {
        vm.prank(user);
        vm.expectRevert("not owner");
        vault.pause();
    }

    // Test 5: Emergency withdraw only callable by owner
    function testEmergencyWithdrawOnlyOwner() public {
        vm.deal(address(vault), 5 ether);

        vm.prank(user);
        vm.expectRevert("not owner");
        vault.emergencyWithdrawAll();
    }

    // Test 6: Proper merkleRoot setting with owner restriction
    function testSetMerkleRootOnlyOwner() public {
        bytes32 newRoot = keccak256(abi.encodePacked("test"));

        vm.prank(user);
        vm.expectRevert("not owner");
        vault.setMerkleRoot(newRoot);

        vm.prank(owner1);
        vault.setMerkleRoot(newRoot);
        assertEq(vault.merkleRoot(), newRoot);
    }

    // Test 7: Receive function uses msg.sender not tx.origin
    function testReceiveMsgSender() public {
        vm.deal(user, 1 ether);

        vm.prank(user);
        (bool success,) = address(vault).call{value: 1 ether}("");
        require(success);

        assertEq(vault.balances(user), 1 ether);
    }

    // Test 8: Multi-sig transaction flow with timelock
    function testMultiSigTransaction() public {
        address target = address(4);
        vm.deal(address(vault), 2 ether);

        // Owner1 submits
        vm.prank(owner1);
        vault.submitTransaction(target, 1 ether, "");

        // Owner2 confirms to reach threshold
        vm.prank(owner2);
        vault.confirmTransaction(0);

        // Check timelock enforced
        vm.prank(owner1);
        vm.expectRevert("timelock not expired");
        vault.executeTransaction(0);

        // Warp past timelock
        vm.warp(block.timestamp + 1 hours + 1);

        // Execute after timelock
        vm.prank(owner1);
        vault.executeTransaction(0);

        // Verify transaction was executed
        (, , , bool executed, , , ) = vault.transactions(0);
        assertTrue(executed);
    }
}