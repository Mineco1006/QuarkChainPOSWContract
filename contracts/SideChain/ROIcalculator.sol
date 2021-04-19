// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import '../libraries/SafeMath.sol';

contract ROIcalculator {

    using SafeMath for uint256;

    address stakingPool;

    uint256 public timestamp1;
    uint256 public timestamp2;
    uint256 public timestamp3;

    mapping(uint256 => uint256) public snapshotBalance;

    constructor() {
        stakingPool = 0x94f151BBD12854f93cf92c882B88E3790F407956;
    }

    function takeNewSnapshot(uint16 snapshotNumber) public {
        require(snapshotNumber <= 3 && snapshotNumber > 0);
        if(snapshotNumber == 1){
            timestamp1 = block.timestamp;
            snapshotBalance[timestamp1] = stakingPool.balance;
        }
        if(snapshotNumber == 2){
            timestamp2 = block.timestamp;
            snapshotBalance[timestamp2] = stakingPool.balance;
        }
        if(snapshotNumber == 3){
            timestamp3 = block.timestamp;
            snapshotBalance[timestamp3] = stakingPool.balance;
        }
    }

    function calculateROI(uint16 snapshotNumber) public view returns(uint256){
        require(snapshotNumber <= 3 && snapshotNumber > 0);
        uint256 _snapshotBalance;
        uint256 timestamp;
        uint256 currentBalance = stakingPool.balance;

        if(snapshotNumber == 1){
            timestamp = timestamp1;
            _snapshotBalance = snapshotBalance[timestamp1];
        }
        if(snapshotNumber == 2){
            timestamp = timestamp2;
            _snapshotBalance = snapshotBalance[timestamp2];
        }
        if(snapshotNumber == 3){
            timestamp = timestamp3;
            _snapshotBalance = snapshotBalance[timestamp3];
        }

        return (currentBalance.sub(_snapshotBalance).mul(1 ether).div(currentBalance)).div(block.timestamp.sub(timestamp)).mul(30 days);
    }
}