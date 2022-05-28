// SPDX-License-Identifier: ISC

pragma solidity ^0.8.10;

import "./IERC721Credit.sol";
import "./Structures/CreditorStructures.sol";
import "./Structures/LoanStructures.sol";
import "./Structures/MicroLoanEvents.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract MicroLoanFactory is LoanStructures, MicroLoanEvents, Ownable {
    mapping(address => bool) whitelist;
    mapping(uint256 => Loan) public loans;
    mapping(uint256 => LoanRequest) public requestsById;
    mapping(address => uint256) public requestsByAddress;
    mapping(address => int256) public creditScores;
    uint256 interestRate = 10**9; // 10% interest rate
    address settlementToken;
    address creditToken;
    uint256 IDs;

    constructor(address token) Ownable() {
        settlementToken = token;
        IDs = 1;
    }

    modifier eligibleForLoan(address user) {
        require(whitelist[user], "Not eligible for loans");
        _;
    }

    modifier loanExists(uint256 id) {
        require(loans[id].start > 0, "Loan does not exist");
        _;
    }

    modifier requestExists(uint256 id) {
        require(requestsById[id].amount > 0, "Request does not exist");
        _;
    }

    function setCreditToken(address token) external onlyOwner {
        creditToken = token;
    }

    function getAmountOwed(uint256 id) public view returns (uint256) {
        if (loans[id].closed || loans[id].id == 0) {
            return 0;
        }
        Loan memory loan = loans[id];
        uint256 nPayments = loan.outstandingAmounts.length;
        OutstandingLoan memory currentBalance = loan.outstandingAmounts[
            nPayments
        ];

        return currentBalance.amount + calculateInterest(id);
    }

    function requestLoan(
        LoanPurpose purpose,
        uint256 amount,
        uint256 duration
    ) external eligibleForLoan(msg.sender) {
        LoanRequest storage request = requestsById[IDs];
        request.amount = amount;
        request.borrower = msg.sender;
        request.creditScore = creditScores[msg.sender];
        request.purpose = purpose;
        request.duration = duration;

        requestsByAddress[msg.sender] = IDs;
        emit LoanRequested(
            IDs,
            msg.sender,
            creditScores[msg.sender],
            block.timestamp,
            amount,
            interestRate
        );
        IDs++;
    }

    function _fulfillLoan(uint256 id)
        internal
        requestExists(id)
        eligibleForLoan(requestsById[id].borrower)
    {
        LoanRequest storage request = requestsById[id];
        require(
            loans[requestsByAddress[request.borrower]].start == 0 &&
                loans[id].start == 0,
            "User has an outstanding loan"
        );
        Loan storage loan = loans[id];
        loan.start = block.timestamp;
        loan.deadline = block.timestamp + request.duration;
        loan.id = id;
        loan.borrower = request.borrower;
        loan.interestRate = interestRate;
        loan.outstandingAmounts.push(
            OutstandingLoan({amount: request.amount, time: block.timestamp})
        );
        loan.tranches.push(
            Tranche({percent: PERCENT_DENOMINATOR, weight: PERCENT_DENOMINATOR})
        );
        loan.k = 2;
        loan.r = 1;
        loan.purpose = request.purpose;

        IERC20(settlementToken).transfer(request.borrower, request.amount);
        emit LoanFulfilled(
            id,
            block.timestamp,
            request.borrower,
            request.amount
        );
    }

    function contribute(
        uint256 id,
        uint256 tranche,
        uint256 amount
    ) external {
        LoanRequest storage request = requestsById[id];
        uint256 amountToFill = request.amount - request.amountFilled;
        uint256 fillAmount = amount > amountToFill ? amountToFill : amount;
        require(
            IERC20(settlementToken).transferFrom(
                msg.sender,
                address(this),
                fillAmount
            )
        );
        request.amountFilled -= fillAmount;
        if (request.amountFilled == request.amount) {
            _fulfillLoan(id);
        }
        IERC721Credit(creditToken).mint(
            CreditorStructures.CreditMintParams({
                loanId: id,
                trancheNumber: tranche,
                amountSupplied: fillAmount,
                creditor: msg.sender
            })
        );
    }

    function calculateInterest(uint256 id) internal view returns (uint256) {
        Loan memory loan = loans[id];
        uint256 nPayments = loan.outstandingAmounts.length;
        OutstandingLoan memory currentBalance = loan.outstandingAmounts[
            nPayments
        ];

        uint256 elapsedTime = block.timestamp - currentBalance.time;
        return
            (currentBalance.amount * loan.interestRate * elapsedTime) /
            PERCENT_DENOMINATOR;
    }

    function closeLoan(uint256 id) internal {
        Loan storage loan = loans[id];
        loan.closed = true;
        uint256 elapsedTime = block.timestamp - loan.start;
        int256 creditChange = int256(block.timestamp) - int256(loan.start);
        creditScores[loan.borrower] =
            creditScores[loan.borrower] +
            creditChange;
        emit LoanFullyPaid(
            id,
            block.timestamp,
            loan.borrower,
            loan.outstandingAmounts[0].amount,
            elapsedTime,
            creditChange
        );
    }

    function repayLoan(uint256 id, uint256 amount) external {
        Loan storage loan = loans[id];
        uint256 interestOwed = calculateInterest(id);
        OutstandingLoan memory outstanding = loan.outstandingAmounts[
            loan.outstandingAmounts.length - 1
        ];
        uint256 totalOwed = interestOwed + outstanding.amount;
        uint256 amountPaid = amount > totalOwed ? totalOwed : amount;
        loan.totalPaid += amountPaid;
        require(
            IERC20(settlementToken).transferFrom(
                loan.borrower,
                address(this),
                amountPaid
            )
        );

        OutstandingLoan memory newOutstanding = OutstandingLoan({
            amount: totalOwed - amountPaid,
            time: block.timestamp
        });
        loan.outstandingAmounts.push(newOutstanding);
        if (amountPaid == totalOwed) {
            closeLoan(id);
        }
        emit LoanPaymentMade(
            id,
            block.timestamp,
            loan.borrower,
            amountPaid,
            totalOwed - amountPaid
        );
    }

    function claimCredit(uint256 creditId) external returns (uint256) {
        (
            CreditorStructures.Credit memory credit,
            address owner
        ) = IERC721Credit(creditToken).getCreditInfo(creditId);
        Loan storage loan = loans[credit.loanId];
        require(msg.sender == owner);
        require(credit.amountClaimed == 0);
        uint256 entitledTo = (credit.amountSupplied * loan.totalPaid) /
            loan.outstandingAmounts[loan.outstandingAmounts.length - 1].amount;
        IERC721Credit(creditToken).setAmountClaimed(creditId, entitledTo);
        IERC20(settlementToken).transfer(owner, entitledTo);
        return entitledTo;
    }
}
