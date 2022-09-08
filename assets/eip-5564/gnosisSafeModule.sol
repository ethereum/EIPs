// SPDX-License-Identifier: CC0-1.0

pragma solidity >=0.7.0 <0.9.0;

import "@gnosis.pm/zodiac/contracts/core/Module.sol";
import "./EllipticCurve.sol";

interface GnosisSafe {
    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(address to, uint256 value, bytes calldata data, Enum.Operation operation)
        external
        returns (bool success);
}


/// @dev Contract to emit Information required by the recipients of private Transfers to determine
///      if they were the recipient of a transfer. Users can derive a key pair from the publishableData
///      part and compare it to the stealthRecipient address. If machting, the respective users can be sure
///      to have the corresponding private key to access the funds. 
/// @notice PubStealthInfoContract MUST be an immutable implementation, shared across every type of asset that 
///         may be transferred using the stealth address mech
contract PubStealthInfoContract {

    event PrivateTransferInfo(address indexed stealthRecipient, bytes publishableData);

    function emitPrivateTransferInfo(address stealthRecipient, bytes calldata publishableData) external {
        emit PrivateTransferInfo(stealthRecipient, publishableData);
    }
}


contract MyModule is Module {
    PubStealthInfoContract public pubStealthInfoContract;


    constructor(address _owner, address _pubStealthInfoContract) {
        bytes memory initializeParams = abi.encode(_owner, _pubStealthInfoContract);
        setUp(initializeParams);
    }

    /// @dev Initialize function, will be triggered when a new proxy is deployed
    /// @param initializeParams Parameters of initialization encoded
    function setUp(bytes memory initializeParams) public override initializer {
        __Ownable_init();
        (address _owner, address _pubStealthInfoContract) = abi.decode(initializeParams, (address, address));
        pubStealthInfoContract = PubStealthInfoContract(_pubStealthInfoContract);
        setAvatar(_owner);
        setTarget(_owner);
        transferOwnership(_owner);
    }

    /// @dev Execute Transfer to stealth address
    /// @param publishableData Is broadcasted by an immutable implementation of pubStealthInfoContract
    /// TODO: Add ERC20, ERC721 etc. support
    function privateETHTransfer(
        GnosisSafe safe, 
        address payable to, 
        uint256 amount, 
        bytes calldata publishableData
    ) external payable {
        require(safe.execTransactionFromModule(to, amount, "", Enum.Operation.Call), "Could not execute ether transfer");
        pubStealthInfoContract.emitPrivateTransferInfo(to, publishableData);
    }    
}


contract MockSafe {
    address public module;

    // Secp256k1 Elliptic Curve
    uint256 public constant GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
    uint256 public constant GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
    uint256 public constant AA = 0;
    uint256 public constant BB = 7;
    uint256 public constant PP = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

    uint256 public PublicKeyX = 89565891926547004231252920425935692360644145829622209833684329913297188986597;
    uint256 public PublicKeyY = 12158399299693830322967808612713398636155367887041628176798871954788371653930;

    error NotAuthorized(address unacceptedAddress);

    receive() external payable {}

    function enableModule(address _module) external {
        module = _module;
    }

    function exec(
        address payable to,
        uint256 value,
        bytes calldata data
    ) external {
        bool success;
        bytes memory response;
        (success, response) = to.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(response, 0x20), mload(response))
            }
       }
    }

    function execTransactionFromModule(
        address payable to,
        uint256 value,
        bytes calldata data,
        uint8 operation
    ) external returns (bool success) {
        if (msg.sender != module) revert NotAuthorized(msg.sender);
        if (operation == 1) (success, ) = to.delegatecall(data);
        else (success, ) = to.call{value: value}(data);
    }

    function generateStealthAddress(uint256 secret) public view returns (uint256, uint256, address){
        //  s*G = S
        (uint256 pubDataX,uint256 pubDataY) = EllipticCurve.ecMul(secret, GX, GY, AA, PP);
        //  s*P = q
        (uint256 Qx,uint256 Qy) = EllipticCurve.ecMul(secret, PublicKeyX, PublicKeyY, AA, PP);
        // hash(sharedSecret)
        bytes32 hQ = keccak256(abi.encodePacked(Qx, Qy));
        // hash value to public key
        (Qx, Qy) = EllipticCurve.ecMul(uint(hQ), GX, GY, AA, PP);
        // derive new public key
        (Qx, Qy) = EllipticCurve.ecAdd(PublicKeyX, PublicKeyY, Qx, Qy, AA, PP);
        // generate stealth address
        address stealthAddress = address(uint160(uint256(keccak256(abi.encodePacked(Qx, Qy)))));
        // return public key coordinates and stealthAddress
        return (pubDataX, pubDataY, stealthAddress);
    }
}
