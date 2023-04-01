// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../src/auctioncollection.sol";

contract SortWinner {

    struct BiddersIndex {
        uint16 index;
        uint256 amount;
        address bidder;
    }

    function getSortedWinners(AuctionCollection auction_, uint256 totalWinners_) public view returns (uint16[] memory sortedList) {
        uint256 totalBid = auction_.totalBids();
        BiddersIndex[] memory bidderListWithIndex = new BiddersIndex[](totalBid);
        AuctionCollection.BidderResponse[] memory bidderList = auction_.listBids(0, totalBid); // tested with 5000 records
        for (uint256 i = 0; i < bidderListWithIndex.length; i++) {
            bidderListWithIndex[i] = BiddersIndex(uint16(i), bidderList[i].amount, bidderList[i].bidder);
        }
        bidderListWithIndex = sort(bidderListWithIndex);
        uint256 winnerNumber = totalWinners_ > totalBid ? totalBid : totalWinners_;
        sortedList = new uint16[](winnerNumber);
        for (uint256 i = 0; i < totalWinners_; i++) {
            sortedList[i] = uint16(bidderListWithIndex[i].index);
        }
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
