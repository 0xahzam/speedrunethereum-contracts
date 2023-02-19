pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading
// SPDX-License-Identifier: MIT
import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {
    //event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);

    YourToken public yourToken;

    constructor(address tokenAddress) {
        yourToken = YourToken(tokenAddress);
    }

    //token per eth
    uint256 public constant tokensPerEth = 100;

    //event
    event transfer(address buyer, uint256 balance, uint256 amountDemand);
    event resell(address seller, uint256 balance, uint256 amountSold);

    //function to buy token
    function buyTokens() public payable {
        // checking balance
        uint256 Balance = msg.value;
        require(Balance > 0, "Not enough balance");

        uint256 amountDemand = Balance * tokensPerEth;
        uint256 supply = yourToken.balanceOf(address(this));

        //checking contract has enough tokens to give
        require(supply >= amountDemand, "Vendor doesn't have enough tokens");

        //sending token
        bool sent = yourToken.transfer(msg.sender, amountDemand);
        require(sent, "Failed to sent");

        //event
        emit transfer(msg.sender, Balance, amountDemand);
    }

    //function to sell back to vendor
    function sellTokens(uint256 amount) public payable {
        require(amount > 0, "Not enough amount to sell");

        //checking user has token to sell
        uint256 userBalance = yourToken.balanceOf(msg.sender);
        require(userBalance >= amount, "User doesn't have enough tokens");

        //checking vendor has enuogh ETH to return
        uint256 ETHAmount = amount / tokensPerEth;
        uint256 vendorBalance = address(this).balance;
        // require(vendorBalance > ETHAmount, "Vendor doesn't have enough ETH");

        //txn1 : token from user -> vendor
        bool sent = yourToken.transferFrom(msg.sender, address(this), amount);
        require(sent, "Failed to transfer tokens");

        //txn2 : ETH from vendor -> user
        (bool Ethsent, ) = msg.sender.call{value: ETHAmount}("");

        require(Ethsent, "Failed to send ETH");

        //event
        emit resell(msg.sender, ETHAmount, amount);
    }

    function withdraw() public onlyOwner {
        // Validate the vendor has ETH to withdraw
        uint256 vendorBalance = address(this).balance;
        require(vendorBalance > 0, "Vendor does not have any ETH to withdraw");

        // Send ETH
        address owner = msg.sender;
        (bool sent, ) = owner.call{value: vendorBalance}("");
        require(sent, "Failed to withdraw");
    }
}
