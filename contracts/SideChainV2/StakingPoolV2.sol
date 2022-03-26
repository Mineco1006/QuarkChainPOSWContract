// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IStakingPoolV2.sol";

contract StakingPoolV2 is Ownable, IStakingPoolV2 {

    address payable public miner;

    uint256 public minStake;
    uint16 public minerFee;
    uint16 public poolFee;
    bool public isClosed;

    address payable[] private user;
    mapping(address => uint256) private userArrPos;
    uint256 public totalStake;
    mapping(address => uint256) private userStake;

    uint256 public snapshotTimestamp;
    uint256 public snapshotBalance;

    constructor() {
        user.push(payable(msg.sender));
        user.push(miner);
        userArrPos[miner] = 1;
    }

    function getStake(address staker) public view override returns (uint256) {
        address contractAddress = address(this);

        if(totalStake == 0) {
            return 0;
        }

        uint256 dividend = contractAddress.balance - totalStake;
        uint256 adjustedValue = dividend - ((dividend * (minerFee + poolFee))/(10000));
        uint256 reward = (userStake[staker] * adjustedValue)/(totalStake);

        
        if(staker == owner()) {
            reward += (dividend * poolFee)/10000;
        }
        if(staker == miner) {
            reward += (dividend * minerFee)/10000;
        }
        return userStake[staker] + reward;
    }

    receive() external payable {
        require(isClosed == false, 'Pool is closed');

        updateStakes();

        if(msg.value != 0) {
            deposit();
        }
    }

    function deposit() public payable override {
        if(msg.sender != user[0] && msg.sender != user[1] && userStake[msg.sender] == 0) {
            require(msg.value >= minStake);
            user.push(payable(msg.sender));
            userArrPos[msg.sender] = user.length - 1;
        }
        userStake[msg.sender] += msg.value;
        totalStake += msg.value;
    }

    function withdraw(uint256 amount) public override {
        require(getStake(msg.sender) >= amount);
        updateStakes();
        require(userStake[msg.sender] >= amount);
        payable(msg.sender).transfer(amount);
        userStake[msg.sender] -= amount;
        totalStake -= amount;

        if(msg.sender != user[0] && msg.sender != user[1] && userStake[msg.sender] == 0) delete user[userArrPos[msg.sender]];
    }

    function getPoolStats() public view override returns(PoolStats memory) {
        address contractAddress = address(this);

        return PoolStats({balance: contractAddress.balance, minStake: minStake, roiMon: getROI(), poolFee: poolFee, minerFee: minerFee, isClosed: isClosed});
    }

    //Miner functions
    function adjustMinerFee(uint16 amount) public {
        require(msg.sender == owner() || msg.sender == miner);
        require(amount <= 9000);
        updateStakes();
        minerFee = amount;
    }

    function changeMiner(address payable _miner) public {
        require(msg.sender == miner);
        miner = _miner;
    }

    //Owner functions
    function changePoolStatus(bool status) public onlyOwner() {
        isClosed = status;
    }

    function adjustMinStake(uint256 _minStake) public onlyOwner() {
        minStake = _minStake;
    }

    function adjustPoolFee(uint16 amount) public onlyOwner() {
        require(amount <= 500);
        updateStakes();
        poolFee = amount;
    }

    function disposeContract() public onlyOwner() {
        updateStakes();
        for(uint16 i; i < user.length; i++) {
            user[i].transfer(userStake[user[i]]);
            userStake[user[i]] = 0;
            delete user[i];
        }
        totalStake = 0;
        isClosed = true;
    }

    //Internal functions
    function updateStakes() internal {

        updateSnapshot();
        
        address contractAddress = address(this);
        snapshotBalance = contractAddress.balance;
        snapshotTimestamp = block.timestamp;
        
        if(contractAddress.balance - (msg.value + totalStake)  > 0){

            uint256 dividend = contractAddress.balance - (msg.value + totalStake);
            uint256 _minerFee = (dividend * minerFee)/10000;
            uint256 _poolFee = (dividend * poolFee)/10000;

            uint256 adjustedValue = dividend - (_minerFee + _poolFee);

            for(uint16 i; i < user.length; i++) {
                uint256 reward = (adjustedValue * userStake[user[i]])/totalStake;
                userStake[user[i]] += reward;
            }
            totalStake += dividend;

            userStake[miner] += _minerFee;
            userStake[owner()] += _poolFee;
        }
    }

    function updateSnapshot() internal {
        address contractAddress = address(this);
        snapshotBalance = contractAddress.balance;
        snapshotTimestamp = block.timestamp;
    }
    
    function getROI() internal view returns(uint256){
        address contractAddress = address(this);
        uint256 currentBalance = contractAddress.balance;

        return ((currentBalance - snapshotBalance)*1e18/currentBalance)/((block.timestamp - snapshotTimestamp) * 30 days);
    }
}