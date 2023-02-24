// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract Streamer is Ownable {
    event Opened(address, uint256);
    event Challenged(address);
    event Withdrawn(address, uint256);
    event Closed(address);

    mapping(address => uint256) balances;
    mapping(address => uint256) canCloseAt;

    function fundChannel() public payable {
        require(balances[msg.sender] == 0, "already has a running channel");
        balances[msg.sender] = msg.value;
        emit Opened(msg.sender, msg.value);
    }

    function timeLeft(address channel) public view returns (uint256) {
        require(canCloseAt[channel] != 0, "channel is not closing");
        return canCloseAt[channel] - block.timestamp;
    }

    function withdrawEarnings(Voucher calldata voucher) public {
        bytes32 hashed = keccak256(abi.encode(voucher.updatedBalance));
        bytes memory prefixed = abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            hashed
        );
        bytes32 prefixedHashed = keccak256(prefixed);

        address signer = ecrecover(
            prefixedHashed,
            voucher.sig.v,
            voucher.sig.r,
            voucher.sig.s
        );

        require(
            balances[signer] > voucher.updatedBalance,
            "balance not enough"
        );

        uint256 payment = balances[msg.sender] - voucher.updatedBalance;
        balances[signer] = voucher.updatedBalance;

        payable(owner()).transfer(payment);

        emit Withdrawn(signer, payment);
    }

    function challengeChannel() public {
        require(balances[msg.sender] != 0, "already has a running channel");
        canCloseAt[msg.sender] = block.timestamp + 20 seconds;
        emit Challenged(msg.sender);
    }

    function defundChannel() public {
        require(canCloseAt[msg.sender] != 0, "doesn't have a closing channel");
        require(
            block.timestamp > canCloseAt[msg.sender],
            "early, can't close rightnow, try again later"
        );
        payable(msg.sender).transfer(balances[msg.sender]);
        balances[msg.sender] = 0;
        emit Closed(msg.sender);
    }

    struct Voucher {
        uint256 updatedBalance;
        Signature sig;
    }
    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }
}
