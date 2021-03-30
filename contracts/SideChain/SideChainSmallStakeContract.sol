pragma solidity ^0.7.4;

import '../libraries/SafeMath.sol';

contract SideChainSmallStakeContract {

    using SafeMath for uint256;

    address payable public miner = 0xe94E8362A0A033C04860024afeb384Dd395F5a4f;
    address payable public owner;

    uint16 public minerFee;

    uint16 public poolFee;

    bool public isClosed;

    address payable[] private user;
    mapping(address => uint256) private userArrPos;

    uint256 public minStake;
    uint256 public totalStakes;
    mapping(address => uint256) private userStakeWithRewards;

    constructor() {
        owner = msg.sender;
        user.push(msg.sender);
        user.push(miner);
        userArrPos[miner] = 1;
    }

    function getStakesWithRewards(address staker) public view returns (uint256) {
        address contractAddress = address(this);

        if(totalStakes == 0) {
            return 0;
        }

        uint256 dividend = contractAddress.balance.sub(totalStakes);
        uint256 adjustedValue = dividend.sub(dividend.mul(minerFee + poolFee).div(10000));
        uint256 reward = userStakeWithRewards[staker].mul(adjustedValue).div(totalStakes);

        if(staker == owner) {
            reward += dividend.mul(poolFee).div(10000);
        }
        if(staker == miner) {
            reward += dividend.mul(minerFee).div(10000);
        }
        return userStakeWithRewards[staker].add(reward);
    }

    receive() external payable {
        require(isClosed == false, 'Pool is closed');

        calculateRewards();

        if(msg.sender != user[0]) {
            if(msg.sender != user[1]) {
                if(userStakeWithRewards[msg.sender] == 0) {
                    require(msg.value >= minStake);
                    user.push(msg.sender);
                    userArrPos[msg.sender] = user.length.sub(1);
                }
            }
        }
        userStakeWithRewards[msg.sender] += msg.value;
        totalStakes += msg.value;
    }

    function withdrawStakes(uint256 amount) public {
        require(getStakesWithRewards(msg.sender) >= amount);
        calculateRewards();
        require(userStakeWithRewards[msg.sender] >= amount);
        msg.sender.transfer(amount);
        userStakeWithRewards[msg.sender] -= amount;
        totalStakes -= amount;

        if(msg.sender != user[0]) {
            if(msg.sender != user[1]) {
                if(userStakeWithRewards[msg.sender] == 0) {
                    delete user[userArrPos[msg.sender]];
                }
            }
        }
    }

    //Miner functions
    function adjustMinerFee(uint16 amount) public {
        require(msg.sender == owner || msg.sender == miner);
        require(amount <= 9000);
        calculateRewards();
        minerFee = amount;
    }

    function changeMiner(address payable _miner) public {
        require(msg.sender == miner);
        miner = _miner;
    }

    //Owner functions
    function changePoolStatus(bool status) public {
        require(msg.sender == owner);
        isClosed = status;
    }

    function adjustMinStake(uint256 _minStake) public {
        require(msg.sender == owner);
        minStake = _minStake;
    }

    function adjustPoolFee(uint16 amount) public {
        require(msg.sender == owner);
        require(amount <= 500);
        calculateRewards();
        poolFee = amount;
    }

    function flushContract() public {
        require(msg.sender == owner);
        calculateRewards();
        for(uint16 i; i < user.length; i++) {
            user[i].transfer(userStakeWithRewards[user[i]]);
            userStakeWithRewards[user[i]] = 0;
            delete user[i];
        }
        totalStakes = 0;
        isClosed = true;
    }

    //Internal functions
    function calculateRewards() internal {

        address contractAddress = address(this);
        
        if(contractAddress.balance.sub(msg.value).sub(totalStakes) > 0){

            uint256 dividend = contractAddress.balance.sub(msg.value).sub(totalStakes);
            uint256 _minerFee = dividend.mul(minerFee).div(10000);
            uint256 _poolFee = dividend.mul(poolFee).div(10000);

            uint256 adjustedValue = dividend.sub(_minerFee).sub(_poolFee);

            for(uint16 i; i < user.length; i++) {
                uint256 reward = adjustedValue.mul(userStakeWithRewards[user[i]]).div(totalStakes);
                userStakeWithRewards[user[i]] += reward;
            }
            totalStakes += dividend;

            userStakeWithRewards[miner] += _minerFee;
            userStakeWithRewards[owner] += _poolFee;
        }
    }
}