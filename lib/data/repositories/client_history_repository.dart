import 'package:powersync/powersync.dart';
import '../models/personal_data.dart';
import '../models/loan.dart';
import '../models/client_history.dart';
import '../../core/config/app_config.dart';

/// Repository for client history data operations
class ClientHistoryRepository {
  final PowerSyncDatabase _db;

  ClientHistoryRepository(this._db);

  /// Search clients by name or client code
  Future<List<ClientSearchResult>> searchClients(String searchTerm) async {
    if (searchTerm.length < AppConfig.searchMinChars) {
      return [];
    }

    final term = '%$searchTerm%';

    // Search in PersonalData with related counts
    final results = await _db.execute('''
      SELECT
        pd.id,
        pd.fullName,
        pd.clientCode,
        (SELECT phone FROM Phone WHERE personalData = pd.id LIMIT 1) as phone,
        (SELECT COUNT(*) FROM Borrower b
         JOIN Loan l ON l.borrower = b.id
         WHERE b.personalData = pd.id) as totalLoans,
        (SELECT COUNT(*) FROM "_LoanCollaterals" lc
         WHERE lc.B = pd.id) as collateralLoans,
        (SELECT a.street FROM Address a WHERE a.personalData = pd.id LIMIT 1) as street,
        (SELECT loc.name FROM Address a
         JOIN Location loc ON a.location = loc.id
         WHERE a.personalData = pd.id LIMIT 1) as locationName
      FROM PersonalData pd
      WHERE pd.fullName LIKE ? OR pd.clientCode LIKE ?
      ORDER BY pd.fullName
      LIMIT ?
    ''', [term, term, AppConfig.searchMaxResults]);

    return results.map((row) {
      return ClientSearchResult(
        id: row['id'] as String,
        name: row['fullName'] as String? ?? '',
        clientCode: row['clientCode'] as String?,
        phone: row['phone'] as String?,
        address: row['street'] as String?,
        locationName: row['locationName'] as String?,
        totalLoans: (row['totalLoans'] as int?) ?? 0,
        collateralLoans: (row['collateralLoans'] as int?) ?? 0,
        hasLoans: ((row['totalLoans'] as int?) ?? 0) > 0,
        hasBeenCollateral: ((row['collateralLoans'] as int?) ?? 0) > 0,
      );
    }).toList();
  }

  /// Get complete client history by PersonalData ID
  Future<ClientHistory?> getClientHistory(String personalDataId) async {
    // Get personal data
    final personalDataRows = await _db.execute('''
      SELECT * FROM PersonalData WHERE id = ?
    ''', [personalDataId]);

    if (personalDataRows.isEmpty) {
      return null;
    }

    final pdRow = personalDataRows.first;

    // Get phones
    final phoneRows = await _db.execute('''
      SELECT phone FROM Phone WHERE personalData = ?
    ''', [personalDataId]);
    final phones = phoneRows.map((r) => r['phone'] as String).toList();

    // Get addresses with location info
    final addressRows = await _db.execute('''
      SELECT
        a.id,
        a.street,
        loc.name as locationName,
        mun.name as municipalityName,
        st.name as stateName,
        r.name as routeName
      FROM Address a
      LEFT JOIN Location loc ON a.location = loc.id
      LEFT JOIN Municipality mun ON loc.municipality = mun.id
      LEFT JOIN State st ON mun.state = st.id
      LEFT JOIN "_RouteEmployees" re ON re.A IN (
        SELECT e.id FROM Employee e WHERE e.personalData = a.personalData
      )
      LEFT JOIN Route r ON re.B = r.id
      WHERE a.personalData = ?
    ''', [personalDataId]);

    final addresses = addressRows.map((r) => AddressInfo.fromRow(r)).toList();

    final personalData = PersonalData.fromRow(
      pdRow,
      phones: phones,
      addresses: addresses,
    );

    // Get loans as client
    final loansAsClient = await _getLoansAsClient(personalDataId);

    // Get loans as collateral
    final loansAsCollateral = await _getLoansAsCollateral(personalDataId);

    // Calculate summary
    final summary = ClientSummary.fromLoans(
      loansAsClient: loansAsClient,
      loansAsCollateral: loansAsCollateral,
    );

    return ClientHistory(
      client: personalData,
      summary: summary,
      loansAsClient: loansAsClient,
      loansAsCollateral: loansAsCollateral,
    );
  }

