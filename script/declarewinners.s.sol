// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/auctioncollection.sol";
import "../lib/sortWinner.sol";

contract DeclareWinnersScript is Script, SortWinner {

    AuctionCollection public auction;
    uint256 public totalWinners;
    address payable public paymentAddress;

    function setUp() public {
        auction = AuctionCollection(vm.envAddress("AUCTION_ADDRESS"));
        totalWinners = uint256(vm.envInt("TOTAL_WINNERS"));
        paymentAddress = payable(vm.envAddress("PAYMENT_ADDRESS"));
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // sort winner list
        uint16[] memory winnerList = getSortedWinners(auction, totalWinners);

        // declare winner
        auction.declareWinners(winnerList, true);

        // withdraw payment
        auction.withdrawPayment(paymentAddress);
    }
}
