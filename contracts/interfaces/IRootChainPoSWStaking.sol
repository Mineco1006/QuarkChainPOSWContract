pragma solidity =0.5.16;

interface IRootChainPoSWStaking {
    function setSigner(address signer) external payable;
    function lock() external payable;
    function unlock() external;
    function () external payable;
    function withdraw(uint256 amount) external;
    function withdrawAll() external;
    function getLockedStakes(address staker) external view returns (uint256, address);
}