---
title: NFT-Bound Modularized Contract
author: MJ <tsngmj@gmail.com>
discussions-to: <URL>
status: Draft
type: Standards Track
category: ERC
created: 2023-09-06
requires: 165, 1155
---

## Abstract

This proposal introduces a new type of NFT called SmartNFT. Unlike traditional static NFTs that lack real-world functionality, SmartNFTs can be customized with specific functions to give them practical uses. Moreover, by combining different SmartNFTs, users can enhance their interactions on the blockchain and streamline project development processes.

## Motivation

The purpose of this protocol is to address the following challenges present within the Web3 ecosystem:

1. When it comes to regular users, using third-party bots or tools to simplify operations brings security risks like the potential exposure of private keys.
2. For individual developers, the process of turning functionalities into market-ready products is hindered by a lack of sufficient resources for this transition and generating profits.
3. In the context of a "Code is Law" philosophy, there is an inadequate infrastructure for effectively transacting assets like code/smart-contract in the market.

- **Streamline Operation while Ensuring Security**

  In the current blockchain environment, accomplishing more complex tasks is often unfriendly for ordinary users. This stems from two main factors.

  ![](../assets/eip-NFT_Bound_Modularized_Contract/streamline_operation.png)

  Firstly, average users lack the coding proficiency required for intricate operations. Advanced/complexed functionalities realized through smart contracts, such as flash loans or conditional orders, appear to be the realm of developers, scientists, or hackers, making them seem like privileges.

  Secondly, if ordinary users opt for third-party bots or tools, they face the challenge of placing trust in these third parties, which brings about the constant risk of account compromise.

- **Treat SmartNFTs as Innovative Products**

  In recent years, NFT-related projects, both in terms of applications and infrastructure, have undergone multiple rounds of iteration. Significant breakthroughs have been achieved in the realm of static assets. Artistic endeavors, for instance, have made significant strides, with numerous successful NFT marketplace platforms providing creators to turn their creations into revenue.

  However, in real-world scenarios, many assets derive their value from their functional utility, such as cars and smartphones. Their value extends beyond branding and encompasses factors like proper functioning and user experience quality.

  Within the context of Web3, code/contracts themselves are creations by developers, imbued with functionality. However, at present, there isn't an effective marketplace that allows these creators to monetize their creations, nor is there a unified standard to govern this particular category of creations.

- **Modularization of Functional Components**

  For project development teams, there are often two recurring challenges. The first is the redundancy of developing functionalities that already exist on the blockchain, while the second pertains to the constant need for protocol upgrades due to evolving market demands. Both of these issues stem from the lack of a unified approach to functional modularization, resulting in duplicated efforts and an inability to add or remove functionalities without altering the primary protocol contract.

  Take GameFi, for example. As games become more intricate, the expansion of gameplay becomes inevitable. In traditional scenarios, this expansion might be achieved through patches. However, in the current blockchain landscape, this kind of technology isn't yet widely available.

## Specification

The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “NOT RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119 and RFC 8174.

- **Overview**

  This protocol establishes standardized implementation and invocation interfaces for SmartNFTs. It builds upon the [ERC-1155](./eip-1155) standard by introducing a universal extension, transforming [ERC-1155](./eip-1155) into a vessel for smart contract. Moreover, the protocol defines registration and verification interfaces for SmartNFTs.

  Additionally, it provides insights into advanced usage scenarios. For instance, users can independently arrange and combine trusted SmartNFTs to achieve more complex operations. Furthermore, it provides a novel solution for contract upgrades without altering the existing contracts.

  ![](../assets/eip-NFT_Bound_Modularized_Contract/architecture.png)

