// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/sendmulti/sendmultinft.sol";
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";

contract SendMulti is Test {
    SendMultiNft public smn;
    ERC721PresetMinterPauserAutoId public col1;
    ERC721PresetMinterPauserAutoId public col2;

    address public USER_1 = address(10);
    address public USER_2 = address(11);
    address public USER_3 = address(12);
    address public USER_4 = address(13);

    function setUp() public {
        smn = new SendMultiNft();
        col1 = new ERC721PresetMinterPauserAutoId("nft1", "1", "tc.com/");
        col1.mint(USER_1);
        col1.mint(USER_1);
        col1.mint(USER_1);

        col2 = new ERC721PresetMinterPauserAutoId("nft2", "2", "tc.com/");
        col2.mint(USER_2);
        col2.mint(USER_2);
        col2.mint(USER_2);
        col2.mint(USER_1);
        col2.mint(USER_1);
    }

    function testTransfer() public {

        SendMultiNft.SendInfo[] memory testData = new SendMultiNft.SendInfo[](2);
        testData[0].recipient = USER_3;
        uint[] memory indexes = new uint[](2);
        indexes[0] = 0;
        indexes[1] = 1;
        testData[0].ids = indexes;

        testData[1].recipient = USER_4;
        uint[] memory indexes2 = new uint[](1);
        indexes2[0] = 2;
        testData[1].ids = indexes2;

        // can not send if did not approve
        vm.startPrank(USER_1);
        vm.expectRevert("ERC721: caller is not token owner or approved");
        smn.sendMulti(col1, testData);

        // approve all
        col1.setApprovalForAll(address(smn), true);
        smn.sendMulti(col1, testData);
        vm.stopPrank();

        // check owner
        assertEq(col1.ownerOf(0), USER_3);
        assertEq(col1.ownerOf(1), USER_3);
        assertEq(col1.ownerOf(2), USER_4);

        // test safe transfer
        vm.startPrank(USER_2);
        SendMultiNft.SendInfo[] memory testData2 = new SendMultiNft.SendInfo[](1);
        testData2[0].recipient = address(smn);
        uint[] memory indexes3 = new uint[](3);
        indexes3[0] = 0;
        indexes3[1] = 1;
        indexes3[2] = 2;
        testData2[0].ids = indexes3;

        col2.setApprovalForAll(address(smn), true);
        vm.expectRevert("ERC721: transfer to non ERC721Receiver implementer");
        smn.safeSendMulti(col2, testData2);
        assertEq(col2.ownerOf(0), USER_2);

        testData2[0].recipient = USER_4;
        smn.safeSendMulti(col2, testData2);
        assertEq(col2.ownerOf(0), USER_4);
        assertEq(col2.ownerOf(1), USER_4);
        assertEq(col2.ownerOf(2), USER_4);

        vm.stopPrank();
    }
}
