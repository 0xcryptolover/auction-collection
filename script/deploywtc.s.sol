// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../lib/sortWinner.sol";
import "../src/auctioncollection2.sol";
import "../src/transparentUpgrade/transparentUpgradeableProxy.sol";
import "../src/tc.sol";
import "../src/WTC.sol";

contract DeployWTC is Script, SortWinner {

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        string memory network = vm.envString("NETWORK");
        vm.startBroadcast(deployerPrivateKey);

        if (keccak256(abi.encodePacked(network)) == keccak256(abi.encodePacked("tc"))) {
            // tc
            uint256 fee = vm.envUint("FEE");
            new TC(fee);
        } else if (keccak256(abi.encodePacked(network)) == keccak256(abi.encodePacked("goerli"))) {
            // goerli
            new WTC();
        } else {
            revert("not known network");
        }

    }
}