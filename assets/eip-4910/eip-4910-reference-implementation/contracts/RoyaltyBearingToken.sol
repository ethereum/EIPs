// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.10;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './RoyaltyBearingTokenStorage.sol';
import './RoyaltyModule.sol';
import './PaymentModule.sol';

contract RoyaltyBearingToken is ERC721, ERC721Burnable, ERC721Pausable, ERC721URIStorage, AccessControlEnumerable, RoyaltyBearingTokenStorage, IERC721Receiver, ReentrancyGuard {
    using Address for address;
    using Counters for Counters.Counter;
    bool private onlyOnce = false;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        string[] memory allowedTokenTypes,
        address[] memory allowedTokenAddresses,
        address creatorAddress,
        uint256 numGenerations
    ) ERC721(name, symbol) {
        require(_msgSender() == tx.origin, 'Caller must not be a contract');
        require(!creatorAddress.isContract(), 'Creator must not be a contract');
        require(allowedTokenTypes.length == allowedTokenAddresses.length, 'Numbers of allowed tokens');
        _baseTokenURI = baseTokenURI;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(CREATOR_ROLE, creatorAddress);

        _numGenerations = numGenerations;

        for (uint256 i = 0; i < allowedTokenTypes.length; i++) {
            addAllowedTokenType(allowedTokenTypes[i], allowedTokenAddresses[i]);
        }

        //For tree logic we need start id from 1 not 0;
        _tokenIdTracker.increment();
    }

    function init(address royaltyModuleAddress, address paymentModuleAddress) public virtual {
        require(!onlyOnce, 'Init was called before');
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Admin role required');
        royaltyModule = RoyaltyModule(royaltyModuleAddress);
        paymentModule = PaymentModule(paymentModuleAddress);
        onlyOnce = true;
    }

    function updatelistinglimit(uint256 maxListingNumber) public virtual returns (bool) {
        //ensure that msg.sender has the creater role or internal call
        require(hasRole(CREATOR_ROLE, _msgSender()) || address(this) == _msgSender(), 'Creator role required');
        return paymentModule.updatelistinglimit(maxListingNumber);
    }

    function updateRAccountLimits(uint256 maxSubAccounts, uint256 minRoyaltySplit) public virtual returns (bool) {
        //ensure that msg.sender has the creater role or internal call
        require(hasRole(CREATOR_ROLE, _msgSender()) || address(this) == _msgSender(), 'Creator role required');
        return royaltyModule.updateRAccountLimits(maxSubAccounts, minRoyaltySplit);
    }

    function updateMaxGenerations(uint256 newMaxNumber) public virtual returns (bool) {
        //ensure that msg.sender has the creater role or internal call
        require(hasRole(CREATOR_ROLE, _msgSender()) || address(this) == _msgSender(), 'Creator role required');
        _numGenerations = newMaxNumber;
        return true;
    }

    function getModules() public view returns (address, address) {
        return (address(royaltyModule), address(paymentModule));
    }

    function delegateAuthority(
        bytes4 functionSig,
        bytes calldata _functionData,
        bytes32 documentHash,
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        uint256 chainid
    ) public virtual returns (bool) {
        require(chainid == block.chainid, 'Wrong blockchain');
        require(functionSigMap[functionSig], 'Not a valid function');

        bytes32 prefixedProof = keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', documentHash));
        address recovered = ecrecover(prefixedProof, sigV[0], sigR[0], sigS[0]);

        require(hasRole(CREATOR_ROLE, recovered), 'Signature'); //Signature was not from creator

        (bool success, ) = address(this).call(_functionData);
        require(success);
        return true;
    }

    //Note that functionSig must be calculated as follows
    //bytes4(keccak256("updateMaxGenerations(uint256)")
    function setFunctionSignature(bytes4 functionSig) public virtual returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(CREATOR_ROLE, _msgSender()), 'Admin or Creator role required');
        functionSigMap[functionSig] = true;
        return true;
    }

    function onERC721Received(
        address, /*operator*/
        address from,
        uint256, /*tokenId*/
        bytes calldata /*data*/
    ) external pure returns (bytes4) {
        require(from == address(0), 'Only minted');
        //required to allow transfer mined token to this contract
        return bytes4(keccak256('onERC721Received(address,address,uint256,bytes)'));
    }

    function addAllowedTokenType(string memory tokenName, address tokenAddress) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Admin role required');
        if (_isEthToken(tokenName)) {
            tokenAddress = address(this);
        } else {
            require(tokenAddress != address(0x0) && tokenAddress.isContract(), 'Token must be contact');
        }
        require(allowedTokenContract[tokenAddress] == 0, 'Token is duplicate');

        allowedToken[string(tokenName)] = tokenAddress;
        allowedTokenList.push(tokenAddress);
        allowedTokenContract[tokenAddress] = allowedTokenList.length;
    }

    function getAllowedTokens() public view returns (address[] memory) {
        return (allowedTokenList);
    }

    //Royalty module functions
    //Get a Royalty Account through the NFT token index
    function getRoyaltyAccount(uint256 tokenId)
        public
        view
        virtual
        returns (
            address accountId,
            RoyaltyAccount memory account,
            RASubAccount[] memory subaccounts
        )
    {
        require(_exists(tokenId), 'NFT does not exist');
        return royaltyModule.getAccount(tokenId);
    }

    // Rules:
    // Only subaccount owner can decrease splitRoyalty for this subaccount
    // Only parent token owner can decrease royalty subaccount splitRoyalty
    function updateRoyaltyAccount(uint256 tokenId, RASubAccount[] memory affectedSubaccounts) public virtual {
        uint256 parentId = ancestry[tokenId].parentId;
        bool isTokenOwner = getApproved(parentId) == _msgSender();

        royaltyModule.updateRoyaltyAccount(tokenId, affectedSubaccounts, _msgSender(), isTokenOwner);
    }

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(
        address to,
        NFTToken[] memory nfttokens,
        string memory tokenType
    ) public virtual {
        require(nfttokens.length > 0, 'nfttokens has no value');
        require(hasRole(MINTER_ROLE, _msgSender()) || hasRole(CREATOR_ROLE, _msgSender()), 'Minter or Creator role required');
        //ensure to address is not a contract
        require(to != address(0x0), 'Zero Address cannot have active NFTs!');
        //require(!to.isContract(), 'Cannot be minted to contracts');
        if (to == _msgSender()) {
            require(tx.origin == to, 'To must not be contracts');
        } else {
            require(!to.isContract(), 'To must not be contracts');
        }

        //token type must exist
        require(allowedToken[tokenType] != address(0x0), 'Token Type not supported!');

        //Loop through the array of tokens to be minted
        for (uint256 i = 0; i < nfttokens.length; i++) {
            NFTToken memory token = nfttokens[i];

            //royaltySplitForItsChildren must be less or equal to 100%
            require(token.royaltySplitForItsChildren <= 10000, 'Royalty Split is > 100%');

            //If the token cannot have offspring royaltySplitForItsChildren must be zero
            if (!token.canBeParent) {
                token.royaltySplitForItsChildren = 0;
            }

            //create RA account identifier
            uint256 tokenId = _tokenIdTracker.current();

            //enforce business rules
            if (token.parent > 0) {
                require(_exists(token.parent), 'Parent NFT does not exist');

                //update ancestry struct and mapping
                require(ancestry[token.parent].ancestryLevel < _numGenerations, 'Generation limit');
                require(ancestry[token.parent].children.length < ancestry[token.parent].maxChildren, 'Offspring limit');
                ancestry[token.parent].children.push(tokenId);
                // store link to parent
                ancestry[tokenId].parentId = token.parent;
                ancestry[tokenId].ancestryLevel = ancestry[token.parent].ancestryLevel + 1;
            }

            // We cannot just use balanceOf to create the new tokenId because tokens
            // can be burned (destroyed), so we need a separate counter.
            // The NFT contract address(this) must be the owner
            _safeMint(address(this), tokenId);

            //give to address minter role unless it has it already
            _grantRole(MINTER_ROLE, to);

            // after successful minting, the to address will be approved as an NFT controller.
            _approve(to, tokenId);

            //Create and link royalty account
            royaltyModule.createRoyaltyAccount(to, token.parent, tokenId, tokenType, token.royaltySplitForItsChildren);

            //set token URI
            _setTokenURI(tokenId, token.uri);

            //if new token can have children instantiate struct and add to mapping
            if (token.canBeParent) {
                ancestry[tokenId].maxChildren = token.maxChildren;
            }

            //increment token counter to know which is the next token index that can be minted
            _tokenIdTracker.increment();
        }
    }

    function updateMaxChildren(uint256 tokenId, uint256 newMaxChildren) public virtual returns (bool) {
        //ensure that msg.sender has the role minter
        require(hasRole(CREATOR_ROLE, _msgSender()) || address(this) == _msgSender(), 'Creator role required');
        require(newMaxChildren > ancestry[tokenId].children.length, 'Max < Actual');
        ancestry[tokenId].maxChildren = newMaxChildren;

        return true;
    }

    //Functions for support ERC721 extensions
    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), 'Pauser role required');
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), 'Pauser role required');
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerable, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function burn(uint256 tokenId) public virtual override {
        require(getApproved(tokenId) == _msgSender(), 'Sender not authorized to burn');
        require(ancestry[tokenId].children.length == 0, 'NFT must not have children');
        //delete token from royalty (check for 0 balance included)
        royaltyModule.deleteRoyaltyAccount(tokenId);

        _burn(tokenId);

        uint256 parentId = ancestry[tokenId].parentId;
        uint256 length = ancestry[parentId].children.length;
        //delete burned token from ancestry
        for (uint256 i = 0; i < length; i++) {
            if (ancestry[parentId].children[i] == tokenId) {
                //swap with last and delete last element for less gas
                ancestry[parentId].children[i] = ancestry[parentId].children[length - 1];
                delete ancestry[parentId].children[length - 1];
                break;
            }
        }
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public pure override {
        revert('Function not allowed');
    }

    function safeTransferFrom(
        address,
        address,
        uint256
    ) public virtual override {
        revert('Function not allowed');
    }

    function _getTokenBalance(address tokenAddress) private view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function _isEthToken(string memory tokenType) internal pure returns (bool) {
        return keccak256(abi.encodePacked(tokenType)) == keccak256(abi.encodePacked('ETH'));
    }

    function listNFT(
        uint256[] calldata tokenIds,
        uint256 price,
        string calldata tokenType
    ) public virtual returns (bool) {

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(getApproved(tokenIds[i]) == _msgSender(), 'Must be token owner');
            require(royaltyModule.isSupportedTokenType(tokenIds[i], tokenType), 'Unsupported token type');
        }
        //Put tokens to listed
        paymentModule.addListNFT(_msgSender(), tokenIds, price, tokenType);
        return true;
    }

    function removeNFTListing(uint256 tokenId) public virtual returns (bool) {
        require(_msgSender() == getApproved(tokenId), 'Must be token owner');
        paymentModule.removeListNFT(tokenId);
        return true;
    }

    function _requireExistsAndOwned(uint256[] memory tokenIds, address seller) internal view {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_exists(tokenIds[i]), 'Token does not exist');
            require(seller == getApproved(tokenIds[i]), 'Seller is not owner');
        }
    }

    // ERC20 royalty payment
    function executePayment(
        address receiver,
        address seller,
        uint256[] calldata tokenIds,
        uint256 payment,
        string calldata tokenType,
        int256 trxntype
    ) public virtual nonReentrant returns (bool) {
        require(payment > 0, 'Payments cannot be 0!');
        require(trxntype == 0 || trxntype == 1, 'Trxn type not supported');
        require(receiver != address(0), 'Receiver must not be zero');
        _requireExistsAndOwned(tokenIds, seller);
        
            paymentModule.isValidPaymentMetadata(seller, tokenIds, payment, tokenType);
            
        //Execute ERC20 payment
        address payToken = allowedToken[tokenType];
        {
            require(payToken != address(0x0), 'Unsupported token type');
            //Check for ERC20 approval
            uint256 allowed = IERC20(payToken).allowance(_msgSender(), address(this));
            require(allowed >= payment, 'Insufficient token allowance');

            uint256 balanceBefore = _getTokenBalance(payToken);

            //Transfer ERC20 token to contact
            bool success = IERC20(payToken).transferFrom(_msgSender(), address(this), payment);
            require(success && payment == _getTokenBalance(payToken) - balanceBefore, 'ERC20 transfer failed');
        }

        //If the transfer is successful, the registeredPayment mapping is updated if trxntype = 1
        if (trxntype == 1) {
            paymentModule.addRegisterPayment(_msgSender(), tokenIds, payment, tokenType);
        }
        //if trxntype = 0, an internal version of the safeTransferFrom function must be called to transfer the NFTs to the buyer
        else if (trxntype == 0) {
            //encode payment data for transfer(s)
            bytes memory data = abi.encode(seller, _msgSender(), receiver, tokenIds, tokenType, payment, payToken, block.chainid);

            //transfer NFT(s)
            _safeTransferFrom(seller, _msgSender(), tokenIds[0], data);
        }

        return true;
    }

    function checkPayment(
        uint256 tokenId,
        string memory tokenType,
        address buyer
    ) public view virtual returns (uint256) {
        return paymentModule.checkRegisterPayment(tokenId, buyer, tokenType);
    }

    function reversePayment(uint256 tokenId, string memory tokenType) public virtual nonReentrant returns (bool) {
        uint256 payment = checkPayment(tokenId, tokenType, _msgSender());
        require(payment > 0, 'No payment registered');

        bool success;
        if (_isEthToken(tokenType)) {
            //ETH reverse payment
            (success, ) = _msgSender().call{value: payment}('');
            require(success, 'Ether payout issue');
        } else {
            //ERC20 reverse payment
            success = IERC20(allowedToken[tokenType]).transfer(_msgSender(), payment);
            require(success, 'ERC20 transfer failed');
        }
        paymentModule.removeRegisterPayment(_msgSender(), tokenId);

        return success;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override {
        (
            address _seller,
            address _buyer,
            address _receiver,
            uint256[] memory _tokenIds,
            string memory _tokenType,
            uint256 _payment, /*address _tokenTypeAddress*/
            ,
            uint256 _chainId
        ) = abi.decode(data, (address, address, address, uint256[], string, uint256, address, uint256));

        require(_seller == from, 'Seller not From address');
        require(_receiver == to, 'Receiver not To address');
        require(_tokenIds[0] == tokenId, 'Wrong NFT listing');
        require(_chainId == block.chainid, 'Transfer on wrong Blockchain');

        //check register payment
        require(paymentModule.checkRegisterPayment(_buyer, _tokenIds, _payment, _tokenType));

        _requireExistsAndOwned(_tokenIds, _seller);

        //remove register payment
        paymentModule.removeRegisterPayment(to, tokenId);

        //Transfer token
        _safeTransferFrom(from, to, tokenId, data);
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256, /*tokenId*/
        bytes memory data
    ) internal virtual {
        (, , , uint256[] memory _tokenIds, string memory tokenType, uint256 payment, address _tokenTypeAddress, ) = abi.decode(
            data,
            (address, address, address, uint256[], string, uint256, address, uint256)
        );

        require(allowedToken[tokenType] != address(0x0), 'Unsupported token type');

        if (_isEthToken(tokenType)) {
            //Royalty pay in ether
            require(_tokenTypeAddress == address(this), 'token address must be contract');
        }

        //Get payments split
        uint256[] memory _payments = royaltyModule.splitSum(payment, _tokenIds.length);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            //Distribute royalty payment
            royaltyModule.distributePayment(_tokenIds[i], _payments[i]);

            //base transfer after royalty pay
            _approve(to, _tokenIds[i]);
            //super.safeTransferFrom(from, to, _tokenId, data);

            //give to address minter role unless it has it already -- new in ver 1.3
            _grantRole(MINTER_ROLE, to);

            //Force royalty payout for old account
            uint256 balance = royaltyModule.getBalance(_tokenIds[i], payable(from));
            if (balance > 0) _royaltyPayOut(_tokenIds[i], payable(from), payable(from), balance);

            //Transfer RA ownership
            royaltyModule.transferRAOwnership(from, _tokenIds[i], to);
        }

        paymentModule.removeListNFT(_tokenIds[0]);
    }

    receive() external payable {}

    fallback() external payable {
        // decode msg.data to decide which transfer route to take
        (address seller, uint256[] memory tokenIds, address receiver, int256 trxntype) = abi.decode(msg.data, (address, uint256[], address, int256));

        _requireExistsAndOwned(tokenIds, seller);

        paymentModule.isValidPaymentMetadata(seller, tokenIds, msg.value, 'ETH');
        //decide which transfer path to go based on trxntype (0 = direct purchase, 1 = exchange purchase)
        if (trxntype == 1) {
            //register payment for exchange based purchases which require a separate, external call to safeTransferFrom function
            paymentModule.addRegisterPayment(_msgSender(), tokenIds, msg.value, 'ETH');
        } else if (trxntype == 0) {
            //encode payment data for transfer(s)
            bytes memory data = abi.encode(seller, _msgSender(), receiver, tokenIds, 'ETH', msg.value, address(this), block.chainid);

            //transfer NFT(s)
            _safeTransferFrom(seller, _msgSender(), tokenIds[0], data);
        } else {
            //if the trxn type is not supported then we need to revert the entire transaction.
            revert('Trxn type not supported');
        }
    }

    function royaltyPayOut(
        uint256 tokenId,
        address RAsubaccount,
        address payable payoutAccount,
        uint256 amount
    ) public virtual returns (bool) {
        require(_msgSender() == RAsubaccount, 'Sender must be subaccount owner');
        return _royaltyPayOut(tokenId, RAsubaccount, payoutAccount, amount);
    }

    function _royaltyPayOut(
        uint256 tokenId,
        address RAsubaccount,
        address payable payoutAccount,
        uint256 amount
    ) internal virtual returns (bool) {
        royaltyModule.checkBalanceForPayout(tokenId, RAsubaccount, amount);
        string memory tokenType = royaltyModule.getTokenType(tokenId);
        //Reentrancy defence
        royaltyModule.withdrawBalance(tokenId, RAsubaccount, amount);

        //payout in Ether
        if (_isEthToken(tokenType)) {
            (bool success, ) = payoutAccount.call{value: amount}('');
            require(success, 'Ether payout issue');
        }
        //payout in tokens
        else {
            bool success = IERC20(allowedToken[tokenType]).transfer(payoutAccount, amount);
            require(success, 'ERC20 transfer failed');
        }

        return true;
    }
}
