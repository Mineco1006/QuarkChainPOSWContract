pragma solidity >0.4.99 <0.6.0;

import '../interfaces/SafeMath.sol';

contract SmallStakeContract {

    using SafeMath for uint256;

    address payable public miner = 0xdfe9A918B553D5BFa4Aa6A1DBa16d5286Bf00fa1;
    address payable public owner;

    uint16 public minerFee;

    uint16 public poolFee;

    bool isClosed;

    address payable[] public user;

    uint256 public poolStakes;
    mapping(address => uint256) public userStakes;
    mapping(address => uint256) public userRewards;

    uint256 public withdrawableTimeStamp;

    constructor() public {
        owner = msg.sender;
    }

    function calculateRewards() internal {
        uint256 _minerFee = msg.value.mul(minerFee).div(10000);
        uint256 _poolFee = msg.value.mul(poolFee).div(10000);
            miner.transfer(_minerFee);
            owner.transfer(_poolFee);

            uint256 adjustedValue = msg.value.sub(_minerFee.add(_poolFee));

            for(uint16 i; i < user.length; i++) {
                userRewards[user[i]] += userStakes[msg.sender].mul(10**18).div(poolStakes).mul(adjustedValue).div(10**18);
            }
    }

    function () external payable {
        if(msg.sender == address(this)){
            calculateRewards();
        } else {
            require(isClosed == false, 'Pool is closed');

            if(userStakes[msg.sender] == 0) {
                require(msg.value >= 20000 ether);
                user.push(msg.sender);
            }

            userStakes[msg.sender] += msg.value;
            poolStakes += msg.value;
        }
    }

    function withdrawStakes(uint256 amount) public {
        require(userStakes[msg.sender].add(userRewards[msg.sender]) >= amount);
        msg.sender.transfer(amount);
    }

    function distributeAllRewardsToStakers() public {
        require(msg.sender == owner);
        for(uint16 i; i <= user.length; i++) {
            user[i].transfer(userStakes[user[i]].add(userRewards[user[i]]));
            userStakes[user[i]] = 0;
            userRewards[user[i]] = 0;
        }
        isClosed = true;
    }

    function adjustMinerFee(uint16 amount) public {
        require(msg.sender == owner || msg.sender == miner);
        require(minerFee <= 4000);
        minerFee = amount;
    }

    function changePoolStatus(bool status) public {
        require(msg.sender == owner);
        isClosed = status;
    }

    function adjustPoolFee(uint16 amount) public {
        require(msg.sender == owner);
        require(amount <= 500);
        poolFee = amount;
    }

    function changeMiner(address payable _miner) public {
        require(msg.sender == miner);
        miner = _miner;
    }
}