- **SmartNFT Interface**

  In order to simplify collaboration among developers, it is essential to establish a unified standard for modularizing SmartNFTs. A standardized and singular interface design for SmartNFTs has becomes a must. Thus, the interface is defined as follows:

  - `execute`: This function **MUST** includes only one parameter of type `bytes`, which encapsulates the necessary parameters for the specific SmartNFT. The SmartNFT's implementation **SHOULD** then decode these parameters back to their original information.
  - `validatePermission`: This function is used to query the SmartManager to determine whether the SmartNFT has been successfully verified and is callable. It **MUST** be executed in the execute function to determine whether the subsequent execution is permitted.
  - `creator`: Return value **MUST** be the developer's address or the payment address, which is used for future revenue collection.

    </br>

  ```solidity
  interface ISmartNFT {
      /**
       * @dev Proxy call `execute` function by delegateCall
       *
       * SmartNFT MUST implement a `execute` function
       *
       * @param data           The data required by the execute function
       * @return returndata    The return value of the function
       */
      function execute(bytes memory data) external payable returns(bytes memory returndata);

      /**
       * @dev Validate that the caller has permission to call `execute` function
       *
       * SmartNFT MUST implement a `validatePermission` function
       *
       * SmartNFT can query whether caller has permission by call `isAccessForUser` of the SmartManager
       *
       * @param manager        The address of the smartManager contract
       * @param addr           The address of the smartNFT contract
       * @return ret           True or False
       */
      function validatePermission(address manager, address addr) external view returns(bool ret);

      /**
       * @dev Return the author of the contract
       *
       *
       * @return author           The author of contract
       */
      function creator() external view returns(address author);
  }
  ```

- **SmartManager Interface**

  Under this protocol definition, where owning a SmartNFT equates to possessing functional value, striking a balance between maximizing SmartNFT reusability and managing usage rights, the [ERC-1155](./eip-1155) protocol is adopted as the vessel for SmartNFTs. Additionally, extensions are introduced to the [ERC-1155](./eip-1155) protocol to create a SmartManager, encompassing functionalities like SmartNFT registration and verification. The interface definitions are as follows:

  - `register`: This function facilitates the registration of a SmartNFT into the SmartManager. At this point, the SmartNFT **SHOULD** ideally be marked as uncertain.
  - `verificationStatus`: The function **MUST** returns the current verification stage of the specified SmartNFT. The verification process is divided into three stages: UNCERTAIN, VERIFIED, and MALICIOUS.
  - `setSmartNFTVerificationStatus`: Trusted validators can use this interface to provide proof of trust or distrust for compliant and secure SmartNFTs.
  - `isAccessForUser`: This interface is used to ascertain whether a user can use a specific SmartNFT. The determination **MUST** involves considering both the ownership of the corresponding tokenId NFT and whether the SmartNFT has been successfully verified.

    </br>

  ```solidity
  interface ISmartManager {

  		enum VerificationStage{
  			UNCERTAIN,
  			VERIFIED,
  			MALICIOUS
  		}

      /**
       * @dev SmartNFT contract apply to join the smartManager
       *
       * SmartManager MUST implement a `register` function
       *
       * @param _addr           The contract address of the SmartNFT
       */
      function register(address _addr) external ;

      /**
      * @dev Verify smartNFT whether it's valid
       *
       * SmartManager MUST implement a `verificationStatus` function
       *
       * After SmartNFT registers with the SmartManager, it's contract need to be audited to confirm the validity
       *
       * @param _addr           The smartNFT contract address
       * @return isValidate     The validity of smartNFT contract
       */
      function verificationStatus(address _addr) external view returns(VerificationStage isValidate);

      /**
      * @dev Set smartNFT verification status
       *
       * SmartManager MUST implement a `setSmartNFTVerificationStatus` function
       *
       * @param _addr           The smartNFT contract address
       * @param _status         The validity of smartNFT contract
       */
      function setSmartNFTVerificationStatus(address _addr, VerificationStage _status) external ;

      /**
      * @dev Provide a interface to the SmartNFT for query caller's permission
       *
       * SmartManager MUST implement a `isAccessForUser` function
       *
       * SmartManager can set the rule that Proxy access the SmartNFT by delegateCall
       *
       * @param _addr           The address of the caller
       * @param _contractAddr   The contract address of the smartNFT
       * @return isAccess       The validity of the smartNFT contract
       */
      function isAccessForUser(address _addr, address _contractAddr) external view returns(bool isAccess);
  }
  ```

