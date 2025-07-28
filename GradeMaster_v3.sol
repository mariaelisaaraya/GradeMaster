// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @title GradeMaster - Smart Solution for Grader5 Challenge
/// @notice Innovative contract to complete the Module 5 final assignment
/// @dev Implements a creative approach to interact with Grader5 contract
contract GradeMaster_v3 {
    /// @notice Target Grader5 contract address (0x5733eE985e22eFF46F595376d79e31413b1a1e16)
    address public immutable graderAddress;
    
    /// @notice Tracks contract creator for fund recovery
    address public immutable solver;
    
    /// @notice Emitted when challenge is successfully completed
    event ChallengeSolved(string studentName, uint256 timestamp);
    
    /// @notice Emitted when funds are withdrawn
    event FundsRecovered(uint256 amount);

    /// @dev Initializes contract with Grader5 address and sets solver
    constructor() {
        graderAddress = 0x5733eE985e22eFF46F595376d79e31413b1A1e16;
        solver = msg.sender;
    }

    /// @notice Executes the complete solution in one transaction
    /// @dev Implements the required sequence with creative enhancements
    /// @param yourName The name/alias to register (gets bonus emoji)
    /// @notice Requires sending at least 5 wei (4 + 1 for retrieve calls)
    function solveChallenge(string calldata yourName) external payable {
        require(msg.value >= 5 wei, "Minimum 5 wei required");
        
        // First retrieve call (4 wei) - meets >3 wei requirement
        (bool success1, ) = graderAddress.call{value: 4, gas: 200000}( 
            abi.encodeWithSignature("retrieve()")
        );
        require(success1, "First retrieve failed"); 
        
        // Second retrieve call (1 wei) - ensures counter > 1
        (bool success2, ) = graderAddress.call{value: 1, gas: 200000}( 
            abi.encodeWithSignature("retrieve()")
        );
        require(success2, "Second retrieve failed"); 
        
        // Creative name registration with trophy emoji
        string memory decoratedName = string(abi.encodePacked("win", yourName));
        (bool success3, ) = graderAddress.call{gas: 200000}(
            abi.encodeWithSignature("gradeMe(string)", decoratedName)
        );
        require(success3, "Grade registration failed"); 
        
        emit ChallengeSolved(decoratedName, block.timestamp);
    }

    /// @notice Allows solver to recover any remaining ETH
    /// @dev Only callable by original solver
    function recoverFunds() external {
        require(msg.sender == solver, "Only solver can recover");
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds available");
        
        (bool sent, ) = payable(solver).call{value: balance}("");
        require(sent, "Transfer failed");
        
        emit FundsRecovered(balance);
    }

    /// @dev Accepts ETH transfers (for retrieve call returns)
    receive() external payable {}
}