// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.16;

import {IDelegationRegistry} from "./IDelegationRegistry.sol";
import {EnumerableSet} from "openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {ERC165} from "openzeppelin-contracts/contracts/utils/introspection/ERC165.sol";

/**
 * @title DelegationRegistry
 * @custom:version 0.2
 * @notice An immutable registry contract to be deployed as a standalone primitive.
 * New project launches can read previous cold wallet -> hot wallet delegations
 * from here and integrate those permissions into their flow.
 * @custom:coauthor foobar (0xfoobar)
 * @custom:coauthor wwchung (manifoldxyz)
 * @custom:coauthor purplehat (artblocks)
 * @custom:coauthor ryley-o (artblocks)
 * @custom:coauthor andy8052 (tessera)
 * @custom:coauthor punk6529 (open metaverse)
 * @custom:coauthor loopify (loopiverse)
 * @custom:coauthor emiliano (nftrentals)
 * @custom:coauthor arran (proof)
 * @custom:coauthor james (collabland)
 * @custom:coauthor john (gnosis safe)
 * @custom:coauthor 0xrusowsky
 */
contract DelegationRegistry is IDelegationRegistry, ERC165 {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @notice The global mapping and single source of truth for delegations
    /// @dev vault -> vaultVersion -> delegationHash
    mapping(address => mapping(uint256 => EnumerableSet.Bytes32Set)) internal delegations;

    /// @notice A mapping of wallets to versions (for cheap revocation)
    mapping(address => uint256) internal vaultVersion;

    /// @notice A mapping of wallets to delegates to versions (for cheap revocation)
    mapping(address => mapping(address => uint256)) internal delegateVersion;

    /// @notice A secondary mapping to return onchain enumerability of delegations that a given address can perform
    /// @dev delegate -> delegationHashes
    mapping(address => EnumerableSet.Bytes32Set) internal delegationHashes;

    /// @notice A secondary mapping used to return delegation information about a delegation
    /// @dev delegationHash -> DelegateInfo
    mapping(bytes32 => IDelegationRegistry.DelegationInfo) internal delegationInfo;

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC165) returns (bool) {
        return interfaceId == type(IDelegationRegistry).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * -----------  WRITE -----------
     */

    /**
     * @inheritdoc IDelegationRegistry
     */
    function delegateForAll(address delegate, bool value) external override {
        bytes32 delegationHash = _computeAllDelegationHash(msg.sender, delegate);
        _setDelegationValues(
            delegate, delegationHash, value, IDelegationRegistry.DelegationType.ALL, msg.sender, address(0), 0
        );
        emit IDelegationRegistry.DelegateForAll(msg.sender, delegate, value);
    }

    /**
     * @inheritdoc IDelegationRegistry
     */
    function delegateForContract(address delegate, address contract_, bool value) external override {
        bytes32 delegationHash = _computeContractDelegationHash(msg.sender, delegate, contract_);
        _setDelegationValues(
            delegate, delegationHash, value, IDelegationRegistry.DelegationType.CONTRACT, msg.sender, contract_, 0
        );
        emit IDelegationRegistry.DelegateForContract(msg.sender, delegate, contract_, value);
    }

    /**
     * @inheritdoc IDelegationRegistry
     */
    function delegateForToken(address delegate, address contract_, uint256 tokenId, bool value) external override {
        bytes32 delegationHash = _computeTokenDelegationHash(msg.sender, delegate, contract_, tokenId);
        _setDelegationValues(
            delegate, delegationHash, value, IDelegationRegistry.DelegationType.TOKEN, msg.sender, contract_, tokenId
        );
        emit IDelegationRegistry.DelegateForToken(msg.sender, delegate, contract_, tokenId, value);
    }

    /**
     * @dev Helper function to set all delegation values and enumeration sets
     */
    function _setDelegationValues(
        address delegate,
        bytes32 delegateHash,
        bool value,
        IDelegationRegistry.DelegationType type_,
        address vault,
        address contract_,
        uint256 tokenId
    )
        internal
    {
        if (value) {
            delegations[vault][vaultVersion[vault]].add(delegateHash);
            delegationHashes[delegate].add(delegateHash);
            delegationInfo[delegateHash] =
                DelegationInfo({vault: vault, delegate: delegate, type_: type_, contract_: contract_, tokenId: tokenId});
        } else {
            delegations[vault][vaultVersion[vault]].remove(delegateHash);
            delegationHashes[delegate].remove(delegateHash);
            delete delegationInfo[delegateHash];
        }
    }

    /**
     * @dev Helper function to compute delegation hash for wallet delegation
     */
    function _computeAllDelegationHash(address vault, address delegate) internal view returns (bytes32) {
        uint256 vaultVersion_ = vaultVersion[vault];
        uint256 delegateVersion_ = delegateVersion[vault][delegate];
        return keccak256(abi.encode(delegate, vault, vaultVersion_, delegateVersion_));
    }

    /**
     * @dev Helper function to compute delegation hash for contract delegation
     */
    function _computeContractDelegationHash(address vault, address delegate, address contract_)
        internal
        view
        returns (bytes32)
    {
        uint256 vaultVersion_ = vaultVersion[vault];
        uint256 delegateVersion_ = delegateVersion[vault][delegate];
        return keccak256(abi.encode(delegate, vault, contract_, vaultVersion_, delegateVersion_));
    }

    /**
     * @dev Helper function to compute delegation hash for token delegation
     */
    function _computeTokenDelegationHash(address vault, address delegate, address contract_, uint256 tokenId)
        internal
        view
        returns (bytes32)
    {
        uint256 vaultVersion_ = vaultVersion[vault];
        uint256 delegateVersion_ = delegateVersion[vault][delegate];
        return keccak256(abi.encode(delegate, vault, contract_, tokenId, vaultVersion_, delegateVersion_));
    }

    /**
     * @inheritdoc IDelegationRegistry
     */
    function revokeAllDelegates() external override {
        ++vaultVersion[msg.sender];
        emit IDelegationRegistry.RevokeAllDelegates(msg.sender);
    }

    /**
     * @inheritdoc IDelegationRegistry
     */
    function revokeDelegate(address delegate) external override {
        _revokeDelegate(delegate, msg.sender);
    }

    /**
     * @inheritdoc IDelegationRegistry
     */
    function revokeSelf(address vault) external override {
        _revokeDelegate(msg.sender, vault);
    }

    /**
     * @dev Revoke the `delegate` hotwallet from the `vault` coldwallet.
     */
    function _revokeDelegate(address delegate, address vault) internal {
        ++delegateVersion[vault][delegate];
        // For enumerations, filter in the view functions
        emit IDelegationRegistry.RevokeDelegate(vault, msg.sender);
    }

    /**
     * -----------  READ -----------
     */

    /**
     * @inheritdoc IDelegationRegistry
     */
    function getDelegationsByDelegate(address delegate)
        external
        view
        returns (IDelegationRegistry.DelegationInfo[] memory info)
    {
        EnumerableSet.Bytes32Set storage potentialDelegationHashes = delegationHashes[delegate];
        uint256 potentialDelegationHashesLength = potentialDelegationHashes.length();
        uint256 delegationCount = 0;
        info = new IDelegationRegistry.DelegationInfo[](potentialDelegationHashesLength);
        for (uint256 i = 0; i < potentialDelegationHashesLength;) {
            bytes32 delegateHash = potentialDelegationHashes.at(i);
            IDelegationRegistry.DelegationInfo memory delegationInfo_ = delegationInfo[delegateHash];
            address vault = delegationInfo_.vault;
            IDelegationRegistry.DelegationType type_ = delegationInfo_.type_;
            bool valid = false;
            if (type_ == IDelegationRegistry.DelegationType.ALL) {
                if (delegateHash == _computeAllDelegationHash(vault, delegate)) {
                    valid = true;
                }
            } else if (type_ == IDelegationRegistry.DelegationType.CONTRACT) {
                if (delegateHash == _computeContractDelegationHash(vault, delegate, delegationInfo_.contract_)) {
                    valid = true;
                }
            } else if (type_ == IDelegationRegistry.DelegationType.TOKEN) {
                if (
                    delegateHash
                        == _computeTokenDelegationHash(vault, delegate, delegationInfo_.contract_, delegationInfo_.tokenId)
                ) {
                    valid = true;
                }
            }
            if (valid) {
                info[delegationCount++] = delegationInfo_;
            }
            unchecked {
                ++i;
            }
        }
        if (potentialDelegationHashesLength > delegationCount) {
            assembly {
                let decrease := sub(potentialDelegationHashesLength, delegationCount)
                mstore(info, sub(mload(info), decrease))
            }
        }
    }

    /**
     * @inheritdoc IDelegationRegistry
     */
    function getDelegatesForAll(address vault) external view returns (address[] memory delegates) {
        return _getDelegatesForLevel(vault, IDelegationRegistry.DelegationType.ALL, address(0), 0);
    }

    /**
     * @inheritdoc IDelegationRegistry
     */
    function getDelegatesForContract(address vault, address contract_)
        external
        view
        override
        returns (address[] memory delegates)
    {
        return _getDelegatesForLevel(vault, IDelegationRegistry.DelegationType.CONTRACT, contract_, 0);
    }

    /**
     * @inheritdoc IDelegationRegistry
     */
    function getDelegatesForToken(address vault, address contract_, uint256 tokenId)
        external
        view
        override
        returns (address[] memory delegates)
    {
        return _getDelegatesForLevel(vault, IDelegationRegistry.DelegationType.TOKEN, contract_, tokenId);
    }

    function _getDelegatesForLevel(
        address vault,
        IDelegationRegistry.DelegationType delegationType,
        address contract_,
        uint256 tokenId
    )
        internal
        view
        returns (address[] memory delegates)
    {
        EnumerableSet.Bytes32Set storage delegationHashes_ = delegations[vault][vaultVersion[vault]];
        uint256 potentialDelegatesLength = delegationHashes_.length();
        uint256 delegatesCount = 0;
        delegates = new address[](potentialDelegatesLength);
        for (uint256 i = 0; i < potentialDelegatesLength;) {
            bytes32 delegationHash = delegationHashes_.at(i);
            DelegationInfo storage delegationInfo_ = delegationInfo[delegationHash];
            if (delegationInfo_.type_ == delegationType) {
                if (delegationType == IDelegationRegistry.DelegationType.ALL) {
                    // check delegate version by validating the hash
                    if (delegationHash == _computeAllDelegationHash(vault, delegationInfo_.delegate)) {
                        delegates[delegatesCount++] = delegationInfo_.delegate;
                    }
                } else if (delegationType == IDelegationRegistry.DelegationType.CONTRACT) {
                    if (delegationInfo_.contract_ == contract_) {
                        // check delegate version by validating the hash
                        if (
                            delegationHash == _computeContractDelegationHash(vault, delegationInfo_.delegate, contract_)
                        ) {
                            delegates[delegatesCount++] = delegationInfo_.delegate;
                        }
                    }
                } else if (delegationType == IDelegationRegistry.DelegationType.TOKEN) {
                    if (delegationInfo_.contract_ == contract_ && delegationInfo_.tokenId == tokenId) {
                        // check delegate version by validating the hash
                        if (
                            delegationHash
                                == _computeTokenDelegationHash(vault, delegationInfo_.delegate, contract_, tokenId)
                        ) {
                            delegates[delegatesCount++] = delegationInfo_.delegate;
                        }
                    }
                }
            }
            unchecked {
                ++i;
            }
        }
        if (potentialDelegatesLength > delegatesCount) {
            assembly {
                let decrease := sub(potentialDelegatesLength, delegatesCount)
                mstore(delegates, sub(mload(delegates), decrease))
            }
        }
    }

    /**
     * @inheritdoc IDelegationRegistry
     */
    function getContractLevelDelegations(address vault)
        external
        view
        returns (IDelegationRegistry.ContractDelegation[] memory contractDelegations)
    {
        EnumerableSet.Bytes32Set storage delegationHashes_ = delegations[vault][vaultVersion[vault]];
        uint256 potentialLength = delegationHashes_.length();
        uint256 delegationCount = 0;
        contractDelegations = new IDelegationRegistry.ContractDelegation[](potentialLength);
        for (uint256 i = 0; i < potentialLength;) {
            bytes32 delegationHash = delegationHashes_.at(i);
            DelegationInfo storage delegationInfo_ = delegationInfo[delegationHash];
            if (delegationInfo_.type_ == IDelegationRegistry.DelegationType.CONTRACT) {
                // check delegate version by validating the hash
                if (
                    delegationHash
                        == _computeContractDelegationHash(vault, delegationInfo_.delegate, delegationInfo_.contract_)
                ) {
                    contractDelegations[delegationCount++] = IDelegationRegistry.ContractDelegation({
                        contract_: delegationInfo_.contract_,
                        delegate: delegationInfo_.delegate
                    });
                }
            }
            unchecked {
                ++i;
            }
        }
        if (potentialLength > delegationCount) {
            assembly {
                let decrease := sub(potentialLength, delegationCount)
                mstore(contractDelegations, sub(mload(contractDelegations), decrease))
            }
        }
    }

    /**
     * @inheritdoc IDelegationRegistry
     */
    function getTokenLevelDelegations(address vault)
        external
        view
        returns (IDelegationRegistry.TokenDelegation[] memory tokenDelegations)
    {
        EnumerableSet.Bytes32Set storage delegationHashes_ = delegations[vault][vaultVersion[vault]];
        uint256 potentialLength = delegationHashes_.length();
        uint256 delegationCount = 0;
        tokenDelegations = new IDelegationRegistry.TokenDelegation[](potentialLength);
        for (uint256 i = 0; i < potentialLength;) {
            bytes32 delegationHash = delegationHashes_.at(i);
            DelegationInfo storage delegationInfo_ = delegationInfo[delegationHash];
            if (delegationInfo_.type_ == IDelegationRegistry.DelegationType.TOKEN) {
                // check delegate version by validating the hash
                if (
                    delegationHash
                        == _computeTokenDelegationHash(
                            vault, delegationInfo_.delegate, delegationInfo_.contract_, delegationInfo_.tokenId
                        )
                ) {
                    tokenDelegations[delegationCount++] = IDelegationRegistry.TokenDelegation({
                        contract_: delegationInfo_.contract_,
                        tokenId: delegationInfo_.tokenId,
                        delegate: delegationInfo_.delegate
                    });
                }
            }
            unchecked {
                ++i;
            }
        }
        if (potentialLength > delegationCount) {
            assembly {
                let decrease := sub(potentialLength, delegationCount)
                mstore(tokenDelegations, sub(mload(tokenDelegations), decrease))
            }
        }
    }

    /**
     * @inheritdoc IDelegationRegistry
     */
    function checkDelegateForAll(address delegate, address vault) public view override returns (bool) {
        bytes32 delegateHash =
            keccak256(abi.encode(delegate, vault, vaultVersion[vault], delegateVersion[vault][delegate]));
        return delegations[vault][vaultVersion[vault]].contains(delegateHash);
    }

    /**
     * @inheritdoc IDelegationRegistry
     */
    function checkDelegateForContract(address delegate, address vault, address contract_)
        public
        view
        override
        returns (bool)
    {
        bytes32 delegateHash =
            keccak256(abi.encode(delegate, vault, contract_, vaultVersion[vault], delegateVersion[vault][delegate]));
        return
            delegations[vault][vaultVersion[vault]].contains(delegateHash)
            ? true
            : checkDelegateForAll(delegate, vault);
    }

    /**
     * @inheritdoc IDelegationRegistry
     */
    function checkDelegateForToken(address delegate, address vault, address contract_, uint256 tokenId)
        public
        view
        override
        returns (bool)
    {
        bytes32 delegateHash = keccak256(
            abi.encode(delegate, vault, contract_, tokenId, vaultVersion[vault], delegateVersion[vault][delegate])
        );
        return
            delegations[vault][vaultVersion[vault]].contains(delegateHash)
            ? true
            : checkDelegateForContract(delegate, vault, contract_);
    }
}
