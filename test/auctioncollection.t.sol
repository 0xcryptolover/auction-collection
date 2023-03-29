// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/auctioncollection.sol";

contract AuctionCollectionTest is Test {
    AuctionCollection public ac;

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
            ac.bid{value: i * 1e10}(btcAddr);
        }
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
