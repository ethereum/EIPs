pragma solidity ^0.8.1;

/// @title ERC-4824 Common Interfaces for DAOs
/// @dev See <https://eips.ethereum.org/EIPS/eip-4824>

contract CloneFactory {
    // implementation of eip-1167 - see https://eips.ethereum.org/EIPS/eip-1167
    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
    }
}

contract ERC-4824RegistrationSummoner {
    event NewRegistration(
        address indexed daoAddress,
        string daoURI,
        address registration
    );

    address public ERC-4824Index;
    address public template; /*Template contract to clone*/

    constructor(address _template, address _ERC-4824Index) {
        template = _template;
        ERC-4824Index = _ERC-4824Index;
    }

    function registrationAddress(
        address by,
        bytes32 salt
    ) external view returns (address addr, bool exists) {
        addr = Clones.predictDeterministicAddress(
            template,
            _saltedSalt(by, salt),
            address(this)
        );
        exists = addr.code.length > 0;
    }

    function summonRegistration(
        bytes32 salt,
        string calldata daoURI_,
        address manager,
        address[] calldata contracts,
        bytes[] calldata data
    ) external returns (address registration, bytes[] memory results) {
        registration = Clones.cloneDeterministic(
            template,
            _saltedSalt(msg.sender, salt)
        );

        if (manager == address(0)) {
            ERC-4824Registration(registration).initialize(
                msg.sender,
                daoURI_,
                ERC-4824Index
            );
        } else {
            ERC-4824Registration(registration).initialize(
                msg.sender,
                manager,
                daoURI_,
                ERC-4824Index
            );
        }

        results = _callContracts(contracts, data);

        emit NewRegistration(msg.sender, daoURI_, registration);
    }
}
