pragma solidity >0.4.99 <0.6.0;

import '../interfaces/SafeMath.sol';

contract SideChainSmallStakeContract {

    using SafeMath for uint256;

    address payable public miner = 0xdfe9A918B553D5BFa4Aa6A1DBa16d5286Bf00fa1;
    address payable public owner;

    uint16 public minerFee;

    uint16 public poolFee;

    bool isClosed;

    address payable[] public user;

    uint256 public totalStakes;
    mapping(address => uint256) public userStakeWithRewards;

    constructor() public {
        owner = msg.sender;
        user.push(msg.sender);
        user.push(miner);
    }

    function getStakesWithRewards(address staker) public view returns (uint256) {
        if (totalStakes == 0) {
            return 0;
        }
        uint256 dividend = address(this).balance.sub(totalStakes);
        uint256 adjustedValue = dividend.sub(dividend.mul(minerFee + poolFee).div(10000));
        uint256 reward = userStakeWithRewards[staker].mul(adjustedValue).div(totalStakes);
        return userStakeWithRewards[staker].add(reward);
    }

    function () external payable {
        updateRewards();
        require(isClosed == false, 'Pool is closed');

        if(userStakeWithRewards[msg.sender] == 0) {
            require(msg.value >= 10 ether);
            user.push(msg.sender);
        }

        userStakeWithRewards[msg.sender] += msg.value;
        totalStakes += msg.value;
    }

    function withdrawStakes(uint256 amount) public {
        require(getStakesWithRewards(msg.sender) >= amount);
        updateRewards();
        msg.sender.transfer(amount);
        totalStakes -= amount;
    }

    //Miner functions
    function adjustMinerFee(uint16 amount) public {
        require(msg.sender == owner || msg.sender == miner);
        require(minerFee <= 4000);
        updateRewards();
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

    function adjustPoolFee(uint16 amount) public {
        require(msg.sender == owner);
        require(amount <= 500);
        updateRewards();
        poolFee = amount;
    }

    function flushContract() public {
        require(msg.sender == owner);
        updateRewards();
        for(uint16 i; i < user.length; i++) {
            user[i].transfer(userStakeWithRewards[user[i]]);
            userStakeWithRewards[user[i]] = 0;
        }
        isClosed = true;
    }

    //Private functions
    function updateRewards() private {
        require(totalStakes <= address(this).balance);

        uint256 dividend = address(this).balance.sub(msg.value).sub(totalStakes);

        if(dividend == 0){
            return;
        } else {
            uint256 _minerFee = dividend.mul(minerFee).div(10000);
            uint256 _poolFee = dividend.mul(poolFee).div(10000);

            uint256 adjustedValue = dividend.sub(_minerFee).sub(_poolFee);

            for(uint16 i; i < user.length; i++) {
                uint256 reward = adjustedValue.mul(userStakeWithRewards[user[i]]).div(totalStakes);
                userStakeWithRewards[user[i]] += reward;
            }

            userStakeWithRewards[miner] += _minerFee;
            userStakeWithRewards[owner] += _poolFee;
        }
    }
}