- **Register SmartNFT**

  For the generation and successful registration of a SmartNFT, the developer **SHOULD** first deploy a logic contract that adheres to the interface design. Following that, a transaction **MUST** be initiated towards the SmartManager to perform the "register" action, binding the logic contract from the previous step with the [ERC-1155](./eip-1155) TokenID.

  During this binding process, the developer's address is **RECOMMENDED** being recorded. As this address cannot be directly obtained from the logic contract's deployer, it is uniformly acquired from the SmartNFT's "creator" function. Upon completing the entire process, an unverified SmartNFT is successfully registered.

- **Verify SmartNFT**

  Security verification for on-chain contracts inherently involves a human component. Currently, blockchain projects often enlist professional contract auditing teams to assess potential vulnerabilities within a contract. Audit reports are then generated within human-defined reasonable limits to ensure the security of project contracts. Similarly, the security evaluation of SmartNFTs also necessitates the presence of validators.

  To enhance verification credibility, a multi-validator consensus approach is **RECOMMENDED** could be adopted, where SmartNFTs **MUST** gain approval from a majority of validators to be deemed compliant and safe. To manage SmartNFTs, at least three stages can be provided:

  - Verified: This stage indicates that the implementation has passed verification and can be executed safely.
  - Uncertain: This stage indicates that the verification progress cannot determine whether it's qualified or malicious at the moment. **SHOULD NOT** being used by any one.
  - Malicious: This stage indicates that the implementation has security issues. **MUST NOT** being used by any one.

## Rationale

- **Standardized SmartNFT interface**

  This protocol defines that SmartNFTs have only one general external interface. While this design may restrict the potential for smart contracts to possess various functional interfaces, it also offers several advantages. For recent development, such stringent constraints assist developers in compliance and enhance efficiency in parallel collaboration efforts. Additionally, the unified `execute` interface eliminates the need for proxy callers to know the specific selector of the interface they want to use.

  Although having just one interface, within the design philosophy of this protocol, the goal is for each SmartNFT to function akin to LEGO blocks. Not every SmartNFT needs to possess comprehensive functionality, but they can be creatively combined to achieve limitless possibilities.

- **Decentralized Verification**

  The verification interface doesn't impose restrictions on implementation methods. If you intend to avoid concentrating verification authority in the hands of a few, you can incorporate a DAO (Decentralized Autonomous Organization) and implement a public voting mechanism. This approach can achieve a decentralized verification process through transparent community participation and decision-making.

- **Without Factory**

  Since the Factory itself cannot verify whether the SmartNFT being deployed adheres to the recommended interface restrictions of the protocol, and with a commitment to maximizing code reusability, we aim for any SmartNFT to be registrable on different SmartNFTManagers. Therefore, the presence or absence of a Factory is not a crucial issue in this context.

## Backwards Compatibility

This proposal aims to ensure the highest possible compatibility with the existing [ERC-1155](./eip-1155) protocol. All functionalities present in [ERC-1155](./eip-1155), including ERC165 detection and SmartNFT support, are retained. This encompasses compatibility with current NFT trading platforms.

For all SmartNFTs, the EIP standard only mandates the provision of the `execute` function. This means that existing proxy contracts need to focus solely on this interface, making integration of SmartNFTs more straightforward and streamlined.

## Security Considerations

- **Malicious Validator**

  All activities involving human intervention inherently carry the risk of malicious behavior. In this protocol, during the verification phase of SmartNFTs, external validators provide guarantees. However, this structure raises concerns about the possibility of malicious validators intentionally endorsing Malicious SmartNFTs. To mitigate this risk, it's necessary to implement stricter validation mechanisms, filtering of validators, punitive measures, or even more stringent consensus standards.

