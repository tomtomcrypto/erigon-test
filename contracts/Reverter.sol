// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Reverter {

    function revertWithMessage() public {
        require(false, "This is a very big problem!");
    }

    function testMultisender(address[] calldata _recipients) external payable returns (uint gasLeft, address[] memory badAddresses)  {
        badAddresses = new address[](_recipients.length);

        uint256 contractBalanceBefore = address(this).balance - msg.value;
        uint256 total = msg.value;
        uint256 contractFee = 0;
        total = total - contractFee;
        for(uint256 i = 0; i < _recipients.length; i++){
            bool success = payable(_recipients[i]).send(_recipients[i].balance);
            if(!success){
                badAddresses[i] = _recipients[i];
            } else {
                total = total - _recipients[i].balance;
            }
        }

        uint256 contractBalanceAfter = address(this).balance;
        require(
            contractBalanceAfter >= contractBalanceBefore + contractFee,
            "don't try to take the contract money"
        );
        gasLeft = gasleft();
    }

    function testValueTransfer(address sender) public payable {
        payable(sender).transfer(msg.value);
    }

    function testGasLeft() public returns (uint gasLeft)  {
        uint gasLeft = gasleft();
        return gasLeft;
    }
}