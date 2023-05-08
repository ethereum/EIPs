// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "src/MyToken/MyToken.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MyToken712ParserHelper {
    string sigMessage =
        "This is MyToken transferWithSig message, by signing this message you are authorizing the transfer of MyToken from your account to the recipient account.";

    struct Transfer {
        address from;
        address to;
        uint256 amount;
        uint256 nonce;
        uint256 deadline;
    }

    function parseSig(bytes memory signature) public view returns (string[] memory sigTranslatedMessage) {
        Transfer memory transfer = abi.decode(signature, (Transfer));
        sigTranslatedMessage = new string[](3);
        sigTranslatedMessage[0] = sigMessage;
        sigTranslatedMessage[1] = Strings.toString(transfer.deadline);
        sigTranslatedMessage[2] = string(
            abi.encodePacked(
                "By signing this message you allow ",
                Strings.toHexString(transfer.to),
                " to transfer ",
                Strings.toString(transfer.amount),
                " of MyToken from your account."
            )
        );
        return sigTranslatedMessage;
    }
}
