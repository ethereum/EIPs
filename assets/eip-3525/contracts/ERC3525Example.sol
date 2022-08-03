//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC3525.sol";
import "StringConvertor.sol";
import "base64.sol";

/**
 * This is a demo contract for how to generate slot
 */
contract ERC3525Example is ERC3525 {
    using StringConvertor for uint256;

    /**
     * @notice Properties of the slot, which determine the value of slot.
     */
    struct SlotDetail {
        string name;
        string description;
        string image;
        address underlying;
        uint8 vestingType;
        uint32 maturity;
        uint32 term;
    }

    // slot => slotDetail
    mapping(uint256 => SlotDetail) private _slotDetails;

    uint256 constant _externalMintMaxId = 1000000000;

    constructor( string memory name_, string memory symbol_, uint8 decimals_) ERC3525(name_, symbol_, decimals_) {}

    function mint( string memory slotName_, string memory slotDescription_, string memory slotImage_,
        uint256 tokenId_, address underlying_, uint8 vestingType_, uint32 maturity_, uint32 term_, uint256 value_) public {
        require(tokenId_ < _externalMintMaxId, "ERC3525: tokenId is too large");
        uint256 slot = _getSlot(underlying_, vestingType_, maturity_, term_);
        _slotDetails[slot] = SlotDetail({
            name: slotName_,
            description: slotDescription_,
            image: slotImage_,
            underlying: underlying_,
            vestingType: vestingType_,
            maturity: maturity_,
            term: term_
        });

        ERC3525._mintValue(_msgSender(), tokenId_, slot, value_);
    }

    function getSlotDetail(uint256 slot_) public view returns (SlotDetail memory) {
        return _slotDetails[slot_];
    }

    function _getNewTokenId(uint256 fromTokenId_) internal virtual override returns (uint256) {
        return 1000000000 + fromTokenId_;
    }

    /**
     * @dev Generate the value of slot by utilizing keccak256 algorithm to calculate the hash
     * value of multi properties.
     */
    function _getSlot( address underlying_, uint8 vestingType_, uint32 maturity_, uint32 term_) internal pure virtual returns (uint256 slot_) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        underlying_,
                        vestingType_,
                        maturity_,
                        term_
                    )
                )
            );
    }

    function slotURI(uint256 slot_) public view virtual override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    /* solhint-disable */
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"',
                            _slotDetails[slot_].name,
                            '","description":"',
                            _slotDetails[slot_].description,
                            '","image":"',
                            _slotDetails[slot_].image,
                            '","properties":',
                            _slotProperties(slot_),
                            "}"
                        )
                    )
                    /* solhint-enable */
                )
            );
    }

    /**
     * @dev Generate the content of the `properties` field of `slotURI`.
     */
    function _slotProperties(uint256 slot_) internal view returns (string memory) {
        SlotDetail storage slotDetail = _slotDetails[slot_];
        return
            string(
                /* solhint-disable */
                abi.encodePacked(
                    "[",
                    abi.encodePacked(
                        '{"name":"underlying",',
                        '"description":"Address of the underlying token locked in this contract.",',
                        '"value":"',
                        Strings.toHexString(
                            uint256(uint160(slotDetail.underlying))
                        ),
                        '",',
                        '"order":1,',
                        '"display_type":"string"},'
                    ),
                    abi.encodePacked(
                        '{"name":"vesting_type",',
                        '"description":"Vesting type that represents the releasing mode of underlying assets.",',
                        '"value":',
                        uint256(slotDetail.vestingType).toString(),
                        ",",
                        '"order":2,',
                        '"display_type":"number"},'
                    ),
                    abi.encodePacked(
                        '{"name":"maturity",',
                        '"description":"Maturity that all underlying assets would be completely released.",',
                        '"value":',
                        uint256(slotDetail.maturity).toString(),
                        ",",
                        '"order":3,',
                        '"display_type":"date"},'
                    ),
                    abi.encodePacked(
                        '{"name":"term",',
                        '"description":"The length of the locking period (in seconds)",',
                        '"value":',
                        uint256(slotDetail.term).toString(),
                        ",",
                        '"order":4,',
                        '"display_type":"number"}'
                    ),
                    "]"
                )
                /* solhint-enable */
            );
    }
}
