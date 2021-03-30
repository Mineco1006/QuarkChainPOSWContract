pragma solidity ^0.7.4;

import '../interfaces/IRootChainPoSWStaking.sol';
import '../libraries/SafeMath.sol';

contract RootChainSmallStakeContract {

    using SafeMath for uint256;

    address private signer;
    address payable private stakingContract;
    address payable public miner;
    address payable public owner;

    uint16 public minerFee;
    uint16 public poolFee;

    bool public isClosed;

    address payable[] private user;
    mapping(address => uint256) private userArrPos;

    uint256 public minStake;
    uint256 public totalStakes;
    mapping(address => uint256) private userStakeWithRewards;

    uint256 public withdrawableTimeStamp;
    

    IRootChainPoSWStaking StakingContract;

    constructor() {
        owner = msg.sender;
        stakingContract = 0x514b430000000000000000000000000000000001;
        StakingContract = IRootChainPoSWStaking(stakingContract);
        miner = 0xdfe9A918B553D5BFa4Aa6A1DBa16d5286Bf00fa1;
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
        if(msg.sender == signer){
            calculateRewards();
        } else {
            require(isClosed == false, 'Pool is closed');

            if(userStakes[msg.sender] == 0) {
                require(msg.value >= 300000 ether);
                user.push(msg.sender);
            }

            userStakes[msg.sender] += msg.value;
            poolStakes += msg.value;

            if(address(this).balance >= 1000000 ether){
                transferStakesToContractInternal(address(this).balance.div(1000000 ether).mul(1000000 ether));
            }
        }
    }

    function unlock() public {
        require(msg.sender == owner || msg.sender == miner);
        StakingContract.unlock();
        withdrawableTimeStamp = block.timestamp.add(3 days);
    }
    
    function lock() public {
        StakingContract.lock();
    }

    function transferStakesToContract(uint256 amount) public {
        require(msg.sender == owner || msg.sender == miner);
        require(poolStakes > 1000000 ether);
        stakingContract.call.value(amount)("");
    }

    function transferStakesToContractInternal(uint256 amount) internal {
        require(poolStakes > 1000000 ether);
        stakingContract.call.value(amount)("");
    }


    function withdrawStakesFromRootContract(uint256 memory amount) public payable {
        require(userStakes[msg.sender].add(userRewards[msg.sender]) >= amount);
        StakingContract.withdraw(amount);
        //stakingContract.call(abi.encodeWithSignature("withdraw(uint256)", amount));
    }

    function withdrawStakes(uint256 amount) public {
        require(userStakes[msg.sender].add(userRewards[msg.sender]) >= amount);
        msg.sender.transfer(amount);
    }

    function withdrawAllStakesFromRootContract() public payable {
        require(msg.sender == owner);
        StakingContract.withdrawAll();
        //stakingContract.call(abi.encodeWithSignature("withdrawAll()"));
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