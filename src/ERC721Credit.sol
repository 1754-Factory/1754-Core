// SPDX-License-Identifier: ISC

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./Structures/CreditorStructures.sol";

contract ERC721Credit is ERC721, CreditorStructures {
    mapping(uint256 => Credit) creditData; // Maps tokenIds to credit structure
    address minter;
    uint256 linesOfCredit;

    constructor(address _minter) ERC721("Credit Receipts", "CRED") {
        minter = _minter;
        linesOfCredit = 0;
    }

    modifier only_minter() {
        require(msg.sender == minter, "Unauthorized");
        _;
    }

    function getCreditInfo(uint256 tokenId)
        external
        view
        returns (Credit memory credit, address owner)
    {
        require(_exists(tokenId), "Line of credit does not exist");
        credit = creditData[tokenId];
        owner = ownerOf(tokenId);
    }

    function setAmountClaimed(uint256 tokenId, uint256 amountClaimed)
        external
        only_minter
    {
        require(_exists(tokenId), "Line of credit does not exist");
        Credit storage credit = creditData[tokenId];
        credit.amountClaimed = amountClaimed;
    }

    function mint(CreditorStructures.CreditMintParams calldata params)
        external
        only_minter
        returns (uint256)
    {
        Credit storage credit = creditData[linesOfCredit];
        credit.amountSupplied = params.amountSupplied;
        credit.loanId = params.loanId;
        credit.trancheNumber = params.trancheNumber;
        _mint(params.creditor, linesOfCredit);
        return linesOfCredit++;
    }

    function burn(uint256 tokenId) external only_minter {
        _burn(tokenId);
    }
}
