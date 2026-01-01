import 'package:powersync/powersync.dart';

/// PowerSync Schema - Mirrors the PostgreSQL/Prisma schema
/// Tables synced from the backend database
const schema = Schema([
  // User table
  Table('User', [
    Column.text('email'),
    Column.text('password'),
    Column.text('role'),
    Column.text('createdAt'),
  ]),

  // PersonalData table - Core entity for clients and employees
  Table('PersonalData', [
    Column.text('fullName'),
    Column.text('clientCode'),
    Column.text('birthDate'),
    Column.text('createdAt'),
    Column.text('updatedAt'),
  ]),

  // Phone table - Multiple phones per PersonalData
  Table('Phone', [
    Column.text('personalData'), // FK to PersonalData.id
    Column.text('phone'),
  ]),

  // Address table - Multiple addresses per PersonalData
  Table('Address', [
    Column.text('personalData'), // FK to PersonalData.id
    Column.text('street'),
    Column.text('location'), // FK to Location.id
    Column.text('createdAt'),
  ]),

  // Location table - For address lookup
  Table('Location', [
    Column.text('name'),
    Column.text('municipality'), // FK to Municipality.id
  ]),

  // Municipality table - For location lookup
  Table('Municipality', [
    Column.text('name'),
    Column.text('state'), // FK to State.id
  ]),

  // State table - For municipality lookup
  Table('State', [
    Column.text('name'),
  ]),

  // Borrower table - Links PersonalData to Loans
  Table('Borrower', [
    Column.text('personalData'), // FK to PersonalData.id (unique)
    Column.integer('loanFinishedCount'),
    Column.text('createdAt'),
    Column.text('updatedAt'),
  ]),

  // Loan table - Main loan entity
  Table('Loan', [
    Column.text('oldId'),
    Column.real('requestedAmount'),
    Column.real('amountGived'),
    Column.text('signDate'),
    Column.text('finishedDate'),
    Column.text('renewedDate'),
    Column.text('badDebtDate'),
    Column.integer('isDeceased'),
    Column.real('profitAmount'),
    Column.real('totalDebtAcquired'),
    Column.real('expectedWeeklyPayment'),
    Column.real('totalPaid'),
    Column.real('pendingAmountStored'),
    Column.real('comissionAmount'),
    Column.text('status'), // ACTIVE, FINISHED, RENOVATED, CANCELLED
    Column.text('borrower'), // FK to Borrower.id
    Column.text('loantype'), // FK to Loantype.id
    Column.text('grantor'), // FK to Employee.id (optional)
    Column.text('lead'), // FK to Employee.id (optional)
    Column.text('snapshotLeadId'),
    Column.text('snapshotLeadAssignedAt'),
    Column.text('snapshotRouteId'),
    Column.text('snapshotRouteName'),
    Column.text('previousLoan'), // FK to Loan.id (optional)
    Column.text('excludedByCleanup'),
    Column.text('createdAt'),
    Column.text('updatedAt'),
  ], indexes: [
    Index('idx_loan_borrower', [IndexedColumn('borrower')]),
    Index('idx_loan_status', [IndexedColumn('status')]),
    Index('idx_loan_signDate', [IndexedColumn('signDate')]),
  ]),

  // Loantype table - Loan configuration
  Table('Loantype', [
    Column.text('name'),
    Column.integer('weekDuration'),
    Column.real('rate'),
    Column.real('initialComissionRate'),
    Column.real('renewComissionRate'),
  ]),

  // LoanCollaterals - Many-to-many relationship (Loan <-> PersonalData as collateral)
  Table('_LoanCollaterals', [
    Column.text('A'), // Loan.id
    Column.text('B'), // PersonalData.id
  ], indexes: [
    Index('idx_loan_collaterals_loan', [IndexedColumn('A')]),
    Index('idx_loan_collaterals_personal', [IndexedColumn('B')]),
  ]),

  // Employee table - For lead/grantor lookup
  Table('Employee', [
    Column.text('oldId'),
    Column.text('type'), // ROUTE_LEAD, AGENT, etc.
    Column.text('personalData'), // FK to PersonalData.id
    Column.text('user'), // FK to User.id (optional)
    Column.text('createdAt'),
    Column.text('updatedAt'),
  ]),

  // Route table - For route lookup
  Table('Route', [
    Column.text('name'),
    Column.text('createdAt'),
  ]),

  // RouteEmployees - Many-to-many relationship
  Table('_RouteEmployees', [
    Column.text('A'), // Employee.id
    Column.text('B'), // Route.id
  ]),

  // AccountEntry table - Financial ledger entries (can be 200K+ records)
  Table('AccountEntry', [
    Column.text('accountId'),
    Column.real('amount'),
    Column.text('entryType'), // DEBIT, CREDIT
    Column.text('sourceType'), // LOAN_GRANT, LOAN_PAYMENT_CASH, etc.
    Column.real('profitAmount'),
    Column.real('returnToCapital'),
    Column.text('snapshotLeadId'),
    Column.text('snapshotRouteId'),
    Column.text('entryDate'),
    Column.text('description'),
    Column.text('loanId'), // FK to Loan.id (optional)
    Column.text('loanPaymentId'),
    Column.text('leadPaymentReceivedId'),
    Column.text('destinationAccountId'),
    Column.text('syncId'),
    Column.text('createdAt'),
  ], indexes: [
    Index('idx_account_entry_loan', [IndexedColumn('loanId')]),
    Index('idx_account_entry_date', [IndexedColumn('entryDate')]),
    Index('idx_account_entry_source', [IndexedColumn('sourceType')]),
  ]),

  // LoanPayment table - Individual payments on a loan
  Table('LoanPayment', [
    Column.real('amount'),
    Column.text('type'), // NORMAL, EXTRA
    Column.text('paymentMethod'), // CASH, MONEY_TRANSFER
    Column.text('receivedAt'),
    Column.text('loan'), // FK to Loan.id
    Column.text('createdAt'),
  ], indexes: [
    Index('idx_loan_payment_loan', [IndexedColumn('loan')]),
    Index('idx_loan_payment_date', [IndexedColumn('receivedAt')]),
  ]),
]);
