// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./VaultStorage.sol";

contract VaultModifiers is VaultStorage {

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier notPaused() {
        require(!paused, "paused");
        _;
    }
}