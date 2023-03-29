// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract LinkedListLib {
    struct Node {
        uint32 prev;
        uint32 next;
        address bidder;
        uint256 amount;
        string btcAddr;
    }

    struct LinkedList {
        uint32 headId;
        uint32 tailId;
        uint32 length;
    }

    uint16 public constant MAX_COLLECTION = 512;
    mapping(uint32 => Node) public nodeList;
    mapping(address => uint32) public bidders;
    // todo: update for search efficiency
    uint32[] public layer2 = new uint32[](50);
    LinkedList public linkedList;

    function getNodeById(uint32 nodeId) view public returns(Node memory) {
        return nodeList[nodeId];
    }

    function getNodeByAddress(address bidder) view public returns(Node memory) {
        uint32 nodeId = bidders[bidder];
        if (nodeId == 0) {
            revert("invalid bidder");
        }
        return nodeList[nodeId];
    }

    function getIdByAddress(address bidder) view public returns(uint32) {
        return bidders[bidder];
    }

    function removeNode(uint32 nodeId) internal returns(address, uint256) {
        require(nodeList[nodeId].bidder != address(0), "remove non-exist node id");
        Node memory node = nodeList[nodeId];
        if (node.prev != 0) {
            nodeList[node.prev].next = node.next;
        } else {
            linkedList.headId = node.next;
        }

        if (node.next != 0) {
            nodeList[node.next].prev = node.prev;
        } else {
            emit logs(node.bidder, linkedList.tailId, node.prev);
            linkedList.tailId = node.prev;
        }

        delete nodeList[nodeId];
        delete bidders[node.bidder];
        linkedList.length -=1;

        return (node.bidder, node.amount);
    }

    function updateNode(uint32 nodeId, Node memory node) internal {
        require(nodeList[nodeId].bidder != address(0), "update non-exist node id");
        nodeList[nodeId] = node;
    }

    event logs(address, uint64, uint64);

    // return address and amount removed from top 512
    function addNodeSorted(address bidder, string memory btcAddr, uint256 amount) internal returns(address, uint256) {
        uint32 newNodeId = linkedList.tailId + 1;
        uint256 lastBidAmount = amount;
        address removedAddr;
        uint256 removedAmount;
        if (linkedList.length == 0) {
            // empty LinkedList
            linkedList.headId = newNodeId;
            linkedList.tailId = newNodeId;
            linkedList.length = 1;
            nodeList[newNodeId] = Node(0, 0, bidder, lastBidAmount, btcAddr);
            return (removedAddr, removedAmount);
        } else if (bidders[bidder] > 0) {
            // bidder existed in list
            uint32 currentIndex = bidders[bidder];
            if (linkedList.length == 1) {
                nodeList[currentIndex].amount += amount;
                return (removedAddr, removedAmount);
            }
            require(keccak256(abi.encodePacked(nodeList[currentIndex].btcAddr)) == keccak256(abi.encodePacked(btcAddr)), "AUC: btc address not match prev bid");
            lastBidAmount += nodeList[currentIndex].amount;
            removeNode(currentIndex);
        }

        //todo: simple search will improve with skip linkedlist
        uint32 id = linkedList.tailId;
        for (uint32 i = 0; i < linkedList.length; i++) {
            if (lastBidAmount > nodeList[id].amount) {
                id = nodeList[id].prev;
            } else {
                break;
            }
        }
        if (id == linkedList.tailId) {
            linkedList.tailId = newNodeId;
            nodeList[id].next = newNodeId;
            nodeList[newNodeId] = Node(id, 0, bidder, lastBidAmount, btcAddr);
        } else if (id == 0) {
            uint32 headId = linkedList.headId;
            nodeList[headId].prev = newNodeId;
            nodeList[newNodeId] = Node(0, headId, bidder, lastBidAmount, btcAddr);
            linkedList.headId = newNodeId;
        } else {
            uint32 nextTemp = nodeList[id].next;
            nodeList[id].next = newNodeId;
            nodeList[nextTemp].prev = newNodeId;
            nodeList[newNodeId] = Node(id, nextTemp, bidder, lastBidAmount, btcAddr);
        }

        linkedList.length++;
        // remove if linkedlist reaches max number
        if (linkedList.length > MAX_COLLECTION) {
            (removedAddr, removedAmount) = removeNode(linkedList.tailId);
        }
        return (removedAddr, removedAmount);
    }
}
