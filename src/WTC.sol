// SPDX-License-Identifier: UNLICENSED
/**
 *Submitted for verification at Etherscan.io on 2017-12-12
*/

// Copyright (C) 2015, 2016, 2017 Dapphub

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract WTC is Ownable, ERC20 {
   constructor() ERC20("Wrapped Trustless Computer", "WTC") {}

   event MultiMint(address[], uint[]);
   event Burn(address, uint256);

   function multiMint(address[] memory receivers, uint256[] memory amounts) external onlyOwner {
       require(receivers.length == amounts.length, "WTC: input mismatch");
       require(receivers.length > 0, "WTC: list of receivers must no empty");

       for (uint i = 0; i < receivers.length; i++) {
           require(amounts[i] > 0, "WTC: mint amount must be positive");
           _mint(receivers[i], amounts[i]);
       }

       emit MultiMint(receivers, amounts);
   }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);

        emit Burn(msg.sender, amount);
    }

    function burn(address to, uint256 amount) external {
        _burn(msg.sender, amount);

        emit Burn(to, amount);
    }
}