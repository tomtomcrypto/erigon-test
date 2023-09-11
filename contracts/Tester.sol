// contracts/Tester.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Reverter.sol";

contract Tester {
    struct Recipient {
        address recipient;
        uint256 balance;
    }
    Reverter public reverter;
    uint256 public storeMe;

    function setReverter(Reverter _reverter) external {
        reverter = _reverter;
    }

    receive() external payable {}

    function testGasLeftProxy() public returns (uint gasLeft)  {
        (bool success, bytes memory returndata) = address(reverter).call(abi.encodeWithSignature('testGasLeft()'));
    }

    function validateEther(Recipient[] calldata _recipients) external payable returns (uint gasLeft, Recipient[] memory badAddresses)  {
        badAddresses = new Recipient[](_recipients.length);

        uint256 contractBalanceBefore = address(this).balance - msg.value;
        uint256 total = msg.value;
        uint256 contractFee = 10000;
        total = total - contractFee;
        for(uint256 i = 0; i < _recipients.length; i++){
            bool success = payable(_recipients[i].recipient).send(_recipients[i].balance);
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

    function testGasLeft() public returns (uint gasLeft)  {
        gasLeft = gasleft();
    }

    function testCallNonRevert() public {
        (bool success, bytes memory returndata) = address(reverter).call(abi.encodeWithSignature('revertWithMessage()'));
    }

    function testCallRevert() public {
        reverter.revertWithMessage();
    }

    function testProxiedValueTransfer() public payable {
        reverter.testValueTransfer{value: msg.value}(msg.sender);
    }

    function testValueTransfer() public payable {
        // First send the TLOS back to sender to test internal value transactions
        payable(msg.sender).transfer(msg.value);
    }

    function create(uint rand, uint gasLimit) public returns (address newReverter) {
        bytes memory bytecode = type(Reverter).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(rand));
        require(gasleft() >= gasLimit, "Insufficient gas for transaction");
        assembly {
            newReverter := create2(gasLimit, add(bytecode, 32), mload(bytecode), salt)
        }
        reverter = Reverter(newReverter);
    }
}