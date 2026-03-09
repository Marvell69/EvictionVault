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

    
    function testDeposit() public {
        vm.deal(user, 1 ether);

        vm.prank(user);
        vault.deposit{value: 1 ether}();

        assertEq(vault.balances(user), 1 ether);
        assertEq(vault.totalVaultValue(), 1 ether);
    }

    
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

    
    function testPauseUnpauseOwner() public {
        vm.prank(owner1);
        vault.pause();
        assertTrue(vault.paused());

        vm.prank(owner1);
        vault.unpause();
        assertFalse(vault.paused());
    }

    
    function testPauseRejectNonOwner() public {
        vm.prank(user);
        vm.expectRevert("not owner");
        vault.pause();
    }

    
    function testEmergencyWithdrawOnlyOwner() public {
        vm.deal(address(vault), 5 ether);

        vm.prank(user);
        vm.expectRevert("not owner");
        vault.emergencyWithdrawAll();
    }

    
    function testSetMerkleRootOnlyOwner() public {
        bytes32 newRoot = keccak256(abi.encodePacked("test"));

        vm.prank(user);
        vm.expectRevert("not owner");
        vault.setMerkleRoot(newRoot);

        vm.prank(owner1);
        vault.setMerkleRoot(newRoot);
        assertEq(vault.merkleRoot(), newRoot);
    }

        function testReceiveMsgSender() public {
        vm.deal(user, 1 ether);

        vm.prank(user);
        (bool success,) = address(vault).call{value: 1 ether}("");
        require(success);

        assertEq(vault.balances(user), 1 ether);
    }

        function testMultiSigTransaction() public {
        address target = address(4);
        vm.deal(address(vault), 2 ether);

       
        vm.prank(owner1);
        vault.submitTransaction(target, 1 ether, "");

        
        vm.prank(owner2);
        vault.confirmTransaction(0);

        
        vm.prank(owner1);
        vm.expectRevert("timelock not expired");
        vault.executeTransaction(0);

       
        vm.warp(block.timestamp + 1 hours + 1);

       
        vm.prank(owner1);
        vault.executeTransaction(0);

        
        (, , , bool executed, , , ) = vault.transactions(0);
        assertTrue(executed);
    }
}