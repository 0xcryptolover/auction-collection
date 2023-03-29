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

        string memory btcAddr;
        for (uint i = 1; i < 522; i ++) {
            btcAddr = numberToString(i);
            user = address(uint160(i));
            vm.prank(user);
            vm.deal(user, i * 1e10);
            ac.bid{value: i * 1e10}(btcAddr, user);
        }
        assertEq(ac.totalBids(), 521);
        AuctionCollection.Bidder memory tmp = ac.getBidsByAddress(numberToString(1));
        assertEq(tmp.btcAddr, numberToString(1));
        assertEq(tmp.bidder, address(uint160(1)));
        assertEq(tmp.amount, 1e10);

        user = address(uint160(1));
        vm.prank(user);
        vm.deal(user, 1e10);
        vm.expectRevert("AUC: btc address mut be not null and bid amount greater than minimum");
        ac.bid{value: 1e10}("", user);

        vm.prank(user);
        ac.bid{value: 1e10}(numberToString(1), user);

        tmp = ac.getBidsByAddress(numberToString(1));
        assertEq(tmp.btcAddr, numberToString(1));
        assertEq(tmp.bidder, address(uint160(1)));
        assertEq(tmp.amount, 2e10);

        // roll to end time
        vm.roll(1001);
        user = address(uint160(523));
        vm.prank(user);
        vm.deal(user, 1e10);
        vm.expectRevert("AUC: btc address mut be not null and bid amount greater than minimum");
        ac.bid{value: 1e10}(numberToString(523), user);

        // declare winners
        uint256 verifyWithdrawAmount = 1e10;
        string[] memory winners = new string[](100);
        for (uint i = 0; i < 100; i ++) {
            winners[i] = numberToString(i+1);
            verifyWithdrawAmount += (i + 1) * 1e10;
        }
        vm.prank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        ac.declareWinners(winners);

        winners[0] = numberToString(0);
        vm.expectRevert("AUC: duplicate winner or invalid");
        ac.declareWinners(winners);

        winners[0] = numberToString(1);
        winners[1] = numberToString(1);
        vm.expectRevert("AUC: duplicate winner or invalid");
        ac.declareWinners(winners);

        winners[1] = numberToString(2);
        ac.declareWinners(winners);

        tmp = ac.getBidsByAddress(numberToString(1));
        assertEq(tmp.isWinner, true);

        // withdraw payments
        address payable receiver = payable(address(uint160(1000)));
        vm.prank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        ac.withdrawPayment(receiver);

        ac.withdrawPayment(receiver);
        assertEq(verifyWithdrawAmount, receiver.balance);

        // request refund
        for (uint i = 101; i < 522; i ++) {
            btcAddr = numberToString(i);
            user = address(uint160(i));
            vm.prank(user);
            vm.expectEmit(false, false, false, true);
            emit Refund(user, i * 1e10);
            ac.refund(btcAddr);
            assertEq(user.balance, i * 1e10);
        }

        // user request refund many times
        btcAddr = numberToString(101);
        user = address(uint160(101));
        vm.prank(user);
        vm.expectEmit(false, false, false, true);
        emit Refund(user, 0);
        ac.refund(btcAddr);
        assertEq(user.balance, 101 * 1e10);

        // test get functions
        ac.listBids(0, 100);
    }

    /**
     * @dev convert enum to string value
     */
    function numberToString(uint erroNum) internal pure returns(string memory) {
        uint maxlength = 10;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (erroNum != 0) {
            uint8 remainder = uint8(erroNum % 10);
            erroNum = erroNum / 10;
            reversed[i++] = bytes1(48 + remainder);
        }
        bytes memory s = new bytes(i + 1);
        for (uint j = 0; j <= i; j++) {
            s[j] = reversed[i - j];
        }
        return string(s);
    }
}
