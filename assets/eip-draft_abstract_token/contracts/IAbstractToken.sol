// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import { IERC165 } from '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { IERC1155 } from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';

struct AbstractTokenMessage {
  uint256 chainId; // the chain where the token(s) can be reified
  address implementation; // the contract by which the token(s) can be reified
  address owner; // the address that owns the token(s)
  bytes meta; // application-specific information defining the token(s)
  uint256 nonce; // counter to allow otherwise duplicate messages
  bytes proof; // application-specific information authorizing the creation of the token(s)
}

enum AbstractTokenMessageStatus {
  invalid, // the token message is rejected by the contract
  valid, // the token message is valid and has not already been used
  used // the token message has already been used to reify or dereify tokens
}

interface IAbstractToken {
  event Reify(AbstractTokenMessage);
  event Dereify(AbstractTokenMessage);

  // transforms token(s) from message to contract
  function reify(AbstractTokenMessage calldata message) external;

  // transforms token(s) from contract to message
  function dereify(AbstractTokenMessage calldata message) external;

  // check abstract token message status: an abstract token message can only be reified if valid and not already reified
  function status(AbstractTokenMessage calldata message)
    external
    view
    returns (AbstractTokenMessageStatus status);

  // id of token in message
  function id(AbstractTokenMessage calldata message) external view returns (uint256);

  // quantity of tokens in the message
  function amount(AbstractTokenMessage calldata message) external view returns (uint256);

  // reference to further information on the tokens
  function uri(AbstractTokenMessage calldata message) external view returns (string memory);
}

// example abstract token interfaces
interface IAbstractERC20 is IAbstractToken, IERC20, IERC165 {
  // reify the message and then transfer tokens
  function transfer(
    address to,
    uint256 amount,
    AbstractTokenMessage calldata message
  ) external returns (bool);

  // reify the message and then transferFrom tokens
  function transferFrom(
    address from,
    address to,
    uint256 amount,
    AbstractTokenMessage calldata message
  ) external returns (bool);
}

interface IAbstractERC721 is IAbstractToken, IERC721 {
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata _data,
    AbstractTokenMessage calldata message
  ) external;

  function transferFrom(
    address from,
    address to,
    uint256 tokenId,
    AbstractTokenMessage calldata message
  ) external;
}

interface IAbstractERC1155 is IAbstractToken, IERC1155 {
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes calldata data,
    AbstractTokenMessage calldata message
  ) external;

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata data,
    AbstractTokenMessage[] calldata messages
  ) external;
}
