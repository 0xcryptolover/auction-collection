// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/auctioncollection.sol";

contract AuctionCollectionTest is Test {
    AuctionCollection public ac;
    event Refund(address, uint256);

    function setUp() public {
        ac = new AuctionCollection(1000, 1e10);
    }

    function testBids() public {
        address user;

        for (uint i = 1; i < 522; i ++) {
            user = address(uint160(i));
            vm.prank(user);
            vm.deal(user, i * 1e10);
            ac.bid{value: i * 1e10}();
        }
        user = address(uint160(1));
        assertEq(ac.totalBids(), 521);
        (bool isWinner, uint256 bidAmount) = ac.getBidsByAddress(user);
        assertEq(isWinner, false);
        assertEq(bidAmount, 1e10);

        user = address(uint160(1));
        vm.prank(user);
        vm.deal(user, 1e1);
        vm.expectRevert("AUC: auction must be open and bid amount greater than minimum");
        ac.bid{value: 1e1}();

        user = address(uint160(2000));
        vm.prank(user);
        vm.deal(user, 2e10);
        ac.bid{value: 2e10}();

        (isWinner, bidAmount) = ac.getBidsByAddress(user);
        assertEq(isWinner, false);
        assertEq(bidAmount, 2e10);

        // roll to end time
        vm.warp(1001);
        user = address(uint160(523));
        vm.prank(user);
        vm.deal(user, 1e10);
        vm.expectRevert("AUC: auction must be open and bid amount greater than minimum");
        ac.bid{value: 1e10}();

        // declare winners
        uint256 verifyWithdrawAmount;
        uint16[] memory winners = new uint16[](100);
        for (uint16 i = 0; i < uint16(winners.length); i ++) {
            winners[i] = i;
            verifyWithdrawAmount += (i + 1) * 1e10;
        }
        vm.prank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        ac.declareWinners(winners, true);

        winners[0] = 1;
        vm.expectRevert("AUC: duplicate winner");
        ac.declareWinners(winners, true);

        winners[0] = 0;
        ac.declareWinners(winners, true);

        winners[0] = 0;
        vm.expectRevert("AUC: auction not end yet or winner declared");
        ac.declareWinners(winners, true);

        user = address(uint160(1));
        (isWinner,)  = ac.getBidsByAddress(user);
        assertEq(isWinner, true);

        // withdraw payments
        address payable receiver = payable(address(uint160(1000)));
        vm.prank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        ac.withdrawPayment(receiver);

        ac.withdrawPayment(receiver);
        assertEq(verifyWithdrawAmount, receiver.balance);

        // request refund
        for (uint i = 101; i < 522; i ++) {
            user = address(uint160(i));
            vm.prank(user);
            vm.expectEmit(false, false, false, true);
            emit Refund(user, i * 1e10);
            ac.refund();
            assertEq(user.balance, i * 1e10);
        }

        // user request refund many times
        user = address(uint160(101));
        vm.prank(user);
        vm.expectEmit(false, false, false, true);
        emit Refund(user, 0);
        ac.refund();
        assertEq(user.balance, 101 * 1e10);

        // test get functions
        ac.listBids(0, 100);

        vm.expectRevert("AUC: user did not bid yet");
        ac.getBidsByAddress(address(uint160(3000)));
    }
}
