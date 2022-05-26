///SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import "./smartNFT_interface.sol";
import "./ERC721_interface.sol";

contract smartNFT_SC is ERC721,smartNFT{
     enum States { waitingForOwner, engagedWithOwner, waitingForUser, engagedWithUser }
    
    address manufacturer;                                   //Address of manufacturer and owner of Smart Contract
    uint256 tokenCounter;                                   //To give a genuine tokenID based on the number of tokens created
    mapping(uint256 => address) ownerOfSD;                  //To khow who is the owner of a specific owner
    mapping(address => uint256) tokenIDOfBCA;               //To khow which is the tokenID associated to a secure device from the address
    mapping(address => uint256) ownerBalance;               //To know how many tokens an owner has
    mapping(address => uint256) userBalance;                //To know how many tokens a user can use
    
    struct Token_Struct{
        address approved;                                   //Indicate who can transfer this token, 0 if no one
        address SD;                                         //Indicate the address of the secure device associated to this token
        address user;                                       //Indicate who can use this secure device
        States state;                                       //If blocked (false) then token should be verified by a new user or a new owner
        uint256 hashK_OD;                                   //Hash of the Key shared between owner and device
        uint256 hashK_UD;                                   //Hash of the Key shared between user and device
        uint256 dataEngagement;                             //Public Key to create K_OD or K_UD depending on token state
        uint256 timestamp;                                  //Last time that device updated its proof of live
        uint256 timeout;                                    //timeout to verify a device error
    }
    
    Token_Struct[] Secure_Token;
    
    constructor() {
        manufacturer = msg.sender;
        tokenCounter = 1;
        Secure_Token.push(Token_Struct(address(0), address(0), address(0), States.waitingForOwner,0,0,0,0,0));

    }
    
    function createToken(address _addressSD, address _addressOwner) public virtual override returns (uint256){
        //Check if the sender of message is the manufacturer
        require(manufacturer == msg.sender);
        //Check if the Blockchain Account of the secure device is in the SmartContract
        if(tokenFromBCA(_addressSD)==0){
            //Create a new token
            Secure_Token.push(Token_Struct(address(0), _addressSD, address(0), States.waitingForOwner,0,0,0,block.timestamp,86400));
            //Assigning a new tokenId
            uint256 _tokenId = tokenCounter ++;
            tokenIDOfBCA[_addressSD] = _tokenId;
            //Assigning the owner
            ownerOfSD[_tokenId] = _addressOwner;
            ownerBalance[_addressOwner]++;
            //Return tokenId obtained
            return(_tokenId);
        }else{
            //If the BCA already exists then return the _tokenId
            return(tokenFromBCA(_addressSD));
        }
    }

    function setUser(uint256 _tokenId, address _addressUser) public virtual override{
        //Check the sender and the token state
        require((ownerOfSD[_tokenId] == msg.sender) && (Secure_Token[_tokenId].state >= States.engagedWithOwner));
        if((Secure_Token[_tokenId].timestamp + Secure_Token[_tokenId].timeout) > block.timestamp){
            //Only to avoid overflow, for example, in address 0.
            if(userBalance[Secure_Token[_tokenId].user]>0){
                //Update the balance of tokens assigned to the old user
                userBalance[Secure_Token[_tokenId].user]--;
            }
            //Update the balance of tokens assigned to the new user
            userBalance[_addressUser]++;
            //Assign the new user to the token
            Secure_Token[_tokenId].user = _addressUser;            
            //Update the state of the token
            Secure_Token[_tokenId].state = States.waitingForUser;
            //Erase old key exchange data between device with old user assigned
            Secure_Token[_tokenId].dataEngagement =0;
            Secure_Token[_tokenId].hashK_UD = 0;
            emit UserAssigned(_tokenId,_addressUser);
        }else{
            Secure_Token[_tokenId].user = address(0);
            emit TimeoutAlarm(_tokenId);
        }
    }
    
    function startOwnerEngagement(uint256 _tokenId, uint256 _dataEngagement, uint256 _hashK_O) public virtual override{
        //Check if sender is the Owner of token and the State of token
        require(ownerOfSD[_tokenId] == msg.sender);
        if((Secure_Token[_tokenId].timestamp + Secure_Token[_tokenId].timeout) > block.timestamp){
            Secure_Token[_tokenId].dataEngagement = _dataEngagement;
            Secure_Token[_tokenId].hashK_OD = _hashK_O;
        }else{
            Secure_Token[_tokenId].user = address(0);
            emit TimeoutAlarm(_tokenId);
        }
    }
    
    function ownerEngagement(uint256 _hashK_D) public virtual override{
        uint256 _tokenId = tokenFromBCA(msg.sender);
        //Check if public key owner-device exists from tokenID of BCA sender
        require(Secure_Token[_tokenId].dataEngagement != 0);
        require (Secure_Token[_tokenId].hashK_OD == _hashK_D);
        require (Secure_Token[_tokenId].state == States.waitingForOwner);
        //Erase PK_Owner-Device and update timestamp
        Secure_Token[_tokenId].dataEngagement = 0;
        Secure_Token[_tokenId].timestamp = block.timestamp;
        //Update the state of token
        Secure_Token[_tokenId].state = States.engagedWithOwner;
        //Send a notification to owner and device
        emit OwnerEngaged(_tokenId);
    }
    
    function startUserEngagement(uint256 _tokenId, uint256 _dataEngagement, uint256 _hashK_U) public virtual override{
        //Check the sender and the state of token
        require(Secure_Token[_tokenId].user == msg.sender);    
        if((Secure_Token[_tokenId].timestamp + Secure_Token[_tokenId].timeout) > block.timestamp){
            Secure_Token[_tokenId].dataEngagement = _dataEngagement;
            Secure_Token[_tokenId].hashK_UD = _hashK_U;
        }else{
            Secure_Token[_tokenId].user = address(0);
            emit TimeoutAlarm(_tokenId);
        }
    }
    
    function userEngagement(uint256 _hashK_D) public virtual override{
        uint256 _tokenId = tokenFromBCA(msg.sender);
        //Check if public key user-device exists from tokenID of BCA sender
        require(Secure_Token[_tokenId].dataEngagement != 0);
        require (Secure_Token[_tokenId].hashK_UD == _hashK_D);
        require (Secure_Token[_tokenId].state == States.waitingForUser);
        //Erase PK_User-Device and update timestamp
        Secure_Token[_tokenId].dataEngagement = 0;
        Secure_Token[_tokenId].timestamp = block.timestamp;
        //Update the state of token
        Secure_Token[_tokenId].state = States.engagedWithUser;
        //Send a notification to user and device
        emit UserEngaged(_tokenId);
    }
    
    
    function tokenFromBCA(address _addressSD) public virtual view override returns (uint256){
        return(tokenIDOfBCA[_addressSD]);
    }
    
    function ownerOfFromBCA(address _addressSD) public virtual view override returns (address){
        return(ownerOfSD[tokenIDOfBCA[_addressSD]]);
    }
    
    function userOf(uint256 _tokenId) public virtual view override returns (address){
         return(Secure_Token[_tokenId].user);
    }
    
    function userOfFromBCA(address _addressSD) public virtual override view returns (address){
        return(Secure_Token[tokenIDOfBCA[_addressSD]].user);
    }   
    
    function userBalanceOf(address _addressUser) public virtual override view returns (uint256){
        return(userBalance[_addressUser]);
    }
    
    function userBalanceOfAnOwner(address _addressUser, address _addressOwner) public virtual override view returns (uint256){
        //TODO
    }
    
    function getInfoToken(uint256 _tokenId) public view returns ( address _BCA_OWNER,
                                                                    address _BCA_USER,
                                                                    address _BCA_SD,
                                                                    uint8   _state){
        _BCA_OWNER = ownerOfSD[_tokenId];
        _BCA_USER = Secure_Token[_tokenId].user;
        _BCA_SD = Secure_Token[_tokenId].SD;
        if(Secure_Token[_tokenId].state == States.waitingForOwner){
            _state = 0;
        }else if(Secure_Token[_tokenId].state == States.engagedWithOwner){
            _state = 1;
        }else if(Secure_Token[_tokenId].state == States.waitingForUser){
            _state = 2;
        }else {
            _state = 3;
        }
    }
    
    function getInfoTokenFromBCA(address _addressSD) public view returns ( address _BCA_OWNER,
                                                                    address _BCA_USER,
                                                                    uint256 _tokenId,
                                                                    uint8   _state){
        _tokenId = tokenIDOfBCA[_addressSD];
        _BCA_OWNER = ownerOfSD[_tokenId];
        _BCA_USER = Secure_Token[_tokenId].user;
        if(Secure_Token[_tokenId].state == States.waitingForOwner){
            _state = 0;
        }else if(Secure_Token[_tokenId].state == States.engagedWithOwner){
            _state = 1;
        }else if(Secure_Token[_tokenId].state == States.waitingForUser){
            _state = 2;
        }else {
            _state = 3;
        }
    }
    
    function balanceOf(address _owner) public virtual override view returns (uint256){
        return(ownerBalance[_owner]);
    }
    
    function ownerOf(uint256 _tokenId) public virtual override view returns (address){
        return(ownerOfSD[_tokenId]);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public virtual override payable{
        
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public virtual override payable{
        transferFrom(_from, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public virtual override payable{
        require((ownerOfSD[_tokenId] == msg.sender)||(Secure_Token[_tokenId].approved == msg.sender));
        require(ownerOfSD[_tokenId] == _from);
        if((Secure_Token[_tokenId].timestamp + Secure_Token[_tokenId].timeout) > block.timestamp){
            ownerOfSD[_tokenId] = _to;
            ownerBalance[_from]--;
            ownerBalance[_to]++;
            //Secure_Token[_tokenId].approved = address(0);
            Secure_Token[_tokenId].user = address(0);
            Secure_Token[_tokenId].state = States.waitingForOwner;
            //Erase old key exchange data between device with old Owner
            Secure_Token[_tokenId].dataEngagement = 0;
            Secure_Token[_tokenId].hashK_UD = 0;
            Secure_Token[_tokenId].hashK_OD = 0;
            emit Transfer(_from,_to,_tokenId);
        }else{
            Secure_Token[_tokenId].user = address(0);
            emit TimeoutAlarm(_tokenId);
        }
    }

    function approve(address _approved, uint256 _tokenId) public virtual override payable{
        
    }

    function setApprovalForAll(address _operator, bool _approved) public virtual override{
        
    }

    function getApproved(uint256 _tokenId) public virtual override view returns (address){
        
    }

    function isApprovedForAll(address _owner, address _operator) public virtual override view returns (bool){
        
    }
    
    function checkTimeout(uint256 _tokenId) public virtual override returns (bool){
        require(ownerOfSD[_tokenId] == msg.sender);
        if((Secure_Token[_tokenId].timestamp + Secure_Token[_tokenId].timeout) > block.timestamp){
            return true;
        }else{
            Secure_Token[_tokenId].user = address(0);
            emit TimeoutAlarm(_tokenId);
            return false;
        }
    }
    
    function updateTimestamp() public virtual override{
        Secure_Token[tokenFromBCA(msg.sender)].timestamp = block.timestamp;
    }
    
    function setTimeout(uint256 _tokenId, uint256 _timeout) public virtual override{
        require(ownerOfSD[_tokenId] == msg.sender);
        Secure_Token[_tokenId].timeout = _timeout;
    }
}
