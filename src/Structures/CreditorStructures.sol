// SPDX-License-Identifier: ISC

pragma solidity ^0.8.10;

interface CreditorStructures {
    struct Credit {
        uint256 loanId; // id of loan associated with
        uint256 trancheNumber;
        uint256 amountSupplied;
        uint256 amountClaimed;
    }

    struct CreditMintParams {
        uint256 loanId;
        uint256 trancheNumber;
        uint256 amountSupplied;
        address creditor;
    }
}
