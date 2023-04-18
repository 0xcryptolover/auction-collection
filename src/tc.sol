pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract TC is Ownable {

    uint256 public constant MAX_FEE = 1e4;
    uint256 public fee;

    event MultiMint(address[], uint[]);
    event Burn(address, uint256);

    constructor(uint256 fee_) {
        require(fee_ < MAX_FEE, "TC: invalid fee");
        fee = fee_;
    }

    function multiMint(address[] memory receivers, uint256[] memory amounts) external onlyOwner {
        require(receivers.length == amounts.length, "TC: input mismatch");
        require(receivers.length > 0, "TC: list of receivers must no empty");

        for (uint i = 0; i < receivers.length; i++) {
            require(amounts[i] > 0, "TC: mint amount must be positive");
            (bool success, ) = receivers[i].call{value: amounts[i]}("");
            require(success, "TC: failed to withdraw");
        }

        emit MultiMint(receivers, amounts);
    }

    function burn() payable external {
        emit Burn(msg.sender, msg.value);
    }

    function setFee(uint256 fee_) external onlyOwner {
        require(fee_ < MAX_FEE, "TC: invalid fee");
        fee = fee_;
    }

    function claimFee() external onlyOwner {
        uint256 temp = fee;
        fee = 0;
        (bool success, ) = owner().call{value: temp}("");
        require(success, "TC: failed to claim fee");
    }
}