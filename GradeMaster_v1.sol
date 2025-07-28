// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/**
 * @title Grader5 Interaction Contract
 * @dev A secure contract to interact with the Grader5 smart contract
 * @notice This contract allows controlled interactions with Grader5 including:
 *         - ETH management with retrieve calls
 *         - Secure function calls with ownership control
 *         - Emergency ETH recovery
 */
interface IGrader5 {
    function retrieve() external payable;
    function gradeMe(string calldata name) external;
    function withdraw() external;
}

contract MyGraderHack {
    /// @notice Immutable instance of the Grader5 contract
    IGrader5 public immutable graderContract;
    
    /// @notice Contract owner address for access control
    address public owner;

    event EtherReceived(address indexed from, uint256 amount);
    event EtherWithdrawn(address indexed to, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "MyGraderHack: caller is not the owner");
        _;
    }

    constructor(address _graderAddress) {
        require(_graderAddress != address(0), "MyGraderHack: zero address");
        graderContract = IGrader5(_graderAddress);
        owner = msg.sender;
    }

    /**
     * @dev Transfers ownership to a new address
     * @param newOwner The address to transfer ownership to
     * @notice Only callable by current owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "MyGraderHack: new owner is zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function callRetrieve(uint256 amountToSend) external payable {
        require(msg.value >= amountToSend, "MyGraderHack: insufficient ETH");
        graderContract.retrieve{value: amountToSend}();
    }

    function callGradeMe(string calldata _name) external {
        graderContract.gradeMe(_name);
    }

    /**
     * @dev Withdraws all ETH from contract
     * @notice Uses call with reentrancy protection
     * @notice Only callable by owner
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "MyGraderHack: no ETH to withdraw");
        
        (bool success, ) = owner.call{value: balance}("");
        require(success, "MyGraderHack: withdrawal failed");
        
        emit EtherWithdrawn(owner, balance);
    }

    receive() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }

    /**
     * @dev Emergency function to recover any ERC20 tokens sent to contract
     * @param tokenAddress Address of ERC20 token to recover
     * @param to Address to send tokens to
     * @notice Only callable by owner
     */
    function recoverERC20(address tokenAddress, address to) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "MyGraderHack: no tokens to recover");
        token.transfer(to, balance);
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}