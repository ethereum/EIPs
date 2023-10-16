//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../ERC3525/interfaces/IERC3525Metadata.sol";
import "./IERC5727.sol";

/**
 * @title ERC5727 Soulbound Token Metadata Interface
 * @dev This extension allows querying the metadata of soulbound tokens.
 */
interface IERC5727Metadata is IERC3525Metadata, IERC5727 {

}
