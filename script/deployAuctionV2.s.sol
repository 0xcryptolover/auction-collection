// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../lib/sortWinner.sol";
import "../src/auctioncollection2.sol";
import "../src/transparentUpgrade/transparentUpgradeableProxy.sol";

contract DeployAuc2 is Script, SortWinner {

    address public auction;
    address public updateAddress;

    function setUp() public {
        auction = vm.envAddress("AUCTION_ADDRESS_V1");
        updateAddress =  vm.envAddress("UPGRADE_ADDRESS");
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy auc 2 implementation
        AuctionCollection2 aucImp = new AuctionCollection2();

        // deploy auc 2  contract
        AuctionCollection2(address(new TransparentUpgradeableProxy(
                address(aucImp),
                updateAddress,
                abi.encodeWithSelector(AuctionCollection2.initialize.selector, auction)
        )));
    }
}
