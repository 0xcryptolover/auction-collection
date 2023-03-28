// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract AuctionCollection is Ownable {

    // vars
    uint256 public endTime;
    uint256 public bidMinimum;

    // events
    event Bid(string, address, uint256);
    event Refund(address, uint256);

    constructor(uint256 endTime_, uint256 bidMinimum_) public {
        require(endTime_ > block.number, "AUC: invalid config params");
        endTime = endTime_;
        bidMinimum = bidMinimum_;
    }

    //    Bid(btc address, eth amount) // check min bid amount
    function bid(string btcAddr) external payable {
        require(btcAddr.length != 0 && msg.value > bidMinimum, "AUC: btc address mut be not null and bid amount greater than minimum");

    }

    //    WithdrawPayment()
    function withdrawPayment() external onlyOwner {

    }

    //    Refund()
    function Refund() external {
        // the auction must end to be able claim eth back
    }

    //    ListBids()
    function listBids() external returns(uint[] memory) {
        uint[] temp = new uint[](0);
        return temp;
    }

    //    GetBidsByAddress()
    function getBidsByAddress() external returns(uint256) {
        return 0;
    }
}
