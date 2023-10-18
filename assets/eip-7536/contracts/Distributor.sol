// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';

import './interfaces/IEIP7536Distributor.sol';
import './interfaces/IEIP7536Validator.sol';

import 'hardhat/console.sol';

/**
 * @notice This is an implementation of the IDistributor interface.
 */
contract Distributor is ERC721Enumerable, IDistributor {
    using Strings for uint256;

    struct Edition {
        address tokenContract;
        uint256 tokenId;
        address validator;
        uint96  actions;
    }

    uint96 private constant _TRANSFER = 1<<0;  // child action
    uint96 private constant _UPDATE = 1<<1;    // child action
    uint96 private constant _REVOKE = 1<<2;    // parent action
    
    uint256 private _tokenCounter;

    // tokenId => editionHash
    mapping(uint256 => bytes32) private _editionHash;
    mapping(uint256 => string) private _tokenURI;

    // nft descriptor => edition (For Record Keeping, editions cannot be deleted once set)
    mapping(address=>mapping(uint256 => bytes32[])) _editionHashes;

    // edition fields
    mapping(bytes32 => Edition) private _edition;
    // mapping(bytes32 => address) private _validator;
    // mapping(bytes32 => uint96) private _actions;
    
    // editions state
    mapping(bytes32 => bool) private _states;

    constructor (
        string memory name_, 
        string memory symbol_
    ) ERC721(name_, symbol_) {}
    
    modifier onlyCreator(address tokenContract, uint256 tokenId) {
        require(
            _isApprovedOrCreator(_msgSender(), tokenContract, tokenId),
            'Distributor: caller is not creator nor approved'
        );
        _;
    }

    /// @inheritdoc IDistributor
    function setEdition(
        address tokenContract,
        uint256 tokenId,
        address validator,
        uint96  actions,
        bytes calldata initData
    ) external override onlyCreator(tokenContract, tokenId) returns (bytes32) {

        Edition memory edition = Edition(tokenContract, tokenId, validator, actions);

        bytes32 editionHash = _getEditionHash(tokenContract, tokenId);
        
        _storeEdition(edition, editionHash);
        _states[editionHash] = true; // enable minting

        IValidator(edition.validator).setRules(editionHash, initData);
        
        emit SetEdition(editionHash, tokenContract, tokenId, validator, actions);
        return editionHash;
    }
    
    function _storeEdition(
        Edition memory edition,
        bytes32 editionHash
    ) internal {
        _editionHashes[edition.tokenContract][edition.tokenId].push(editionHash);
        _edition[editionHash] = edition;
    }

    /// @inheritdoc IDistributor
    function pauseEdition(
        bytes32 editionHash,
        bool isPaused
    ) external override onlyCreator(_edition[editionHash].tokenContract, _edition[editionHash].tokenId) {
        _states[editionHash] = !isPaused; // disable minting
        emit PauseEdition(editionHash, isPaused);
    }
    
    // validate condition fulfilment and mint
    function mint(address to, bytes32 editionHash) external payable returns (uint256) {
        require(_states[editionHash], 'Distributor: Minting Disabled');
        IValidator(_edition[editionHash].validator).validate{value: msg.value}(to, editionHash, 0, bytes(''));
        
        uint256 tokenId = _mintToken(to);
        _tokenURI[tokenId] = _fetchURIFromParent(_edition[editionHash].tokenContract, _edition[editionHash].tokenId);
        _editionHash[tokenId] = editionHash;
        
        return tokenId;
    }
    
    function revoke(uint256 tokenId) external onlyCreator(_edition[_editionHash[tokenId]].tokenContract, _edition[_editionHash[tokenId]].tokenId) {
        require(isPermitted(tokenId, _REVOKE), 'Distributor: Non-revokable');
        delete _tokenURI[tokenId];
        delete _editionHash[tokenId];
        _burn(tokenId);
    }

    function destroy(uint256 tokenId) external {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            'ERC721: caller is not token owner nor approved'
        );
        delete _tokenURI[tokenId];
        delete _editionHash[tokenId];
        _burn(tokenId);
    }

    function update(uint256 tokenId) external returns (string memory) {
        require(isPermitted(tokenId, _UPDATE), 'Distributor: Non-updatable');
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            'ERC721: caller is not token owner nor approved'
        );
        _tokenURI[tokenId] = _fetchURIFromParent(_edition[_editionHash[tokenId]].tokenContract, _edition[_editionHash[tokenId]].tokenId);
        return _tokenURI[tokenId];
    }

    function _mintToken(address to) internal returns (uint256) {
        uint256 tokenId = ++_tokenCounter;
        _safeMint(to, tokenId);
        return tokenId;
    }

    function _fetchURIFromParent(address tokenContract, uint256 tokenId) internal view returns (string memory) {
        return IERC721Metadata(tokenContract).tokenURI(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (address(0) != from && address(0) != to) {
            // disable transfer if the token is not transferable. It does not apply to mint/burn action
            require(isPermitted(tokenId, _TRANSFER), 'Distributor: Non-transferable');
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _isApprovedOrCreator(address spender, address tokenContract, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        address owner = IERC721(tokenContract).ownerOf(tokenId);
        return
            owner == spender ||
            IERC721(tokenContract).getApproved(tokenId) == spender ||
            IERC721(tokenContract).isApprovedForAll(owner, spender);
    }

    function _getEditionHash(
        address tokenContract,
        uint256 tokenId
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    tokenContract,
                    tokenId,
                    _editionHashes[tokenContract][tokenId].length
                )
            );
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        return _tokenURI[tokenId];
    }

    function isPermitted(uint256 tokenId, uint96 action) view public returns (bool) {
        return _edition[_editionHash[tokenId]].actions & action == action;
    }
    
    function getEdition(bytes32 editionHash) external view returns (Edition memory) {
        return _edition[editionHash];
    }
    
    function getEditionHashes(address tokenContract, uint256 tokenId) external view returns (bytes32[] memory) {
        return _editionHashes[tokenContract][tokenId];
    }

}