  /// Get loans where the person is the borrower
  Future<List<Loan>> _getLoansAsClient(String personalDataId) async {
    final results = await _db.execute('''
      SELECT
        l.*,
        lt.weekDuration,
        lt.rate,
        pd.fullName as borrowerName,
        (SELECT pd2.fullName FROM Employee e
         JOIN PersonalData pd2 ON e.personalData = pd2.id
         WHERE e.id = l.lead) as leadName
      FROM Loan l
      JOIN Borrower b ON l.borrower = b.id
      JOIN PersonalData pd ON b.personalData = pd.id
      LEFT JOIN Loantype lt ON l.loantype = lt.id
      WHERE b.personalData = ?
      ORDER BY l.signDate DESC
    ''', [personalDataId]);

    final loans = <Loan>[];
    for (final row in results) {
      // Get collateral names for this loan
      final collateralRows = await _db.execute('''
        SELECT pd.fullName
        FROM "_LoanCollaterals" lc
        JOIN PersonalData pd ON lc.B = pd.id
        WHERE lc.A = ?
      ''', [row['id']]);
      final collateralNames =
          collateralRows.map((r) => r['fullName'] as String).toList();

      // Get payments for this loan
      final payments = await _getPaymentsForLoan(row['id'] as String);

      loans.add(Loan.fromRow(
        row,
        borrowerName: row['borrowerName'] as String?,
        leadName: row['leadName'] as String?,
        collateralNames: collateralNames,
        payments: payments,
        weekDuration: row['weekDuration'] as int?,
        rate: (row['rate'] as num?)?.toDouble(),
      ));
    }

    return loans;
  }

  /// Get loans where the person is a collateral/guarantor
  Future<List<Loan>> _getLoansAsCollateral(String personalDataId) async {
    final results = await _db.execute('''
      SELECT
        l.*,
        lt.weekDuration,
        lt.rate,
        pd.fullName as borrowerName,
        (SELECT pd2.fullName FROM Employee e
         JOIN PersonalData pd2 ON e.personalData = pd2.id
         WHERE e.id = l.lead) as leadName
      FROM Loan l
      JOIN "_LoanCollaterals" lc ON lc.A = l.id
      JOIN Borrower b ON l.borrower = b.id
      JOIN PersonalData pd ON b.personalData = pd.id
      LEFT JOIN Loantype lt ON l.loantype = lt.id
      WHERE lc.B = ?
      ORDER BY l.signDate DESC
    ''', [personalDataId]);

    final loans = <Loan>[];
    for (final row in results) {
      final payments = await _getPaymentsForLoan(row['id'] as String);

      loans.add(Loan.fromRow(
        row,
        borrowerName: row['borrowerName'] as String?,
        leadName: row['leadName'] as String?,
        payments: payments,
        weekDuration: row['weekDuration'] as int?,
        rate: (row['rate'] as num?)?.toDouble(),
      ));
    }

    return loans;
  }

  /// Get payments for a specific loan
  Future<List<LoanPayment>> _getPaymentsForLoan(String loanId) async {
    final results = await _db.execute('''
      SELECT * FROM LoanPayment
      WHERE loan = ?
      ORDER BY receivedAt ASC
    ''', [loanId]);

    return results.map((r) => LoanPayment.fromRow(r)).toList();
  }

  /// Get loan details by ID
  Future<Loan?> getLoanDetails(String loanId) async {
    final results = await _db.execute('''
      SELECT
        l.*,
        lt.weekDuration,
        lt.rate,
        pd.fullName as borrowerName,
        (SELECT pd2.fullName FROM Employee e
         JOIN PersonalData pd2 ON e.personalData = pd2.id
         WHERE e.id = l.lead) as leadName
      FROM Loan l
      JOIN Borrower b ON l.borrower = b.id
      JOIN PersonalData pd ON b.personalData = pd.id
      LEFT JOIN Loantype lt ON l.loantype = lt.id
      WHERE l.id = ?
    ''', [loanId]);

    if (results.isEmpty) return null;

    final row = results.first;

    // Get collateral names
    final collateralRows = await _db.execute('''
      SELECT pd.fullName
      FROM "_LoanCollaterals" lc
      JOIN PersonalData pd ON lc.B = pd.id
      WHERE lc.A = ?
    ''', [loanId]);
    final collateralNames =
        collateralRows.map((r) => r['fullName'] as String).toList();

    // Get payments
    final payments = await _getPaymentsForLoan(loanId);

    return Loan.fromRow(
      row,
      borrowerName: row['borrowerName'] as String?,
      leadName: row['leadName'] as String?,
      collateralNames: collateralNames,
      payments: payments,
      weekDuration: row['weekDuration'] as int?,
      rate: (row['rate'] as num?)?.toDouble(),
    );
  }
}
