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
  /// [isAdmin] - If false, excludes PersonalData of employees with user accounts
  Future<List<ClientSearchResult>> searchClients(String searchTerm, {bool isAdmin = false}) async {
    if (searchTerm.length < AppConfig.searchMinChars) {
      return [];
    }

    final term = '%$searchTerm%';

    // Security filter: Non-admin users cannot see PersonalData of people with User accounts
    // This matches the API's isAdmin filtering logic
    final securityFilter = isAdmin
        ? ''
        : '''
          AND NOT EXISTS (
            SELECT 1 FROM Employee e
            JOIN User u ON u.employee = e.id
            WHERE e.personalData = pd.id
          )
        ''';

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
         WHERE a.personalData = pd.id LIMIT 1) as locationName,
        (SELECT r.name FROM Address a
         JOIN Location loc ON a.location = loc.id
         JOIN Route r ON loc.route = r.id
         WHERE a.personalData = pd.id LIMIT 1) as routeName
      FROM PersonalData pd
      WHERE (pd.fullName LIKE ? OR pd.clientCode LIKE ?)
      $securityFilter
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
        routeName: row['routeName'] as String?,
        totalLoans: (row['totalLoans'] as int?) ?? 0,
        collateralLoans: (row['collateralLoans'] as int?) ?? 0,
        hasLoans: ((row['totalLoans'] as int?) ?? 0) > 0,
        hasBeenCollateral: ((row['collateralLoans'] as int?) ?? 0) > 0,
      );
    }).toList();
  }

  /// Get complete client history by PersonalData ID
  /// [isAdmin] - If false, blocks access to PersonalData of employees with user accounts
  Future<ClientHistory?> getClientHistory(String personalDataId, {bool isAdmin = false}) async {
    print('[ClientHistory] Loading history for: $personalDataId (isAdmin: $isAdmin)');

    // Security check: Non-admin users cannot view PersonalData of people with User accounts
    if (!isAdmin) {
      final hasUserAccount = await _db.execute('''
        SELECT 1 FROM Employee e
        JOIN User u ON u.employee = e.id
        WHERE e.personalData = ?
        LIMIT 1
      ''', [personalDataId]);

      if (hasUserAccount.isNotEmpty) {
        print('[ClientHistory] Access denied: PersonalData has associated User account');
        return null;
      }
    }

    // Get personal data
    final personalDataRows = await _db.execute('''
      SELECT * FROM PersonalData WHERE id = ?
    ''', [personalDataId]);

    print('[ClientHistory] PersonalData rows: ${personalDataRows.length}');

    if (personalDataRows.isEmpty) {
      print('[ClientHistory] No PersonalData found!');
      return null;
    }

    final pdRow = personalDataRows.first;

    // Get phones
    final phoneRows = await _db.execute('''
      SELECT phone FROM Phone WHERE personalData = ?
    ''', [personalDataId]);
    final phones = phoneRows
        .map((r) => r['phone'] as String?)
        .where((p) => p != null)
        .cast<String>()
        .toList();

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
      LEFT JOIN Route r ON loc.route = r.id
      WHERE a.personalData = ?
    ''', [personalDataId]);

    final addresses = addressRows.map((r) => AddressInfo.fromRow(r)).toList();

    final personalData = PersonalData.fromRow(
      pdRow,
      phones: phones,
      addresses: addresses,
    );

    // Get loans as client
    print('[ClientHistory] Getting loans as client...');
    List<Loan> loansAsClient = [];
    try {
      loansAsClient = await _getLoansAsClient(personalDataId);
      print('[ClientHistory] Loans as client: ${loansAsClient.length}');
    } catch (e, stack) {
      print('[ClientHistory] ERROR getting loans as client: $e');
      print('[ClientHistory] Stack: $stack');
    }

    // Get loans as collateral
    print('[ClientHistory] Getting loans as collateral...');
    List<Loan> loansAsCollateral = [];
    try {
      loansAsCollateral = await _getLoansAsCollateral(personalDataId);
      print('[ClientHistory] Loans as collateral: ${loansAsCollateral.length}');
    } catch (e, stack) {
      print('[ClientHistory] ERROR getting loans as collateral: $e');
      print('[ClientHistory] Stack: $stack');
    }

    // Calculate summary
    final summary = ClientSummary.fromLoans(
      loansAsClient: loansAsClient,
      loansAsCollateral: loansAsCollateral,
    );

    print('[ClientHistory] Summary calculated, returning history');
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
         LEFT JOIN PersonalData pd2 ON e.personalData = pd2.id
         WHERE e.id = l.lead
         LIMIT 1) as leadName,
        (SELECT loc.name FROM Employee e
         LEFT JOIN PersonalData pd2 ON e.personalData = pd2.id
         LEFT JOIN Address a ON a.personalData = pd2.id
         LEFT JOIN Location loc ON a.location = loc.id
         WHERE e.id = l.lead
         LIMIT 1) as leadLocality
      FROM Loan l
      JOIN Borrower b ON l.borrower = b.id
      LEFT JOIN PersonalData pd ON b.personalData = pd.id
      LEFT JOIN Loantype lt ON l.loantype = lt.id
      WHERE b.personalData = ?
      ORDER BY l.signDate DESC
    ''', [personalDataId]);

    final loans = <Loan>[];
    for (final row in results) {
      final loanId = row['id'] as String?;
      if (loanId == null || loanId.isEmpty) continue;

      // Get collateral names for this loan
      final collateralRows = await _db.execute('''
        SELECT pd.fullName
        FROM "_LoanCollaterals" lc
        JOIN PersonalData pd ON lc.B = pd.id
        WHERE lc.A = ?
      ''', [loanId]);
      final collateralNames = collateralRows
          .map((r) => r['fullName'] as String?)
          .where((n) => n != null)
          .cast<String>()
          .toList();

      // Get payments for this loan
      final payments = await _getPaymentsForLoan(loanId);

      loans.add(Loan.fromRow(
        row,
        borrowerName: row['borrowerName'] as String?,
        leadName: row['leadName'] as String?,
        leadLocality: row['leadLocality'] as String?,
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
         LEFT JOIN PersonalData pd2 ON e.personalData = pd2.id
         WHERE e.id = l.lead
         LIMIT 1) as leadName,
        (SELECT loc.name FROM Employee e
         LEFT JOIN PersonalData pd2 ON e.personalData = pd2.id
         LEFT JOIN Address a ON a.personalData = pd2.id
         LEFT JOIN Location loc ON a.location = loc.id
         WHERE e.id = l.lead
         LIMIT 1) as leadLocality
      FROM Loan l
      JOIN "_LoanCollaterals" lc ON lc.A = l.id
      LEFT JOIN Borrower b ON l.borrower = b.id
      LEFT JOIN PersonalData pd ON b.personalData = pd.id
      LEFT JOIN Loantype lt ON l.loantype = lt.id
      WHERE lc.B = ?
      ORDER BY l.signDate DESC
    ''', [personalDataId]);

    final loans = <Loan>[];
    for (final row in results) {
      final loanId = row['id'] as String?;
      if (loanId == null || loanId.isEmpty) continue;

      final payments = await _getPaymentsForLoan(loanId);

      loans.add(Loan.fromRow(
        row,
        borrowerName: row['borrowerName'] as String?,
        leadName: row['leadName'] as String?,
        leadLocality: row['leadLocality'] as String?,
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
    final collateralNames = collateralRows
        .map((r) => r['fullName'] as String?)
        .where((n) => n != null)
        .cast<String>()
        .toList();

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