- **Unexpected Verification Error**

  Apart from the issue of Malicious Validators, there's the possibility of missed detection during the verification phase due to factors like overly complex SmartNFT implementations or vulnerabilities in the Solidity compiler. This protocol addresses such scenarios with designed interfaces for appropriate handling, but its effectiveness relies on the responsiveness and vigilance of Validators.

- **Improper SmartNFT Implementation**

  This protocol defines that when a SmartNFT executes `execute`, it should first trigger `validatePermission` to query the SmartManager's `isAccessForUser` interface, determining whether the user can use the SmartNFT. However, potential implementation errors by developers could lead to several issues:

  - Users who possess the SmartNFT might not be able to execute its functionalities properly.
  - Users who don't possess the SmartNFT might be able to execute its functionalities improperly.
  - Unverified SmartNFTs could be used by users to execute their functionalities improperly.

## Reference Implementation

- **Code**

  - **The interface of SmartNFT and SmartManager**

    ```solidity
    interface ISmartNFT {
        /**
         * @dev Proxy call `execute` function by delegateCall
         *
         * SmartNFT MUST implement a `execute` function
         *
         * @param data           The data required by the execute function
         * @return returndata    The return value of the function
         */
        function execute(bytes memory data) external payable returns(bytes memory returndata);

        /**
         * @dev Validate that the caller has permission to call `execute` function
         *
         * SmartNFT MUST implement a `validatePermission` function
         *
         * SmartNFT can query whether caller has permission by call `isAccessForUser` of the SmartManager
         *
         * @param manager        The address of the smartManager contract
         * @param addr           The address of the smartNFT contract
         * @return ret           True or False
         */
        function validatePermission(address manager, address addr) external view returns(bool ret);

        /**
         * @dev Return the author of the contract
         *
         *
         * @return author           The author of contract
         */
        function creator() external view returns(address author);
    }

    interface ISmartManager {

    		// SmartNFT verification stage
    		enum VerificationStage{
    			UNCERTAIN,                         //Status after the time of application
    			VERIFIED,                          //Status after the manager approves
    			MALICIOUS                          //Status when SmartNFT contract has bug
    		}

        /**
         * @dev SmartNFT contract apply to join the smartManager
         *
         * SmartManager MUST implement a `register` function
         *
         * @param _addr           The contract address of the SmartNFT
         */
        function register(address _addr) external ;

        /**
        * @dev Verify smartNFT whether it's valid
         *
         * SmartManager MUST implement a `verificationStatus` function
         *
         * After SmartNFT registers with the SmartManager, it's contract need to be audited to confirm the validity
         *
         * @param _addr           The smartNFT contract address
         * @return isValidate     The validity of smartNFT contract
         */
        function verificationStatus(address _addr) external view returns(VerificationStage isValidate);

        /**
        * @dev Set smartNFT verification status
         *
         * SmartManager MUST implement a `setSmartNFTVerificationStatus` function
         *
         * @param _addr           The smartNFT contract address
         * @param _status         The validity of smartNFT contract
         */
        function setSmartNFTVerificationStatus(address _addr, VerificationStage _status) external ;

        /**
        * @dev Provide a interface to the SmartNFT for query caller's permission
         *
         * SmartManager MUST implement a `isAccessForUser` function
         *
         * SmartManager can set the rule that Proxy access the SmartNFT by delegateCall
         *
         * @param _addr           The address of the caller
         * @param _contractAddr   The contract address of the smartNFT
         * @return isAccess       The validity of the smartNFT contract
         */
        function isAccessForUser(address _addr, address _contractAddr) external view returns(bool isAccess);
    }
    ```

  - **ERC20Transfer SmartNFT**

    ```solidity
    // ERC20 smartNFT, used for `transfer`
    contract ERC20Transfer is ISmartNFT  {

        address immutable _author;

        constructor() {
            _author = msg.sender;
        }

        function execute(bytes memory data) external payable returns(bytes memory returndata) {
            address manager;
            address contractAddr;
            address tokenAddr;
            address toAddr;
            uint256 amount;

            (manager, contractAddr, tokenAddr, toAddr, amount) = abi.decode(data, (address, address, address, address, uint256));
            require(validatePermission(manager, msg.sender), "invalid permission");
            bool success = IERC20(tokenAddr).transfer(toAddr, amount);
            returndata = abi.encodePacked(success);
        }

        function validatePermission(address manager, address contractAddr) public view returns(bool) {
            return ISmartManager(manager).isAccessForUser(msg.sender, contractAddr);
        }

        function creator() external view returns(address author) {
            return _author;
        }
    }
    ```

  - **ERC20Approve SmartNFT**

    ```solidity
    //ERC20 SmartNFT, used for `approve`
    contract ERC20Approve is ISmartNFT  {

        address immutable _author;

        constructor() {
            _author = msg.sender;
        }

        function execute(bytes memory data) external payable returns(bytes memory returndata) {
            address manager;
            address contractAddr;
            address tokenAddr;
            address toAddr;
            uint256 amount;

            (manager, contractAddr, tokenAddr, toAddr, amount) = abi.decode(data, (address, address, address, address, uint256));
            require(validatePermission(manager, msg.sender), "invalid permission");
            bool success = IERC20(tokenAddr).approve(toAddr, amount);
            returndata = abi.encodePacked(success);
        }

        function validatePermission(address manager, address contractAddr) public view returns(bool) {
            return ISmartManager(manager).isAccessForUser(msg.sender, contractAddr);
        }

        function creator() external view returns(address author) {
            return _author;
        }
    }
    ```

  - **SmartManager**

    ```solidity
    //DAO contract, used for audit `smartNFT contract`
    contract Proposal is Ownable {

        //The record of smartNFT's validity
        mapping(address => ISmartManager.VerificationStage) internal _proposalStatus;

        modifier onlyProposal(address addr) {
            require(owner() == addr, "IS OWNER");
            _;
        }
    }


    // SmartManager contract, used for manage smartNFT contract
    contract SmartManager is ISmartManager, ERC1155(""), Proposal {

        // Record ERC1155 token id
        uint256 _id;

        // Record relation between `contract address` and `erc1155 token id`
        mapping(address => uint256) public contractAddr2Id;
        mapping(uint256 => address) public id2contractAddr;

        modifier onlyOwnerOfId(uint256 id, address addr) {
            require(contractAddr2Id[addr] == id, "NOT INVALID");
            _;
        }

        function register(address _addr) external onlyProposal(msg.sender) {
            require(contractAddr2Id[_addr] == 0, "ALREADY REGISTERED");
            contractAddr2Id[_addr] = _id;
            id2contractAddr[_id] = _addr;
            _id += 1;
        }

        /**
        * @dev Allows the account to receive Ether
         *
         * Mint ERC1155 to user - it must be the owner of smartNFT call
         *
         * @param to              The address of user
         * @param id              The id of smartNFT contract address
         * @param value           The amount of erc1155 token
         */
        function mint(address to, uint256 id, uint256 value) external onlyOwnerOfId(id, msg.sender) {
            require(verificationStatus(id2contractAddr[id]) == VerificationStage.VERIFIED, "invalid id");
            _mint(to, id, value, "");
        }

        function verificationStatus(address _addr) public view returns(VerificationStage) {
            return _proposalStatus[_addr];
        }

        function setSmartNFTVerificationStatus(address _addr, VerificationStage _status) external onlyProposal(msg.sender) {
            _proposalStatus[_addr] = _status;
        }

        function isAccessForUser(address _addr, address _contractAddr) external view returns(bool isAccess) {
            require(balanceOf(_addr, contractAddr2Id[_contractAddr]) > 0, "No Access");
            return true;
        }

        function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
            return
            interfaceId == type(ISmartManager).interfaceId ||
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
        }
    }
    ```

  - **Composable method**

    The following describes a SmartNFT combination method, which realizes the batch execution of SmartNFT logic through proxy.

    ```solidity
    contract Wallet is Ownable, Proxy {

    address _impl;

    function _implementation() internal view override returns (address) {
            return _impl;
        }

        function batachExecute(address[] memory addr, bytes[] memory data) external {
            uint256 length = addr.length;
            for (uint256 i = 0; i < length; i++) {
                addr[i].delegatecall(data[i]);
            }
        }

        function setImpl(address addr) external {
            _impl = addr;
        }
    }
    ```

