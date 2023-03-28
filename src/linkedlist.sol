// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract LinkedListLib {
    struct Node {
        address receiver;
        uint256 value;
        uint256 lastDeposit;
        uint256 height;
        uint64 prev;
        uint64 next;
    }

    struct NodeWithId {
        uint64 id;
        Node info;
    }

    struct LinkedList {
        uint64 headId;
        uint64 tailId;
        uint64 length;
    }

    mapping(uint64 => Node) public nodeList;
    mapping(address => uint64) public suppliers;
    LinkedList public linkedList;

    function getNodeById(uint64 nodeId) view public returns(Node memory) {
        return nodeList[nodeId];
    }

    function getNodeByAddress(address supplier) view public returns(Node memory) {
        uint64 nodeId = suppliers[supplier];
        if (nodeId == 0) {
            revert("invalid supplier");
        }
        return nodeList[nodeId];
    }

    function getIdByAddress(address supplier) view public returns(uint64) {
        return suppliers[supplier];
    }

    function addNode(address receiver, uint256 value, uint256 lastDeposit, uint256 height) internal returns(uint64) {
        uint64 newNodePrev = 0;
        uint64 newNodeId = linkedList.tailId + 1;
        if (linkedList.length == 0) {
            // empty LinkedList
            linkedList.headId = newNodeId;
        } else {
            // append to tail
            nodeList[linkedList.tailId].next = newNodeId;
            newNodePrev = linkedList.tailId;
        }
        // create new node
        nodeList[newNodeId] = Node(receiver, value, lastDeposit, height, newNodePrev, 0);
        suppliers[receiver] = newNodeId;

        // update linked list
        linkedList.tailId = newNodeId;
        linkedList.length += 1;

        return newNodeId;
    }

    function removeNode(uint64 nodeId) internal {
        require(nodeList[nodeId].height != 0, "remove non-exist node id");
        Node memory node = nodeList[nodeId];
        if (node.prev != 0) {
            nodeList[node.prev].next = node.next;
        } else {
            linkedList.headId = node.next;
        }

        if (node.next != 0) {
            nodeList[node.next].prev = node.prev;
        } else {
            linkedList.tailId = node.prev;
        }

        delete nodeList[nodeId];
        delete suppliers[node.receiver];
        linkedList.length -=1;
    }

    function updateNode(uint64 nodeId, Node memory node) internal {
        require(nodeList[nodeId].height != 0, "update non-exist node id");
        nodeList[nodeId] = node;
    }
}
