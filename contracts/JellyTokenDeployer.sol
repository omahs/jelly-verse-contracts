// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./vendor/openzeppelin/v4.9.0/utils/Create2.sol";
import "./JellyToken.sol";

/**
 * @title The JellyTokenDeployer smart contract
 * @notice A contract for deploying JellyToken smart contract using CREATE2 opcode
 */
contract JellyTokenDeployer {
    event Deployed(address contractAddress, bytes32 salt);

    /**
     * @notice Returns the bytecode for deploying JellyToken smart contract
     *
     * @param _defaultAdminRole - The address of the Jelly Governance (Timelock) smart contract
     *
     * @return bytes - The bytecode for deploying JellyToken smart contract
     */
    function getBytecode(address _defaultAdminRole) public pure returns (bytes memory) {
        return
            abi.encodePacked(
                type(JellyToken).creationCode,
                abi.encode(_defaultAdminRole)
            );
    }

    /**
     * @notice Computes the address of the JellyToken smart contract
     *
     * @param _defaultAdminRole - The address of the Jelly Governance (Timelock) smart contract
     *
     * @return address - The address of the JellyToken smart contract
     */
    function computeAddress(
        bytes32 _salt,
        address _defaultAdminRole
    ) public view returns (address) {
        bytes memory _bytecode = getBytecode(_defaultAdminRole);

        return Create2.computeAddress(_salt, keccak256(_bytecode));
    }

    function deployJellyToken(
        bytes32 _salt,
        address _defaultAdminRole
    ) public payable returns (address JellyTokenAddress) {
        bytes memory _bytecode = getBytecode(_defaultAdminRole);

        JellyTokenAddress = Create2.deploy(0, _salt, _bytecode);

        emit Deployed(JellyTokenAddress, _salt);
    }
}
