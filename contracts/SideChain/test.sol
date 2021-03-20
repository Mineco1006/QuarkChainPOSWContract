pragma solidity ^0.7.4;

contract test {

    constructor() {
    }

    receive() external payable {

    }
    function getAddress() public view returns(address) {
        return address(this);
    }
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function getBalance1() public view returns(uint256) {
        address contractAddress = address(this);
        return contractAddress.balance;
    }

    function withdraw() public {
        msg.sender.transfer(address(this).balance);
    }
}