- **Application**

  - **SmartNFT for GameFi**

    In game-fi, mods are often one of the reasons for a game's popularity. Users can create their own mods to enhance the game's entertainment value. For example, in games like "The Elder Scrolls V: Skyrim," players can develop mods that add new elements and enhance the overall gameplay experience.

    Developers can create mods as SmartNFTs within blockchain games and sell them as [ERC-1155](./eip-1155) tokens, thereby generating revenue. This approach allows developers to monetize their creativity and contributions to the gaming ecosystem, while players benefit from enhanced gaming experiences through these unique and customizable modifications.

  - **SmartNFT for Customizable Interactions**

    ![](../assets/eip-NFT_Bound_Modularized_Contract/interoperation.png)

    The diagram illustrates the suboptimal user experience when interacting with multiple DEFI protocols compared to the ideal interaction. With the thriving blockchain ecosystem, including blockchain games and social applications, a mix of existing and new protocols has led to intricate and complex interactions. When users must perform multiple actions to complete a transaction, it results in inefficiency for the user.

    To address this issue, we propose Customizable Link Interactions, allowing users to streamline multiple interactions into a single one. For instance, numerous DEFI protocols involving actions like approval, deposit, and borrowing could be simplified into a single action, like a "signAll," akin to using a shortcut.

  - **Advanced Usage - Combination SmartNFT**

    Because SmartNFTs are fundamentally smart contracts, these smart contracts can also possess other NFTs, which subsequently allows SmartNFTs to own other SmartNFTs. This characteristic enables the realization of compositional SmartNFT applications. For instance, SmartNFT A might implement an ERC20 token approval, while SmartNFT B facilitates a Swap operation with a DEX. If a SmartNFT C possesses both SmartNFT A and SmartNFT B, then SmartNFT C can sequentially invoke SmartNFT A and SmartNFT B to effectively accomplish the functionality of approving before executing a swap.

    ![](../assets/eip-NFT_Bound_Modularized_Contract/combination_nft.png)

    Another scenario for compositional use is when a single Proxy holds multiple SmartNFTs. The Proxy can then selectively invoke SmartNFTs in the desired sequence according to its requirements. This approach can achieve the same effect as the example mentioned earlier.

    ![](../assets/eip-NFT_Bound_Modularized_Contract/proxy_hold_nft.png)

  - **Advanced Usage - Modularization of DAPP Functionality**

    As mentioned earlier, the design of this protocol aims to make SmartNFTs modular, with each SmartNFT corresponding to a specific functionality, effectively modularizing functionalities. Applying this feature to DAPP implementation allows for the creation of complete DAPP instances by possessing SmartNFTs with the corresponding required functionalities.

    Taking a DEX (Decentralized Exchange) as an example, if there's a need to add or remove liquidity and perform swaps, you'd only need SmartNFTs that provide functionalities like adding liquidity, removing liquidity, and swapping.

    This design also proves advantageous for future upgrades. If upgrades are required for certain interfaces, you would only need to acquire new SmartNFTs and remove the old ones, simplifying the upgrade process.

## Copyright

Copyright and related rights waived via [CC0](../LICENSE.md).