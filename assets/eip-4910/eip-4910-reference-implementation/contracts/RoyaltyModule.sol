// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.10;

import '@openzeppelin/contracts/access/Ownable.sol';
import './StorageStructure.sol';
import 'abdk-libraries-solidity/ABDKMathQuad.sol';

contract RoyaltyModule is StorageStructure, Ownable {
    mapping(uint256 => address) private _tokenindextoRA; //Mapping a tokenId to an raAccountID in order to connect a RA raAccountId to a tokenId
    mapping(address => RoyaltyAccount) private _royaltyaccount; //Mapping the raAccountID to a RoyaltyAccount in order to connect the account identifier to the actual account.
    mapping(address => RASubAccount[]) private _royaltysubaccounts; //workaround for array in struct
    mapping(uint256 => Child) private ancestry; //An ancestry mapping of the parent-to-child NFT relationship

    event RoyalyDistributed(uint256 tokenId, address to, uint256 amount, uint256 assetId);
    address private _ttAddress;
    uint256 private _royaltySplitTT;
    uint256 private _maxSubAccount;
    uint256 private _minRoyaltySplit;

    constructor(
        address owner,
        address ttAddress,
        uint256 royaltySplitTT,
        uint256 minRoyaltySplit,
        uint256 maxSubAccounts
    ) {
        transferOwnership(owner);
        require(royaltySplitTT < 10000, 'Royalty Split to TT is > 100%'); //new v1.3
        require(royaltySplitTT + minRoyaltySplit < 10000, 'Royalty Split to TT + Minimal Split is > 100%');
        require(ttAddress != address(0), 'Zero Address cannot be TT roaylty account');
        _ttAddress = ttAddress;
        _royaltySplitTT = royaltySplitTT;
        _maxSubAccount = maxSubAccounts;
        _minRoyaltySplit = minRoyaltySplit;
    }

    function updateRAccountLimits(uint256 maxSubAccounts, uint256 minRoyaltySplit) public virtual onlyOwner returns (bool) {
        require(_royaltySplitTT + minRoyaltySplit < 10000, 'Royalty Split to TT + Minimal Split is > 100%');
        _maxSubAccount = maxSubAccounts;
        _minRoyaltySplit = minRoyaltySplit;
        return true;
    }

    function getAccount(uint256 tokenId)
        public
        view
        returns (
            address,
            RoyaltyAccount memory,
            RASubAccount[] memory
        )
    {
        address royaltyAccount = _tokenindextoRA[tokenId];
        return (royaltyAccount, _royaltyaccount[royaltyAccount], _royaltysubaccounts[royaltyAccount]);
    }

    // Lib variant
    // Rules:
    // Only subaccount owner can decrease splitRoyalty for this subaccount
    // Only parent token owner can decrease royalty subaccount splitRoyalty
    function updateRoyaltyAccount(
        uint256 tokenId,
        RASubAccount[] memory affectedSubaccounts,
        address sender,
        bool isTokenOwner
    ) public virtual onlyOwner {
        address royaltyAccount = _tokenindextoRA[tokenId];
        //Check total sum of royaltySplit was not changed
        uint256 oldSum;
        uint256 newSum;
        for (uint256 i = 0; i < affectedSubaccounts.length; i++) {
            require(affectedSubaccounts[i].royaltySplit >= _minRoyaltySplit, 'Royalty Split is smaller then set limit');
            newSum += affectedSubaccounts[i].royaltySplit;
            (bool found, uint256 indexOld) = _findSubaccountIndex(royaltyAccount, affectedSubaccounts[i].accountId);
            if (found) {
                RASubAccount storage foundAcc = _royaltysubaccounts[royaltyAccount][indexOld];
                oldSum += foundAcc.royaltySplit;
                //Check rights to decrease royalty split
                if (affectedSubaccounts[i].royaltySplit < foundAcc.royaltySplit) {
                    if (foundAcc.isIndividual) {
                        require(affectedSubaccounts[i].accountId == sender, 'Only individual subaccount owner can decrease royaltySplit');
                    } else {
                        require(isTokenOwner, 'Only parent token owner can decrease royalty subaccount royaltySplit');
                    }
                }
            }
            //New subaccounts must be individual
            else {
                require(affectedSubaccounts[i].isIndividual, 'New subaccounts must be individual');
            }
        }
        require(oldSum == newSum, 'Total royaltySplit must be 10000');

        //Update royalty split for subaccounts and add new subaccounts
        for (uint256 i = 0; i < affectedSubaccounts.length; i++) {
            (bool found, uint256 indexOld) = _findSubaccountIndex(royaltyAccount, affectedSubaccounts[i].accountId);
            if (found) {
                _royaltysubaccounts[royaltyAccount][indexOld].royaltySplit = affectedSubaccounts[i].royaltySplit;
            } else {
                require(_royaltysubaccounts[royaltyAccount].length < _maxSubAccount, 'Too many Royalty subaccounts');
                _royaltysubaccounts[royaltyAccount].push(RASubAccount(true, affectedSubaccounts[i].royaltySplit, 0, affectedSubaccounts[i].accountId));
            }
        }
    }

    //Deleting a Royalty Account
    function deleteRoyaltyAccount(uint256 tokenId) public virtual onlyOwner {
        address royaltyAccount = _tokenindextoRA[tokenId];
        for (uint256 i = 0; i < _royaltysubaccounts[royaltyAccount].length; i++) {
            if (_royaltysubaccounts[royaltyAccount][i].isIndividual) {
                require(_royaltysubaccounts[royaltyAccount][i].royaltyBalance == 0, "Can't delete non empty royalty account");
            }
        }
        delete _royaltyaccount[royaltyAccount];
        delete _royaltysubaccounts[royaltyAccount];
        delete _tokenindextoRA[tokenId];
    }

    function createRoyaltyAccount(
        address to,
        uint256 parentTokenId,
        uint256 tokenId,
        string calldata tokenType,
        uint256 royaltySplitForItsChildren
    ) public onlyOwner returns (address) {
        require(royaltySplitForItsChildren <= 10000, 'Royalty Split to be received from children is > 100%');

        require(_royaltySplitTT + royaltySplitForItsChildren <= 10000, 'Royalty Splits sum is > 100%');
        address raAccountId = address(bytes20(keccak256(abi.encodePacked(tokenId, to, block.number))));
        if (parentTokenId == 0) {
            //Create Royalty account without parent

            //create the RA subaccount for the to address
            _royaltysubaccounts[raAccountId].push(RASubAccount({isIndividual: true, royaltySplit: 10000 - _royaltySplitTT, royaltyBalance: 0, accountId: to}));

            //create the RA subaccount for TreeTrunk
            _royaltysubaccounts[raAccountId].push(RASubAccount({isIndividual: true, royaltySplit: _royaltySplitTT, royaltyBalance: 0, accountId: _ttAddress}));

            //now create the Royalty Account
            //map assetID to RA
            _royaltyaccount[raAccountId] = RoyaltyAccount({assetId: tokenId, parentId: 0, royaltySplitForItsChildren: royaltySplitForItsChildren, tokenType: tokenType, balance: 0});
        } else {
            //Create royalty account with parent

            address parentRoyaltyAccount = _tokenindextoRA[parentTokenId];
            //tokenType must be same as in parent
            require(_isSameString(tokenType, _royaltyaccount[parentRoyaltyAccount].tokenType), 'tokenType must be same as in parent');

            RoyaltyAccount memory parentRA = _royaltyaccount[parentRoyaltyAccount];
            //create the RA subaccount for the to address
            _royaltysubaccounts[raAccountId].push(RASubAccount({isIndividual: true, royaltySplit: 10000 - parentRA.royaltySplitForItsChildren - _royaltySplitTT, royaltyBalance: 0, accountId: to}));

            //create the RA subaccount for TreeTrunk
            _royaltysubaccounts[raAccountId].push(RASubAccount({isIndividual: true, royaltySplit: _royaltySplitTT, royaltyBalance: 0, accountId: _ttAddress}));

            //create the RA subaccount for the RA address of the ancestor
            _royaltysubaccounts[raAccountId].push(RASubAccount({isIndividual: false, royaltySplit: parentRA.royaltySplitForItsChildren, royaltyBalance: 0, accountId: parentRoyaltyAccount}));

            //now create the Royalty Account
            //map assetID to RA
            _royaltyaccount[raAccountId] = RoyaltyAccount({assetId: tokenId, parentId: parentRA.assetId, royaltySplitForItsChildren: royaltySplitForItsChildren, tokenType: tokenType, balance: 0});
        }
        require(_royaltysubaccounts[raAccountId].length <= _maxSubAccount, 'Too many Royalty subaccounts');
        _tokenindextoRA[tokenId] = raAccountId;
        return raAccountId;
    }

    //Function for recursive distribution royalty for RA tree
    function distributePayment(uint256 tokenId, uint256 payment) public virtual onlyOwner returns (bool) {
        address royaltyAccount = _tokenindextoRA[tokenId];
        return _distributePayment(royaltyAccount, payment, tokenId);
    }

    function _distributePayment(
        address royaltyAccount,
        uint256 payment,
        uint256 tokenId
    ) internal virtual returns (bool) {
        uint256 remainsValue = payment;
        uint256 remainsSplit = 10000;
        uint256 assetId = _royaltyaccount[royaltyAccount].assetId;
        for (uint256 i = 0; i < _royaltysubaccounts[royaltyAccount].length; i++) {
            //skip calculate for 0% subaccounts
            if (_royaltysubaccounts[royaltyAccount][i].royaltySplit == 0) continue;
            //calculate royalty split sum
            uint256 paymentSplit = mulDiv(remainsValue, _royaltysubaccounts[royaltyAccount][i].royaltySplit, remainsSplit);
            remainsValue -= paymentSplit;
            remainsSplit -= _royaltysubaccounts[royaltyAccount][i].royaltySplit;
            //distribute if IND subaccount
            if (_royaltysubaccounts[royaltyAccount][i].isIndividual == true) {
                _royaltysubaccounts[royaltyAccount][i].royaltyBalance += paymentSplit;
                emit RoyalyDistributed(tokenId, _royaltysubaccounts[royaltyAccount][i].accountId, paymentSplit, assetId);
            }
            //distribute if RA subaccounts
            else {
                _distributePayment(_royaltysubaccounts[royaltyAccount][i].accountId, paymentSplit, tokenId);
            }
        }
        return true;
    }

    function isSupportedTokenType(uint256 tokenId, string calldata tokenType) public view returns (bool) {
        return _isSameString(tokenType, _royaltyaccount[_tokenindextoRA[tokenId]].tokenType);
    }

    function getTokenType(uint256 tokenId) public view returns (string memory) {
        return _royaltyaccount[_tokenindextoRA[tokenId]].tokenType;
    }

    function findSubaccountIndex(uint256 tokenId, address subaccount) public view virtual returns (bool, uint256) {
        address royaltyAccount = _tokenindextoRA[tokenId];
        return _findSubaccountIndex(royaltyAccount, subaccount);
    }

    function checkBalanceForPayout(
        uint256 tokenId,
        address subaccount,
        uint256 amount
    ) public view virtual returns (bool) {
        (bool subaccountFound, uint256 subaccountIndex) = findSubaccountIndex(tokenId, subaccount);
        require(subaccountFound, 'Subaccount not found');
        RASubAccount memory subAccount = getSubaccount(tokenId, subaccountIndex);
        require(subAccount.isIndividual == true, 'Subaccount must be individual');
        require(subAccount.royaltyBalance >= amount, 'Insufficient royalty balance');
        return true;
    }

    function getSubaccount(uint256 tokenId, uint256 subaccountIndex) public view virtual returns (RASubAccount memory) {
        return _royaltysubaccounts[_tokenindextoRA[tokenId]][subaccountIndex];
    }

    function getBalance(uint256 tokenId, address subaccount) public view virtual returns (uint256) {
        (bool found, uint256 subaccountIndex) = findSubaccountIndex(tokenId, subaccount);
        if (!found) return 0;
        return getSubaccount(tokenId, subaccountIndex).royaltyBalance;
    }

    //Used for reduce royalty ballance after payout
    //Used only in RoyaltyBearingToken._royaltyPayOut(uint256,address,address,uint256)
    function withdrawBalance(
        uint256 tokenId,
        address subaccount,
        uint256 amount
    ) public virtual onlyOwner {
        (bool subaccountFound, uint256 subaccountIndex) = findSubaccountIndex(tokenId, subaccount);
        require(subaccountFound, 'Subaccount not found');
        require(_royaltysubaccounts[_tokenindextoRA[tokenId]][subaccountIndex].royaltyBalance >= amount, 'Insufficient royalty balance');
        _royaltysubaccounts[_tokenindextoRA[tokenId]][subaccountIndex].royaltyBalance -= amount;
    }

    //Used in RoyaltyBearingToken._safeTransferFrom(address, address,uint256, bytes)
    //for transfer royalty account ownership after tranfer token ownership
    function transferRAOwnership(
        address seller,
        uint256 tokenId,
        address buyer
    ) public virtual onlyOwner {
        address royaltyAccount = _tokenindextoRA[tokenId];
        (bool found, uint256 index) = _findSubaccountIndex(royaltyAccount, seller);
        require(found, 'Seller subaccount not found');
        require(_royaltysubaccounts[royaltyAccount][index].royaltyBalance == uint256(0), 'Seller subaccount must have 0 balance');

        //replace owner of subaccount
        _royaltysubaccounts[royaltyAccount][index].accountId = buyer;
    }

    // Find subaccount index by subaccount address
    function _findSubaccountIndex(address royaltyAccount, address subaccount) internal view virtual returns (bool, uint256) {
        //local variable decrease contract code size
        RASubAccount[] storage subAccounts = _royaltysubaccounts[royaltyAccount];
        for (uint256 i = 0; i < subAccounts.length; i++) {
            if (subAccounts[i].accountId == subaccount) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    //Util function for split royalty payment
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) public pure returns (uint256) {
        return ABDKMathQuad.toUInt(ABDKMathQuad.div(ABDKMathQuad.mul(ABDKMathQuad.fromUInt(x), ABDKMathQuad.fromUInt(y)), ABDKMathQuad.fromUInt(z)));
    }

    //Util function for  split value by pieces without remains
    function splitSum(uint256 sum, uint256 pieces) public pure virtual returns (uint256[] memory) {
        uint256[] memory result = new uint256[](pieces);
        uint256 remains = sum;
        for (uint256 i = 0; i < pieces; i++) {
            result[i] = mulDiv(remains, 1, pieces - i);
            remains -= result[i];
        }
        return result;
    }
}
