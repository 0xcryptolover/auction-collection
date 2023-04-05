// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../src/auctioncollection.sol";
import "../src/auctioncollection2.sol";

contract SortWinner {

    enum AuctionType {
        v1,
        v2,
        both
    }

    struct BiddersIndex {
        uint32 index;
        uint32 index2;
        uint256 amount;
        address bidder;
        AuctionType auctionType;
        uint32 quantity;
    }

    mapping(address => uint256) public isInV2;
    BiddersIndex[] public biddersInfo;
    uint16[] public sortedListV1;
    uint32[] public sortedListV2;

    function getSortedWinners(AuctionCollection auction_, uint256 totalWinners_) public view returns (uint16[] memory sortedList) {
        uint256 totalBid = auction_.totalBids();
        BiddersIndex[] memory bidderListWithIndex = new BiddersIndex[](totalBid);
        AuctionCollection.BidderResponse[] memory bidderList = auction_.listBids(0, totalBid); // tested with 5000 records
        for (uint256 i = 0; i < bidderListWithIndex.length; i++) {
            bidderListWithIndex[i] = BiddersIndex(uint16(i), 0, bidderList[i].amount, bidderList[i].bidder, AuctionType.v1, 1);
        }
        bidderListWithIndex = sort(bidderListWithIndex);
        uint256 winnerNumber = totalWinners_ > totalBid ? totalBid : totalWinners_;
        sortedList = new uint16[](winnerNumber);
        for (uint256 i = 0; i < totalWinners_; i++) {
            sortedList[i] = uint16(bidderListWithIndex[i].index);
        }
    }

    function getSortedWinners2(AuctionCollection auction_, AuctionCollection2 auction2_, uint256 totalWinners_) public returns (uint16[] memory sortedList, uint32[] memory sortedList2) {
        uint256 totalBidV2 = auction2_.totalBids();
        AuctionCollection2.BidderResponse[] memory listBidV2 = auction2_.listBids(0, totalBidV2);
        uint256 totalQty;
        for (uint256 i = 0; i < totalBidV2; i++) {
            biddersInfo.push(BiddersIndex(0, uint32(i), uint256(listBidV2[i].bidderInfo.unitPrice), listBidV2[i].bidder, AuctionType.v2, listBidV2[i].bidderInfo.quantity));
            isInV2[listBidV2[i].bidder] = biddersInfo.length;
            totalQty += listBidV2[i].bidderInfo.quantity;
        }

        // get v1
        uint256 totalBid = auction_.totalBids();
        AuctionCollection.BidderResponse[] memory listBid = auction_.listBids(0, totalBid);
        for (uint256 i = 0; i < totalBid; i++) {
            if (isInV2[listBid[i].bidder] != 0) {
                biddersInfo[isInV2[listBid[i].bidder] - 1].index = uint32(i);
                biddersInfo[isInV2[listBid[i].bidder] - 1].auctionType = AuctionType.both;
            } else {
                biddersInfo.push(BiddersIndex(uint32(i), 0, listBid[i].amount, listBid[i].bidder, AuctionType.v1, 1));
                totalQty++;
            }
        }
        uint256 lastNumerOfWinner = totalWinners_ > totalQty ? totalQty : totalWinners_;

        BiddersIndex[] memory results = sort(biddersInfo);
        uint counted;
        for (uint256 i = 0; i < results.length && counted <= lastNumerOfWinner; i++) {
            if (results[i].auctionType == AuctionType.both) {
                sortedListV1.push(uint16(results[i].index));
                sortedListV2.push(uint32(results[i].index2));
            } else if (results[i].auctionType == AuctionType.v1) {
                sortedListV1.push(uint16(results[i].index));
            } else {
                sortedListV2.push(uint32(results[i].index2));
            }
            counted += results[i].quantity;
        }

        return (sortedListV1, sortedListV2);
    }

    // bubble sort
    function sort(BiddersIndex[] memory array) public pure returns (BiddersIndex[] memory) {

        bool swapped;
        for (uint i = 1; i < array.length; i++) {
            swapped = false;
            for (uint j = 0; j < array.length - i; j++) {
                BiddersIndex memory next = array[j + 1];
                BiddersIndex memory actual = array[j];
                if (next.amount > actual.amount) {
                    array[j] = next;
                    array[j + 1] = actual;
                    swapped = true;
                }
            }
            if (!swapped) {
                return array;
            }
        }

        return array;
    }
}
