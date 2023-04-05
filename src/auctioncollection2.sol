// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./auctioncollection.sol";
import "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

contract AuctionCollection2 is Ownable, Initializable {
    uint256 public constant MAX_WINNERS = 512;
    address public singleAuction;

    struct BidderResponse {
        address bidder;
        bool isWinner;
        Bidder bidderInfo;
    }

    struct Bidder {
        uint128 amount;
        uint64 unitPrice; // max 18 eth per nft
        uint32 index;
        uint32 quantity;
    }

    // vars
    uint256 public endTime;
    uint256 public bidMinimum;
    uint256 private totalPaymentWithdraw;
    bool public winnerDeclared;
    mapping(address => Bidder) private bidders;
    address[] private ethAddresses;

    // initializer
    function initialize(
        AuctionCollection singleAuction_
    ) external initializer {
        endTime = singleAuction_.endTime();
        bidMinimum = singleAuction_.bidMinimum();
        singleAuction = address(singleAuction_);
        _transferOwnership(_msgSender());
    }

    //    Bid(btc address, eth amount) // check min bid amount
    function bid(uint64 unitPrice) external payable {
        address bidder = msg.sender;
        uint256 bidAmount;
        (bool success, bytes memory data) = singleAuction.staticcall(
            abi.encodeWithSelector(
                AuctionCollection.getBidsByAddress.selector,
                msg.sender
            )
        );

        if (success) {
            (, bidAmount) = abi.decode(data, (bool, uint256));
        }

        bidAmount += (msg.value + bidders[bidder].amount);
        require(bidAmount > 0 && unitPrice >= bidMinimum && block.timestamp < endTime, "AUC: auction must be open and bid amount greater than minimum");
        require(unitPrice >= bidders[bidder].unitPrice && bidAmount % unitPrice == 0 && uint32(bidAmount / unitPrice) >= bidders[bidder].quantity, "AUC: invalid bid amount, unit price");

        bidders[bidder].amount += uint128(msg.value);
        bidders[bidder].quantity = uint32(bidAmount / unitPrice);
        bidders[bidder].unitPrice = unitPrice;

        if (bidders[bidder].index == 0) {
            ethAddresses.push(bidder);
            bidders[bidder].index = uint32(ethAddresses.length);
        }
    }

    // declare winners
    function declareWinners(uint32[] memory winnerList, bool isFinal) external onlyOwner {
        require(block.timestamp >= endTime && !winnerDeclared,"AUC: auction not end yet or winner declared");
        require(winnerList.length <= MAX_WINNERS ,"AUC: too many winners");
        uint256 _totalPaymentWithdraw;
        for (uint256 i = 0; i < winnerList.length; i++) {
            address temp = ethAddresses[winnerList[i]];
            require(temp != address(0), "AUC: duplicate winner");
            ethAddresses[winnerList[i]] = address(0);
            _totalPaymentWithdraw += uint256(bidders[temp].amount);
        }
        winnerDeclared = isFinal;
        totalPaymentWithdraw += _totalPaymentWithdraw;
    }

    function isWinner(address bidder) internal view returns(bool) {
        uint128 bidderIndex = bidders[bidder].index;
        if (!winnerDeclared || bidderIndex == 0) {
            return false;
        }
        return ethAddresses[bidderIndex - 1] == address(0);
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
        uint256 refundAmount = uint256(bidders[bidder].amount);
        bidders[bidder].amount = 0;
        (bool success, ) = bidder.call{value: refundAmount}("");
        require(success, "AUC: failed to refund");
    }

    // get total bids
    function totalBids() external view returns(uint256) {
        return ethAddresses.length;
    }

    // ListBids()
    function listBids(uint256 start, uint256 end) external view returns(BidderResponse[] memory) {
        require(end <= ethAddresses.length, "AUC: invalid index");
        BidderResponse[] memory temp = new BidderResponse[](end - start);
        for (uint i = start; i < end; i++) {
            address tmp = ethAddresses[i];
            temp[i - start] = BidderResponse(tmp, isWinner(tmp), bidders[tmp]);
        }
        return temp;
    }

    //  GetBidsByAddress()
    function getBidsByAddress(address bidder) external view returns(bool, Bidder memory) {
        require(bidders[bidder].index != 0, "AUC: user did not bid yet");
        return (isWinner(bidder), bidders[bidder]);
    }

    function withdrawAll() external onlyOwner {
        require(block.timestamp >= endTime, "AUC: auction not ended yet");
        (bool success, ) = _msgSender().call{value: address(this).balance}("");
        require(success, "AUC: failed to withdraw all");
    }
}
