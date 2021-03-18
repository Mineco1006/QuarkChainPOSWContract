pragma solidity >0.4.99 <0.6.0;

import './RootChainPoSWStaking.sol';
import '../interfaces/SafeMath.sol';

contract SmallStakeContract {

    using SafeMath for uint256;


    address private signer;
    address payable private constant stakingContract = 0x514b430000000000000000000000000000000001;
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
    

    RootChainPoSWStaking StakingContract = RootChainPoSWStaking(stakingContract);

    constructor() public {
        signer = address(this);
        StakingContract.setSigner(signer);
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


    function withdrawStakesFromRootContract(uint256 amount) public payable {
        require(userStakes[msg.sender].add(userRewards[msg.sender]) >= amount);
        StakingContract.withdraw(amount);
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