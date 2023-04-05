// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/auctioncollection.sol";
import "../lib/sortWinner.sol";
import "../src/auctioncollection2.sol";

contract DeclareWinnersScript is Script, SortWinner {

    AuctionCollection public auction;
    AuctionCollection2 public auction2;
    uint256 public totalWinners;
    address payable public paymentAddress;

    function setUp() public {
        auction = AuctionCollection(vm.envAddress("AUCTION_ADDRESS"));
        auction2 = AuctionCollection2(vm.envAddress("AUCTION_ADDRESS_V2"));
        totalWinners = uint256(vm.envInt("TOTAL_WINNERS"));
        paymentAddress = payable(vm.envAddress("PAYMENT_ADDRESS"));
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // sort winner list
        (uint16[] memory winnerList, uint32[] memory winnerList2)  = getSortedWinners2(auction, auction2, totalWinners);

        // declare winner
        auction.declareWinners(winnerList, true);

        // withdraw payment
        auction.withdrawPayment(paymentAddress);

        // @dev v2
        auction2.declareWinners(winnerList2, true);

        // withdraw payment
        auction2.withdrawPayment(paymentAddress);
    }
}
