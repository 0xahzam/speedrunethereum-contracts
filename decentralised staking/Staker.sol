// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    // external contract that will hold funds
    ExampleExternalContract public exampleExternalContra
    // user balances
    mapping(address => uint256) public balances;

    // staking threshold and deadline
    uint256 public constant threshold = 1 ether;
    uint256 public deadline = block.timestamp + 72 hours;

    // Boolean set if threshold is not reached by the deadline
    bool public openForWithdraw;

    // staking events
    event Stake(address indexed sender, uint256 amount);
    event Withdraw(address indexed sender, uint256 amount);

    // constructor
    constructor(address exampleExternalContractAddress) public {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    // time left function
    function timeLeft() public view returns (uint256 timeleft) {
        if (block.timestamp >= deadline) {
            return 0;
        } else {
            return deadline - block.timestamp;
        }
    }


    // deadline passed
    modifier deadlinePassed(bool requireDeadlinePassed) {
        uint256 timeRemaining = timeLeft();
        if (requireDeadlinePassed) {
            require(timeRemaining <= 0, "Deadline has not been passed yet");
        } else {
            require(timeRemaining > 0, "Deadline is already passed");
        }
        _;
    }

    // staking not yet completed modifer
    modifier stakeNotCompleted() {
        bool completed = exampleExternalContract.completed();
        require(!completed, "staking process already completed");
        _;
    }

    // stake function
    function stake() public payable deadlinePassed(false) stakeNotCompleted {
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

     // withdraw function
    function withdraw()
        public
        deadlinePassed(true)
        stakeNotCompleted
    {
        require(openForWithdraw, "Not open for withdraw");

        require(balances[msg.sender] > 0, "You don't have balance to withdraw");

        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;

        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send user balance back to the user");

        emit Withdraw(msg.sender, amount);
    }

    // execute function
    function execute() public stakeNotCompleted {
        uint256 contractBalance = address(this).balance;
        if (contractBalance >= threshold) {
            exampleExternalContract.complete{value: contractBalance}();
        } else {
            openForWithdraw = true;
        }
    }

    // special function
    receive() external payable {
        stake();
    }
}
