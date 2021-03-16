pragma solidity >0.4.99 <0.6.0;

import './interfaces/RootChainPoSWStaking.sol'

contract SmallStakeContract {
    address private signer;
    address private constant stakingContract = 0x514b430000000000000000000000000000000001;
    address public constant miner = ;
    address public constant owner = ;

    address[] user;

    uint14 public minerFee;
    uint256 public minerRewards;

    bool isClosed;

    uint256 public poolStakes;
    mapping(address => uint12) private userWeight;
    mapping(address => uint256) public userStakes;
    mapping(address => uint256) public userRewards;
    

    RootChainPoSWStaking StakingContract = RootChainPoSWStaking(stakingContract);

    constructor() {
        signer = address(this);
        StakingContract.setSigner(signer);
    }

    receive() external payable {
        if(msg.sender == signer){
            uint256 adjustedValue = msg.value - (msg.value*minerFee/10000)
            for(uint16 i, i < user.length, i++) {
                userRewards[user[i]] += (userWeight[user[i]]*adjustedValue)/10**18
            }
        } else {
            require(isClosed = false, 'Pool is already closed')
            require(poolStakes + msg.value <= 1000100*10**18, 'Pool stakes too high')

            userStakes[msg.sender] += msg.value;
            poolStakes += msg.value;

            if(poolStakes >= 1000000*10**18) {
                for(uint16 i, i <= user.lenght, i++) {
                    userWeight[user[i]] = userStakes[user[i]]*10**18/poolStakes;
                }
                isClosed = true;
            }
        }
    }

    function unlock() public {
        StakingContract.unlock();
    }
    
    function lock() public {
        StakingContract.lock();
    }

    function pushStakesToContract(uint256 amount) public {
        require(poolStakes > 1000000*10**18);
        stakingContract.transfer(amount);
    }

    function getWithdrawableTime() public view returns(uint256) {
        return StakingContract.Stake.withdrawableTimestamp;
    }

    function withdrawStakesFromStakingContract(uint256 amount) public {
        require(userStakes[msg.sender] >= amount);
        StakingContract.withdraw(amount);
    }

    function withdrawAllStakesFromStakingContract() public {
        require(msg.sender == owner)
        StakingContract.withdrawAll;
    }

    function adjustMinerFee(uint14 amount) {
        require(msg.sender == owner || msg.sender == miner)
        minerFee = amount;
    }

    function openPool() public {
        require(msg.sender == owner);
        isClosed = false;
    }
}