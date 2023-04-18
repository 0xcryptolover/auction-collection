pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract TC is Ownable {

    event MultiMint(address[], uint[]);
    event Burn(address, uint256);

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
}