// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./linkedlist.sol";

contract AuctionCollection is Ownable, LinkedListLib {

    // vars
    uint256 public endTime;
    uint256 public bidMinimum;
    uint256 public totalUserBid; // tracking purpose
    uint256 public totalClaimable;
    mapping(address => uint256) public notEligibleList;

    // events
    event Bid(address, string, uint256);
    event Refund(address, uint256);

    constructor(uint256 endTime_, uint256 bidMinimum_) {
        require(endTime_ > block.number, "AUC: invalid config params");
        endTime = endTime_;
        bidMinimum = bidMinimum_;
    }

    //    Bid(btc address, eth amount) // check min bid amount
    function bid(string calldata btcAddr) external payable {
        require(bytes(btcAddr).length != 0 && msg.value >= bidMinimum, "AUC: btc address mut be not null and bid amount greater than minimum");
        uint256 bidAmount = msg.value;
        address bidder = msg.sender;
        if (notEligibleList[bidder] > 0) {
            bidAmount += notEligibleList[bidder];
            notEligibleList[bidder] = 0;
        }
        (address removedAddr, uint256 removedAmount) = addNodeSorted(bidder, btcAddr, bidAmount);
        if (removedAddr != address(0)) {
            notEligibleList[removedAddr] = removedAmount;
        }

        emit Bid(bidder, btcAddr, bidAmount);
    }

    //    WithdrawPayment()
    function withdrawPayment() external onlyOwner {
        require(block.number >= endTime, "AUC: withdraw only after end time");
        uint256 paymentWithdrawAmount = address(this).balance - totalClaimable;
        require(paymentWithdrawAmount > 0, "AUC: nothing to withdraw");
        uint256 amount = paymentWithdrawAmount;
        paymentWithdrawAmount = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "AUC: failed to withdraw");
    }

    //    Refund()
    function refund() external {
        // the auction must end to be able claim eth back
        require(block.number >= endTime, "AUC: withdraw only after end time");
        uint256 refundAmount = notEligibleList[msg.sender];
        require(refundAmount > 0, "AUC: nothing to refund");
        notEligibleList[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: 0}("");
        require(success, "AUC: failed to refund");

        emit Refund(msg.sender, refundAmount);
    }

    //    ListBids()
    function listBids() external returns(uint[] memory) {
        uint[] memory temp = new uint[](0);
        return temp;
    }

    //    GetBidsByAddress()
    function getBidsByAddress() external returns(uint256) {
        return 0;
    }
}
