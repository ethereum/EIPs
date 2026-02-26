// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

import "./IKBT721.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract KBT721 is IKBT721, ERC721Enumerable, Ownable {
    mapping(address => AccountHolderBindings) private _holderAccounts;
    mapping(address => FirstAccountBindings) private _firstAccounts;
    mapping(address => SecondAccountBindings) private _secondAccounts;

    mapping(address => TransferConditions) private _transferConditions;
    mapping(address => ApprovalConditions) private _approvalConditions;

    mapping(address => mapping(address => uint256))
        private _numberOfTransfersAllowed;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {}

    function addBindings(
        address _keyWallet1,
        address _keyWallet2
    ) external virtual override returns (bool) {
        address sender = _msgSender();
        require(balanceOf(sender) > 0, "[200] KBT721: Wallet is not a holder");
        require(
            _holderAccounts[sender].firstWallet == address(0) &&
                _holderAccounts[sender].secondWallet == address(0),
            "[201] KBT721: Key wallets are already filled"
        );
        require(
            _keyWallet1 != address(0) && _keyWallet2 != address(0),
            "[202] KBT721: Does not follow 0x standard"
        );
        require(
            _keyWallet1 != _keyWallet2,
            "[205] KBT721: Key wallet 1 must be different than key wallet 2"
        );
        require(
            _keyWallet1 != sender,
            "[206] KBT721: Key wallet 1 must be different than the sender"
        );
        require(
            sender != _keyWallet2,
            "[207] KBT721: Key wallet 2 must be different than the sender"
        );
        require(
            _firstAccounts[_keyWallet1].accountHolderWallet == address(0),
            "[203] KBT721: Key wallet 1 is already registered"
        );
        require(
            _secondAccounts[_keyWallet2].accountHolderWallet == address(0),
            "[204] KBT721: Key wallet 2 is already registered"
        );
        _holderAccounts[sender] = AccountHolderBindings({
            firstWallet: _keyWallet1,
            secondWallet: _keyWallet2
        });
        _firstAccounts[_keyWallet1] = FirstAccountBindings({
            accountHolderWallet: sender,
            secondWallet: _keyWallet2
        });
        _secondAccounts[_keyWallet2] = SecondAccountBindings({
            accountHolderWallet: sender,
            firstWallet: _keyWallet1
        });
        emit AccountSecured(sender, balanceOf(sender));
        return true;
    }

    function getBindings(
        address _account
    ) external view virtual override returns (AccountHolderBindings memory) {
        return _holderAccounts[_account];
    }

    function resetBindings() external virtual override returns (bool) {
        address accountHolder = _getAccountHolder();
        require(
            accountHolder != address(0),
            "[300] KBT721: Key authorization failure"
        );
        delete _firstAccounts[_holderAccounts[accountHolder].firstWallet];
        delete _secondAccounts[_holderAccounts[accountHolder].secondWallet];
        delete _holderAccounts[accountHolder];
        emit AccountResetBinding(accountHolder);
        return true;
    }

    function safeFallback() external virtual override returns (bool) {
        address accountHolder = _getAccountHolder();
        address otherSecureWallet = _getOtherSecureWallet();
        require(
            accountHolder != address(0),
            "[400] KBT721: Key authorization failure"
        );

        uint256 noOfTokens = balanceOf(accountHolder);
        uint256 i = 0;
        while (i++ < noOfTokens) {
            uint256 tempTokenId = tokenOfOwnerByIndex(accountHolder, 0);
            _transfer(accountHolder, otherSecureWallet, tempTokenId);
        }

        emit SafeFallbackActivated(accountHolder);

        return true;
    }

    function allowTransfer(
        uint256 _tokenId,
        uint256 _time,
        address _to,
        bool _anyToken
    ) external virtual returns (bool) {
        address accountHolder = _getAccountHolder();

        require(
            accountHolder != address(0),
            "[500] KBT721: Key authorization failure"
        );
        if (_tokenId > 0) {
            address _owner = ownerOf(_tokenId);
            require(_owner == accountHolder, "[501] KBT721: Invalid tokenId.");
        }

        _time = _time > 0 ? (block.timestamp + _time) : 0;

        _transferConditions[accountHolder] = TransferConditions({
            tokenId: _tokenId,
            time: _time,
            to: _to,
            anyToken: _anyToken
        });

        emit AccountEnabledTransfer(
            accountHolder,
            _tokenId,
            _time,
            _to,
            _anyToken
        );

        return true;
    }

    function getTransferableFunds(
        address _account
    ) external view returns (TransferConditions memory) {
        return _transferConditions[_account];
    }

    function allowApproval(
        uint256 _time,
        uint256 _numberOfTransfers
    ) external virtual returns (bool) {
        address accountHolder = _getAccountHolder();
        require(
            accountHolder != address(0),
            "[600] KBT721: Key authorization failure"
        );

        _time = block.timestamp + _time;

        _approvalConditions[accountHolder].time = _time;
        _approvalConditions[accountHolder]
            .numberOfTransfers = _numberOfTransfers;

        emit AccountEnabledApproval(accountHolder, _time, _numberOfTransfers);

        return true;
    }

    function getApprovalConditions(
        address _account
    ) external view returns (ApprovalConditions memory) {
        return _approvalConditions[_account];
    }

    function getNumberOfTransfersAllowed(
        address _account,
        address _spender
    ) external view returns (uint256) {
        return _numberOfTransfersAllowed[_account][_spender];
    }

    function isSecureWallet(address _account) public view returns (bool) {
        return
            _holderAccounts[_account].firstWallet != address(0) &&
            _holderAccounts[_account].secondWallet != address(0);
    }

    function isSecureToken(
        uint256 _tokenId
    ) public view virtual override returns (bool) {
        address _owner = ownerOf(_tokenId);

        return isSecureWallet(_owner);
    }

    // region ERC721 overrides

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual override(ERC721, IERC721) {
        address _sender = _msgSender();
        address _owner = ownerOf(_tokenId);

        if (_sender == _owner && isSecureWallet(_owner)) {
            require(
                _hasAllowedTransfer(_owner, _tokenId, _to),
                "[100] KBT721: Sender is a secure wallet and doesn't have approval for the token"
            );
        }

        super.transferFrom(_from, _to, _tokenId);

        if (_sender == _owner) {
            delete _transferConditions[_owner];
        } else {
            if (_numberOfTransfersAllowed[_owner][_sender] != 0) {
                if (_numberOfTransfersAllowed[_owner][_sender] == 1) {
                    _setApprovalForAll(_owner, _sender, false);
                }
                _numberOfTransfersAllowed[_owner][_sender] -= 1;
            }
        }
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual override(ERC721, IERC721) {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) public virtual override(ERC721, IERC721) {
        address _sender = _msgSender();
        address _owner = ownerOf(_tokenId);

        if (_sender == _owner && isSecureWallet(_owner)) {
            require(
                _hasAllowedTransfer(_owner, _tokenId, _to),
                "[100] KBT721: Owner is a secure wallet and doesn't have approval for the token"
            );
        }

        super.safeTransferFrom(_from, _to, _tokenId, data);

        if (_sender == _owner) {
            delete _transferConditions[_owner];
        } else {
            if (_numberOfTransfersAllowed[_owner][_sender] != 0) {
                if (_numberOfTransfersAllowed[_owner][_sender] == 1) {
                    _setApprovalForAll(_owner, _sender, false);
                }
                _numberOfTransfersAllowed[_owner][_sender] -= 1;
            }
        }
    }

    function approve(
        address _to,
        uint256 _tokenId
    ) public virtual override(ERC721, IERC721) {
        address _owner = ownerOf(_tokenId);

        if (isSecureWallet(_owner)) {
            require(
                _approvalConditions[_owner].time > 0,
                "[101] KBT721: Spending of funds is not authorized."
            );
            require(
                _isApprovalAllowed(_owner),
                "[102] KBT721: Time has expired for the spending of funds"
            );
        }

        super.approve(_to, _tokenId);

        _numberOfTransfersAllowed[_owner][_to] = _approvalConditions[_owner]
            .numberOfTransfers;

        delete _approvalConditions[_owner];
    }

    function setApprovalForAll(
        address _operator,
        bool _approved
    ) public virtual override(ERC721, IERC721) {
        address _sender = _msgSender();
        if (isSecureWallet(_sender)) {
            require(
                _approvalConditions[_sender].time > 0,
                "[101] KBT721: Spending of funds is not authorized."
            );
            require(
                _isApprovalAllowed(_sender),
                "[102] KBT721: Time has expired for the spending of funds"
            );
        }

        super.setApprovalForAll(_operator, _approved);

        _numberOfTransfersAllowed[_sender][_operator] = _approvalConditions[
            _sender
        ].numberOfTransfers;

        delete _approvalConditions[_sender];
    }

    function _afterTokenTransfer(
        address _from,
        address _to,
        uint256 _firstTokenId,
        uint256 _batchSize
    ) internal virtual override {
        if (_from != address(0)) {
            // region update secureAccounts
            if (isSecureWallet(_from) && balanceOf(_from) == 0) {
                delete _firstAccounts[_holderAccounts[_from].firstWallet];
                delete _secondAccounts[_holderAccounts[_from].secondWallet];
                delete _holderAccounts[_from];
            }
            // endregion
            if (balanceOf(_from) == 0) {
                emit Egress(_from, _firstTokenId);
            }
        }

        if (_to != address(0) && balanceOf(_to) == _batchSize) {
            emit Ingress(_to, _firstTokenId);
        }
    }

    // endregion

    function _hasAllowedTransfer(
        address _account,
        uint256 _tokenId,
        address _to
    ) internal view returns (bool) {
        TransferConditions memory conditions = _transferConditions[_account];

        if (conditions.anyToken) {
            return true;
        }

        if (
            (conditions.tokenId == 0 &&
                conditions.time == 0 &&
                conditions.to == address(0)) ||
            (conditions.tokenId > 0 && conditions.tokenId != _tokenId) ||
            (conditions.time > 0 && conditions.time < block.timestamp) ||
            (conditions.to != address(0) && conditions.to != _to)
        ) {
            return false;
        }

        return true;
    }

    function _isApprovalAllowed(address account) internal view returns (bool) {
        return _approvalConditions[account].time >= block.timestamp;
    }

    function _getAccountHolder() internal view returns (address) {
        address sender = _msgSender();
        return
            _firstAccounts[sender].accountHolderWallet != address(0)
                ? _firstAccounts[sender].accountHolderWallet
                : (
                    _secondAccounts[sender].accountHolderWallet != address(0)
                        ? _secondAccounts[sender].accountHolderWallet
                        : address(0)
                );
    }

    function _getOtherSecureWallet() internal view returns (address) {
        address sender = _msgSender();
        address accountHolder = _getAccountHolder();

        return
            _holderAccounts[accountHolder].firstWallet == sender
                ? _holderAccounts[accountHolder].secondWallet
                : _holderAccounts[accountHolder].firstWallet;
    }
}
