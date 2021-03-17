pragma solidity >0.4.99 <0.6.0;

import './RootChainPoSWStaking.sol';
import './interfaces/SafeMath.sol';

contract SmallStakeContract {

    using SafeMath for uint256;


    address private signer;
    address payable private constant stakingContract = 0x514b430000000000000000000000000000000001;
    address payable public constant miner = 0xdfe9A918B553D5BFa4Aa6A1DBa16d5286Bf00fa1;
    address payable public owner;

    address[] user;

    uint16 public minerFee;
    uint256 public minerRewards;

    uint16 public ownerFee;

    bool isClosed;

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
        uint256 _minerFee = msg.value*minerFee/10000;
        uint256 _ownerFee = msg.value.mul(ownerFee).div(10000);
            miner.transfer(_minerFee);
            owner.transfer(_ownerFee);

            uint256 adjustedValue = msg.value - _minerFee;

            for(uint16 i; i < user.length; i++) {
                userRewards[user[i]] += ((userRewards[msg.sender]/poolStakes)*adjustedValue)/10**18;
            }
    }

    function () external payable {
        if(msg.sender == signer){
            calculateRewards();
        } else {
            require(isClosed = true, 'Pool is closed');

            if(userStakes[msg.sender] == 0) {
                user.push(msg.sender);
            }

            userStakes[msg.sender] += msg.value;
            poolStakes += msg.value;
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

    function pushStakesToContract(uint256 amount) public payable {
        require(poolStakes > 1000000*10**18);
        stakingContract.transfer(amount);
    }

    function withdrawStakesFromStakingContract(uint256 amount) public {
        require(userStakes[msg.sender] >= amount);
        StakingContract.withdraw(amount);
    }

    function withdrawAllStakesFromStakingContract() public view {
        require(msg.sender == owner);
        StakingContract.withdrawAll;
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

    function adjustOwnerFee(uint16 amount) public {
        require(msg.sender == owner);
        require(amount <= 500);
        ownerFee = amount;
    }
}