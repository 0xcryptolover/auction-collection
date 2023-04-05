// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/auctioncollection.sol";
import "../src/auctioncollection2.sol";
import "../src/transparentUpgrade/transparentUpgradeableProxy.sol";
import "../lib/sortWinner.sol";

contract AuctionCollectionTest is Test, SortWinner {
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

    function testDeclareWinnerScript() public {
        address user;
        address payable paymentReceiver = payable(address(uint160(4000)));

        for (uint i = 1; i < 5001; i ++) {
            user = address(uint160(i));
            vm.prank(user);
            vm.deal(user, (i % 3 + 1) * 1e10);
            ac.bid{value: (i % 3 + 1) * 1e10}();
        }

        // roll to end time
        vm.warp(1001);

        uint16[] memory winnerList = getSortedWinners(ac, 512);
        ac.declareWinners(winnerList, true);
        ac.withdrawPayment(paymentReceiver);

        assertEq(paymentReceiver.balance != 0, true);
    }

    function testAuction2() public {
        address POOL_ADMIN_UPGRADE = address(uint160(123123));
        AuctionCollection2 imp = new AuctionCollection2();
        AuctionCollection2 ac2 = AuctionCollection2(address(new TransparentUpgradeableProxy(address(imp), POOL_ADMIN_UPGRADE, abi.encodeWithSelector(AuctionCollection2.initialize.selector, ac))));
        address user;

        for (uint i = 1; i < 200; i ++) {
            user = address(uint160(i));
            vm.prank(user);
            vm.deal(user, i * 1e17);
            ac.bid{value: i * 1e17}();
        }

        for (uint i = 100; i < 522; i ++) {
            user = address(uint160(i));
            vm.prank(user);
            vm.deal(user, i * 1e17);
            ac2.bid{value: i * 1e17}(1e17);
        }

        // test value matches
        user = address(uint160(150));
        (bool isWinner, AuctionCollection2.Bidder memory bidder) = ac2.getBidsByAddress(user);
        assertEq(bidder.index, 51);
        assertEq(bidder.unitPrice, 1e17);
        assertEq(bidder.quantity, 300);
        assertEq(bidder.amount, 150 * 1e17);
        assertEq(isWinner, false);

        user = address(uint160(250));
        (isWinner, bidder) = ac2.getBidsByAddress(user);
        assertEq(isWinner, false);
        assertEq(bidder.index, 151);
        assertEq(bidder.unitPrice, 1e17);
        assertEq(bidder.quantity, 250);
        assertEq(bidder.amount, 250 * 1e17);
        assertEq(isWinner, false);

        user = address(uint160(1000));
        vm.startPrank(user);
        vm.deal(user, 20 * 1e17);
        vm.expectRevert("AUC: auction must be open and bid amount greater than minimum");
        ac2.bid(1e17);

        vm.expectRevert("AUC: auction must be open and bid amount greater than minimum");
        ac2.bid{value: 1e17}(1);

        vm.expectRevert("AUC: invalid bid amount, unit price");
        ac2.bid{value: 1e17}(1e10 + 1);

        vm.expectRevert("AUC: invalid bid amount, unit price");
        ac2.bid{value: 1e17}(1e10 + 1);

        ac2.bid{value: 1e17}(1e17);

        // buy 4 items
        ac2.bid{value: 3e17}(1e17);

        // buy 2 items
        vm.expectRevert("AUC: invalid bid amount, unit price");
        ac2.bid(2e17);

        vm.expectRevert("AUC: invalid bid amount, unit price");
        ac2.bid{value: 1e16}(1e17);

        vm.expectRevert("AUC: invalid bid amount, unit price");
        ac2.bid{value: 1e17}(1e16);

        // roll to end time
        vm.warp(1001);
        vm.expectRevert("AUC: auction must be open and bid amount greater than minimum");
        ac2.bid{value: 1e17}(1e17);
        vm.stopPrank();

        // declare winners
        uint32[] memory winners = new uint32[](2);
        winners[0] = 50;
        winners[1] = 150;
        ac2.declareWinners(winners, true);

        // withdraw money
        user = address(uint160(2000));
        ac2.withdrawPayment(payable(user));
        assertEq(user.balance, 400 * 1e17);

        uint16[] memory winners2 = new uint16[](1);
        winners2[0] = 149;
        ac.declareWinners(winners2, true);
        ac.withdrawPayment(payable(user));
        assertEq(user.balance, 550 * 1e17);

        // refund
        user = address(uint160(100));
        vm.prank(user);
        ac2.refund();
        assertEq(user.balance, 100 * 1e17);
    }
}
