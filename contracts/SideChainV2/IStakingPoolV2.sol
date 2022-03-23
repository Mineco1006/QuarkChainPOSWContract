//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IStakingPoolV2 {
    struct PoolStats {
        uint256 balance;
        uint256 minStake;
        uint256 roiMon;
        uint16 poolFee;
        uint16 minerFee;
        bool isClosed;
    }

    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function getStake(address staker) external view returns(uint256);
    function getPoolStats() external view returns(PoolStats memory);
}
