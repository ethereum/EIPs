pragma solidity >=0.8.0; //important

// EIP-3561 trust minimized proxy implementation https://github.com/ethereum/EIPs/blob/master/EIPS/eip-3561.md
// Based on EIP-1967 upgradeability proxy: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1967.md

contract TrustMinimizedProxy {
    event Upgraded(address indexed toLogic);
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
    event NextLogicDefined(address indexed nextLogic, uint earliestArrivalBlock);
    event ProposingUpgradesRestrictedUntil(uint block, uint nextProposedLogicEarliestArrival);
    event NextLogicCanceled();
    event ZeroTrustPeriodSet(uint blocks);

    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    bytes32 internal constant LOGIC_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 internal constant NEXT_LOGIC_SLOT = 0x19e3fabe07b65998b604369d85524946766191ac9434b39e27c424c976493685;
    bytes32 internal constant NEXT_LOGIC_BLOCK_SLOT = 0xe3228ec3416340815a9ca41bfee1103c47feb764b4f0f4412f5d92df539fe0ee;
    bytes32 internal constant PROPOSE_BLOCK_SLOT = 0x4b50776e56454fad8a52805daac1d9fd77ef59e4f1a053c342aaae5568af1388;
    bytes32 internal constant ZERO_TRUST_PERIOD_SLOT = 0x7913203adedf5aca5386654362047f05edbd30729ae4b0351441c46289146720;

    constructor() payable {
        require(
            ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1) &&
                LOGIC_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1) &&
                NEXT_LOGIC_SLOT == bytes32(uint256(keccak256('eip3561.proxy.next.logic')) - 1) &&
                NEXT_LOGIC_BLOCK_SLOT == bytes32(uint256(keccak256('eip3561.proxy.next.logic.block')) - 1) &&
                PROPOSE_BLOCK_SLOT == bytes32(uint256(keccak256('eip3561.proxy.propose.block')) - 1) &&
                ZERO_TRUST_PERIOD_SLOT == bytes32(uint256(keccak256('eip3561.proxy.zero.trust.period')) - 1)
        );
        _setAdmin(msg.sender);
    }

    modifier IfAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    function _logic() internal view returns (address logic) {
        assembly {
            logic := sload(LOGIC_SLOT)
        }
    }

    function _nextLogic() internal view returns (address nextLogic) {
        assembly {
            nextLogic := sload(NEXT_LOGIC_SLOT)
        }
    }

    function _proposeBlock() internal view returns (uint b) {
        assembly {
            b := sload(PROPOSE_BLOCK_SLOT)
        }
    }

    function _nextLogicBlock() internal view returns (uint b) {
        assembly {
            b := sload(NEXT_LOGIC_BLOCK_SLOT)
        }
    }

    function _zeroTrustPeriod() internal view returns (uint ztp) {
        assembly {
            ztp := sload(ZERO_TRUST_PERIOD_SLOT)
        }
    }

    function _admin() internal view returns (address adm) {
        assembly {
            adm := sload(ADMIN_SLOT)
        }
    }

    function _setAdmin(address newAdm) internal {
        assembly {
            sstore(ADMIN_SLOT, newAdm)
        }
    }

    function changeAdmin(address newAdm) external IfAdmin {
        emit AdminChanged(_admin(), newAdm);
        _setAdmin(newAdm);
    }

    function upgrade(bytes calldata data) external IfAdmin {
        require(block.number >= _nextLogicBlock(), 'too soon');
        address logic;
        assembly {
            logic := sload(NEXT_LOGIC_SLOT)
            sstore(LOGIC_SLOT, logic)
        }
        (bool success, ) = logic.delegatecall(data);
        require(success, 'failed to call');
        emit Upgraded(logic);
    }

    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }

    function _fallback() internal {
        require(msg.sender != _admin());
        _delegate(_logic());
    }

    function cancelUpgrade() external IfAdmin {
        address logic;
        assembly {
            logic := sload(LOGIC_SLOT)
            sstore(NEXT_LOGIC_SLOT, logic)
        }
        emit NextLogicCanceled();
    }

    function prolongLock(uint b) external IfAdmin {
        require(b > _proposeBlock(), 'can be only set higher');
        assembly {
            sstore(PROPOSE_BLOCK_SLOT, b)
        }
        emit ProposingUpgradesRestrictedUntil(b, b + _zeroTrustPeriod());
    }

    function setZeroTrustPeriod(uint blocks) external IfAdmin {
        // before this set at least once acts like a normal eip 1967 transparent proxy
        uint ztp;
        assembly {
            ztp := sload(ZERO_TRUST_PERIOD_SLOT)
        }
        require(blocks > ztp, 'can be only set higher');
        assembly {
            sstore(ZERO_TRUST_PERIOD_SLOT, blocks)
        }
        _updateNextBlockSlot();
        emit ZeroTrustPeriodSet(blocks);
    }

    function _updateNextBlockSlot() internal {
        uint nlb = block.number + _zeroTrustPeriod();
        assembly {
            sstore(NEXT_LOGIC_BLOCK_SLOT, nlb)
        }
    }

    function _setNextLogic(address nl) internal {
        require(block.number >= _proposeBlock(), 'too soon');
        _updateNextBlockSlot();
        assembly {
            sstore(NEXT_LOGIC_SLOT, nl)
        }
        emit NextLogicDefined(nl, block.number + _zeroTrustPeriod());
    }

    function proposeTo(address newLogic, bytes calldata data) external payable IfAdmin {
        if (_zeroTrustPeriod() == 0 || _logic() == address(0)) {
            _updateNextBlockSlot();
            assembly {
                sstore(LOGIC_SLOT, newLogic)
            }
            (bool success, ) = newLogic.delegatecall(data);
            require(success, 'failed to call');
            emit Upgraded(newLogic);
        } else {
            _setNextLogic(newLogic);
        }
    }

    function _delegate(address logic_) internal {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), logic_, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}
