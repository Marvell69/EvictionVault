// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./VaultModifiers.sol";

contract EvictionVault is VaultModifiers {

    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event MerkleRootSet(bytes32 root);
    event Claim(address indexed user, uint256 amount);

    constructor(address[] memory _owners, uint256 _threshold) {

        require(_owners.length > 0, "no owners");
        require(_threshold <= _owners.length, "invalid threshold");

        threshold = _threshold;

        for (uint i; i < _owners.length; i++) {
            isOwner[_owners[i]] = true;
            owners.push(_owners[i]);
        }
    }

    receive() external payable {
        balances[msg.sender] += msg.value; // FIX: no tx.origin
        totalVaultValue += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        totalVaultValue += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external notPaused {

        require(balances[msg.sender] >= amount, "insufficient");

        balances[msg.sender] -= amount;
        totalVaultValue -= amount;

        (bool success,) = payable(msg.sender).call{value: amount}(""); // FIX transfer
        require(success);

        emit Withdrawal(msg.sender, amount);
    }

    function setMerkleRoot(bytes32 root) external onlyOwner { // FIX access control
        merkleRoot = root;
        emit MerkleRootSet(root);
    }

    function claim(bytes32[] calldata proof, uint256 amount) external notPaused {

        require(!claimed[msg.sender], "claimed");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));

        require(MerkleProof.verify(proof, merkleRoot, leaf), "invalid proof");

        claimed[msg.sender] = true;

        (bool success,) = payable(msg.sender).call{value: amount}(""); // FIX transfer
        require(success);

        totalVaultValue -= amount;

        emit Claim(msg.sender, amount);
    }

    function pause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }

    function emergencyWithdrawAll() external onlyOwner { // FIX public drain

        uint256 bal = address(this).balance;

        (bool success,) = payable(msg.sender).call{value: bal}("");
        require(success);

        totalVaultValue = 0;
    }

    // Multi-signature transaction functions with timelock
    event Submission(uint256 indexed txId);
    event Confirmation(uint256 indexed txId, address indexed owner);
    event Execution(uint256 indexed txId);

    function submitTransaction(
        address to,
        uint256 value,
        bytes calldata data
    ) external onlyOwner notPaused {
        uint256 id = txCount++;
        transactions[id] = Transaction({
            to: to,
            value: value,
            data: data,
            executed: false,
            confirmations: 1,
            submissionTime: block.timestamp,
            executionTime: 0
        });
        confirmed[id][msg.sender] = true;
        emit Submission(id);
    }

    function confirmTransaction(uint256 txId) external onlyOwner notPaused {
        Transaction storage txn = transactions[txId];
        require(!txn.executed, "executed");
        require(!confirmed[txId][msg.sender], "already confirmed");
        confirmed[txId][msg.sender] = true;
        txn.confirmations++;
        if (txn.confirmations == threshold) {
            txn.executionTime = block.timestamp + TIMELOCK_DURATION;
        }
        emit Confirmation(txId, msg.sender);
    }

    function executeTransaction(uint256 txId) external {
        Transaction storage txn = transactions[txId];
        require(txn.confirmations >= threshold, "insufficient confirmations");
        require(!txn.executed, "executed");
        require(block.timestamp >= txn.executionTime, "timelock not expired");
        txn.executed = true;
        (bool success,) = txn.to.call{value: txn.value}(txn.data);
        require(success, "execution failed");
        emit Execution(txId);
    }
}