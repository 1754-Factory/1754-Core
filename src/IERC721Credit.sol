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

interface IERC721Credit is IERC721, CreditorStructures {
    function getCreditInfo(uint256 tokenId)
        external
        view
        returns (Credit memory credit, address owner);

    function mint(CreditorStructures.CreditMintParams calldata params)
        external
        returns (uint256);

    function burn(uint256 tokenId) external;

    function setAmountClaimed(uint256 tokenId, uint256 amountClaimed) external;
}
