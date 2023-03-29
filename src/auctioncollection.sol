// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract AuctionCollection is Ownable {
    uint256 public constant MAX_WINNERS = 512;

    struct BidderResponse {
        address bidder;
        bool isWinner;
        uint256 amount;
    }

    struct Bidder {
        uint256 amount;
        uint16 index;
    }

    // vars
    uint256 public endTime;
    uint256 public bidMinimum;
    uint256 private totalPaymentWithdraw;
    bool private winnerDeclared;
    mapping(address => Bidder) private bidders;
    mapping(address => bool) private isAccountExisted;
    address[] private ethAddresses;
    bytes private winners;

    // events
    event Bid(address, uint256);
    event Refund(address, uint256);

    constructor(uint256 endTime_, uint256 bidMinimum_) {
        require(endTime_ > block.timestamp, "AUC: invalid config params");
        endTime = endTime_;
        bidMinimum = bidMinimum_;
    }

    //    Bid(btc address, eth amount) // check min bid amount
    function bid() external payable {
        uint256 bidAmount = msg.value;
        address bidder = msg.sender;
        require(bidAmount >= bidMinimum && block.timestamp < endTime, "AUC: btc address mut be not null and bid amount greater than minimum");
        unchecked {
            bidders[bidder].amount += bidAmount;
        }

        if (!isAccountExisted[bidder]) {
            isAccountExisted[bidder] = true;
            ethAddresses.push(bidder);
            bidders[bidder].index = uint16(ethAddresses.length);
        }

        emit Bid(bidder, bidAmount);
    }

    // declare winners
    function declareWinners(uint16[] memory winnerList, bool isFinal) external onlyOwner {
        require(block.timestamp >= endTime && !winnerDeclared,"AUC: auction not end yet or winner declared");
        require(winnerList.length <= MAX_WINNERS ,"AUC: too many winners");
        uint256 _totalPaymentWithdraw;
        for (uint256 i = 0; i < winnerList.length; i++) {
            address temp = ethAddresses[winnerList[i]];
            require(temp != address(0), "AUC: duplicate winner");
            ethAddresses[winnerList[i]] = address(0);
            _totalPaymentWithdraw += bidders[temp].amount;
        }
        winnerDeclared = isFinal;
        totalPaymentWithdraw += _totalPaymentWithdraw;
    }

    //    function isBitSet(uint8 b, uint8 pos) public pure returns(bool) {
    //        return ((b >> pos) & 1) == 1;
    //    }

    function isWinner(address bidder) internal view returns(bool) {
        uint16 bidderIndex = bidders[bidder].index;
        if (!winnerDeclared || bidderIndex == 0) {
            return false;
        }
        // return isBitSet(winners[bidderIndex / 8], bidderIndex % 8);
        return ethAddresses[bidders[bidder].index - 1] == address(0);
    }

    //  WithdrawPayment()
    function withdrawPayment(address payable receiver) external onlyOwner {
        require(block.timestamp >= endTime, "AUC: withdraw only after end time");
        require(totalPaymentWithdraw > 0 && winnerDeclared, "AUC: nothing to withdraw or winners not declared");
        uint256 amount = totalPaymentWithdraw;
        totalPaymentWithdraw = 0;
        (bool success, ) = receiver.call{value: amount}("");
        require(success, "AUC: failed to withdraw");
    }

    //  Refund()
    function refund() external {
        // the auction must end to be able claim eth back
        require(block.timestamp >= endTime && winnerDeclared, "AUC: withdraw only after end time and winner declared");
        address bidder = msg.sender;
        require(!isWinner(bidder), "AUC: must be not a winner");
        uint256 refundAmount = bidders[bidder].amount;
        bidders[bidder].amount = 0;
        (bool success, ) = bidder.call{value: refundAmount}("");
        require(success, "AUC: failed to refund");

        emit Refund(bidder, refundAmount);
    }

    // get total bids
    function totalBids() external view returns(uint256) {
        return ethAddresses.length;
    }

    // ListBids()
    function listBids(uint256 start, uint256 end) external view returns(BidderResponse[] memory) {
        require(end < ethAddresses.length, "AUC: invalid index");
        BidderResponse[] memory temp = new BidderResponse[](end - start);
        for (uint i = start; i < end; i++) {
            address tmp = ethAddresses[i];
            temp[i] = BidderResponse(tmp, isWinner(tmp), bidders[tmp].amount);
        }
        return temp;
    }

    //  GetBidsByAddress()
    function getBidsByAddress(address bidder) external view returns(bool, uint256) {
        return (isWinner(bidder), bidders[bidder].amount);
    }
}
