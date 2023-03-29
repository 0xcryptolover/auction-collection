// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract AuctionCollection is Ownable {
    uint256 public constant MAX_WINNERS = 512;

    struct Bidder {
        bool isWinner;
        address bidder;
        string btcAddr;
        uint256 amount;
    }

    // vars
    uint256 public endTime;
    uint256 public bidMinimum;
    uint256 private totalPaymentWithdraw;
    mapping(string => Bidder) private bidders;
    bool private winnerDeclared;
    mapping(string => bool) private isBtcExisted;
    string[] private btcAddresses;

    // events
    event Bid(address, string, uint256);
    event Refund(address, uint256);

    constructor(uint256 endTime_, uint256 bidMinimum_) {
        require(endTime_ > block.number, "AUC: invalid config params");
        endTime = endTime_;
        bidMinimum = bidMinimum_;
    }

    //    Bid(btc address, eth amount) // check min bid amount
    function bid(string calldata btcAddr, address bidder) external payable {
        uint256 bidAmount = msg.value;
        require(bytes(btcAddr).length != 0 && bidAmount >= bidMinimum && block.number < endTime, "AUC: btc address mut be not null and bid amount greater than minimum");
        if (bidders[btcAddr].amount == 0) {
            bidders[btcAddr] = Bidder(false, bidder, btcAddr, bidAmount);
        } else {
            bidders[btcAddr].amount += bidAmount;
        }

        if (!isBtcExisted[btcAddr]) {
            btcAddresses.push(btcAddr);
        }

        emit Bid(bidder, btcAddr, bidAmount);
    }

    // declare winners
    function declareWinners(string[] memory winners) external onlyOwner {
        require(block.number >= endTime,"AUC: auction not end yet");
        require(winners.length < MAX_WINNERS,"AUC: too many winners");
        uint256 _totalPaymentWithdraw;
        for (uint256 i = 0; i < winners.length; i++) {
            Bidder storage tmpBidder = bidders[winners[i]];
            require(!tmpBidder.isWinner && tmpBidder.amount > 0, "AUC: duplicate winner or invalid");
            _totalPaymentWithdraw += tmpBidder.amount;
            tmpBidder.isWinner = true;
        }
        winnerDeclared = true;
        totalPaymentWithdraw = _totalPaymentWithdraw;
    }

    //    WithdrawPayment()
    function withdrawPayment(address payable receiver) external onlyOwner {
        require(block.number >= endTime, "AUC: withdraw only after end time");
        require(totalPaymentWithdraw > 0 && winnerDeclared, "AUC: nothing to withdraw or winners not declared");
        uint256 amount = totalPaymentWithdraw;
        totalPaymentWithdraw = 0;
        (bool success, ) = receiver.call{value: amount}("");
        require(success, "AUC: failed to withdraw");
    }

    //    Refund()
    function refund(string calldata btcAddr) external {
        // the auction must end to be able claim eth back
        require(block.number >= endTime && winnerDeclared, "AUC: withdraw only after end time and winner declared");
        require(!bidders[btcAddr].isWinner, "AUC: must be not a winner");

        uint256 refundAmount = bidders[btcAddr].amount;
        bidders[btcAddr].amount = 0;
        (bool success, ) = bidders[btcAddr].bidder.call{value: refundAmount}("");
        require(success, "AUC: failed to refund");

        emit Refund(msg.sender, refundAmount);
    }

    // get total bids
    function totalBids() external view returns(uint256) {
        return btcAddresses.length;
    }

    // ListBids()
    function listBids(uint256 start, uint256 end) external view returns(Bidder[] memory) {
        require(end < btcAddresses.length, "AUC: invalid index");
        Bidder[] memory temp = new Bidder[](end - start);
        for (uint i = start; i < end; i++) {
            temp[i] = bidders[btcAddresses[i]];
        }
        return temp;
    }

    //  GetBidsByAddress()
    function getBidsByAddress(string calldata btcAddr) external view returns(Bidder memory) {
        return bidders[btcAddr];
    }
}
