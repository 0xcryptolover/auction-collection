// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

contract SendMultiNft {
    struct SendInfo {
        address recipient;
        uint[] ids;
    }

    function sendMulti(IERC721 token, SendInfo[] memory sendInfos) external {
        address from = msg.sender;
        for (uint i = 0; i < sendInfos.length; i++) {
            for (uint j = 0; j < sendInfos[i].ids.length; j++) {
                token.transferFrom(from, sendInfos[i].recipient, sendInfos[i].ids[j]);
            }
        }
    }

    function safeSendMulti(IERC721 token, SendInfo[] memory sendInfos) external {
        address from = msg.sender;
        for (uint i = 0; i < sendInfos.length; i++) {
            for (uint j = 0; j < sendInfos[i].ids.length; j++) {
                token.safeTransferFrom(from, sendInfos[i].recipient, sendInfos[i].ids[j]);
            }
        }
    }

    function sendMulti(IERC721 token, address[] memory recipients, uint[] memory ids) external {
        require(recipients.length == ids.length, "SendMulti: mismatch input params");

        address from = msg.sender;
        for (uint i = 0; i < recipients.length; i++) {
            token.transferFrom(from, recipients[i], ids[i]);
        }
    }

    function safeSendMulti(IERC721 token, address[] memory recipients, uint[] memory ids) external {
        require(recipients.length == ids.length, "SendMulti: mismatch input params");

        address from = msg.sender;
        for (uint i = 0; i < recipients.length; i++) {
            token.safeTransferFrom(from, recipients[i], ids[i]);
        }
    }
}
