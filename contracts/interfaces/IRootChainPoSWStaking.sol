pragma solidity ^0.7.4;

interface IRootChainPoSWStaking {
    function setSigner(address signer) external payable;
    function lock() external payable;
    function unlock() external;
    receive() external payable;
    function withdraw(uint256 amount) external;
    function withdrawAll() external;
}