pragma solidity >0.4.99 <0.6.0;

interface IRootChainPoSWStaking {
    function setSigner(address signer) external payable;
    function lock() external payable;
    function unlock() external;
    function withdraw(uint256 amount) external;
    function withdrawAll() external;
    function getLockedStakes() external view returns(uint256, address);
}