// SPDX-License-Identifier: ISC

pragma solidity ^0.8.10;

interface MicroLoanEvents {
    event LoanRequested(
        uint256 indexed id,
        address indexed requestor,
        int256 indexed creditScore,
        uint256 timestamp,
        uint256 amount,
        uint256 rate
    );
    event LoanFulfilled(
        uint256 indexed id,
        uint256 time,
        address indexed borrower,
        uint256 amount
    );
    event LoanPaymentMade(
        uint256 indexed id,
        uint256 time,
        address indexed borrower,
        uint256 indexed amountPaid,
        uint256 outstandingLoanAmount
    );
    event LoanFullyPaid(
        uint256 indexed id,
        uint256 time,
        address indexed borrower,
        uint256 amountBorrowed,
        uint256 elapsedTime,
        int256 changeToCredit
    );
}
