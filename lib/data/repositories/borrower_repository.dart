import 'package:powersync/powersync.dart';
import 'package:uuid/uuid.dart';

/// Client/Borrower with loan information for the wizard
class ClientForLoan {
  final String id; // PersonalData ID
  final String? borrowerId; // Borrower ID if exists
  final String fullName;
  final String? clientCode;
  final String? phone;
  final String? locationId;
  final String? locationName;
  final bool isFromCurrentLocation; // Whether client is from the current selected location
  final bool hasActiveLoan;
  final ActiveLoanInfo? activeLoan;
  final int loanFinishedCount;

  const ClientForLoan({
    required this.id,
    this.borrowerId,
    required this.fullName,
    this.clientCode,
    this.phone,
    this.locationId,
    this.locationName,
    this.isFromCurrentLocation = true,
    this.hasActiveLoan = false,
    this.activeLoan,
    this.loanFinishedCount = 0,
  });

  /// Whether this client can be renewed (has active loan with pending debt)
  bool get canBeRenewed => hasActiveLoan && activeLoan != null && activeLoan!.pendingAmount > 0;
}

/// Active loan information for renewal
class ActiveLoanInfo {
  final String loanId;
  final double requestedAmount;
  final double totalDebtAcquired;
  final double profitAmount;
  final double pendingAmount;
  final double totalPaid;
  final String loantypeName;
  final DateTime signDate;

  const ActiveLoanInfo({
    required this.loanId,
    required this.requestedAmount,
    required this.totalDebtAcquired,
    required this.profitAmount,
    required this.pendingAmount,
    required this.totalPaid,
    required this.loantypeName,
    required this.signDate,
  });
}

/// Input for creating a new borrower/client
class CreateBorrowerInput {
  final String fullName;
  final String? phone;
  final String? street;
  final String? locationId;

  const CreateBorrowerInput({
    required this.fullName,
    this.phone,
    this.street,
    this.locationId,
  });
}

/// Repository for Borrower/Client operations
class BorrowerRepository {
  final PowerSyncDatabase _db;
  final _uuid = const Uuid();

  BorrowerRepository(this._db);

  /// Search clients by name or phone for loan creation
  ///
  /// Returns clients with their active loan status for renewal detection.
  /// Does NOT filter by location - instead marks isFromCurrentLocation for grouping.
  Future<List<ClientForLoan>> searchClientsForLoan(
    String searchTerm, {
    String? locationId,
    int limit = 20,
  }) async {
    if (searchTerm.length < 2) {
      return [];
    }

    final term = '%$searchTerm%';

    // Optimized query using JOINs instead of correlated subqueries
    // Uses a CTE to get the most recent active loan per borrower
    final query = '''
      WITH ActiveLoans AS (
        SELECT
          l.borrower,
          l.id as loanId,
          l.requestedAmount,
          l.totalDebtAcquired,
          l.profitAmount,
          l.pendingAmountStored,
          l.totalPaid,
          l.signDate,
          l.loantype,
          ROW_NUMBER() OVER (PARTITION BY l.borrower ORDER BY l.signDate DESC) as rn
        FROM Loan l
        WHERE l.status = 'ACTIVE'
      )
      SELECT
        pd.id,
        b.id as borrowerId,
        pd.fullName,
        pd.clientCode,
        ph.phone,
        addr.location as clientLocationId,
        loc.name as locationName,
        COALESCE(b.loanFinishedCount, 0) as loanFinishedCount,
        al.loanId as activeLoanId,
        al.requestedAmount as activeLoanRequestedAmount,
        al.totalDebtAcquired as activeLoanTotalDebt,
        al.profitAmount as activeLoanProfit,
        al.pendingAmountStored as activeLoanPending,
        al.totalPaid as activeLoanTotalPaid,
        al.signDate as activeLoanSignDate,
        lt.name as activeLoanTypeName
      FROM PersonalData pd
      LEFT JOIN Borrower b ON b.personalData = pd.id
      LEFT JOIN Phone ph ON ph.personalData = pd.id
      LEFT JOIN Address addr ON addr.personalData = pd.id
      LEFT JOIN Location loc ON addr.location = loc.id
      LEFT JOIN ActiveLoans al ON al.borrower = b.id AND al.rn = 1
      LEFT JOIN Loantype lt ON al.loantype = lt.id
      WHERE pd.fullName LIKE ? OR pd.clientCode LIKE ?
      GROUP BY pd.id
      ORDER BY pd.fullName
      LIMIT ?
    ''';

    final params = <dynamic>[term, term, limit];

    final results = await _db.execute(query, params);

    return results.map((row) {
      final activeLoanId = row['activeLoanId'] as String?;
      ActiveLoanInfo? activeLoan;

      if (activeLoanId != null) {
        activeLoan = ActiveLoanInfo(
          loanId: activeLoanId,
          requestedAmount: (row['activeLoanRequestedAmount'] as num?)?.toDouble() ?? 0,
          totalDebtAcquired: (row['activeLoanTotalDebt'] as num?)?.toDouble() ?? 0,
          profitAmount: (row['activeLoanProfit'] as num?)?.toDouble() ?? 0,
          pendingAmount: (row['activeLoanPending'] as num?)?.toDouble() ?? 0,
          totalPaid: (row['activeLoanTotalPaid'] as num?)?.toDouble() ?? 0,
          loantypeName: row['activeLoanTypeName'] as String? ?? '',
          signDate: DateTime.parse(row['activeLoanSignDate'] as String),
        );
      }

      final clientLocationId = row['clientLocationId'] as String?;
      // isFromCurrentLocation: true if no locationId filter, no location found, or locations match
      final isFromCurrentLocation = locationId == null || clientLocationId == null || clientLocationId == locationId;

      return ClientForLoan(
        id: row['id'] as String,
        borrowerId: row['borrowerId'] as String?,
        fullName: row['fullName'] as String? ?? '',
        clientCode: row['clientCode'] as String?,
        phone: row['phone'] as String?,
        locationId: clientLocationId,
        locationName: row['locationName'] as String?,
        isFromCurrentLocation: isFromCurrentLocation,
        hasActiveLoan: activeLoanId != null,
        activeLoan: activeLoan,
        loanFinishedCount: (row['loanFinishedCount'] as int?) ?? 0,
      );
    }).toList();
  }

  /// Search clients by phone number
  Future<List<ClientForLoan>> searchClientsByPhone(String phone, {int limit = 10}) async {
    if (phone.length < 4) {
      return [];
    }

    final term = '%$phone%';

    final results = await _db.execute('''
      SELECT
        pd.id,
        b.id as borrowerId,
        pd.fullName,
        pd.clientCode,
        p.phone,
        COALESCE(b.loanFinishedCount, 0) as loanFinishedCount,
        (SELECT l.id FROM Loan l
         WHERE l.borrower = b.id AND l.status = 'ACTIVE'
         ORDER BY l.signDate DESC LIMIT 1) as activeLoanId
      FROM Phone p
      JOIN PersonalData pd ON p.personalData = pd.id
      LEFT JOIN Borrower b ON b.personalData = pd.id
      WHERE p.phone LIKE ?
      ORDER BY pd.fullName
      LIMIT ?
    ''', [term, limit]);

    return results.map((row) {
      return ClientForLoan(
        id: row['id'] as String,
        borrowerId: row['borrowerId'] as String?,
        fullName: row['fullName'] as String? ?? '',
        clientCode: row['clientCode'] as String?,
        phone: row['phone'] as String?,
        isFromCurrentLocation: true, // Phone search doesn't filter by location
        hasActiveLoan: row['activeLoanId'] != null,
        loanFinishedCount: (row['loanFinishedCount'] as int?) ?? 0,
      );
    }).toList();
  }

  /// Create a new borrower with PersonalData (offline-first)
  ///
  /// This creates both PersonalData and Borrower records.
  Future<ClientForLoan> createBorrower(CreateBorrowerInput input) async {
    final personalDataId = _uuid.v4();
    final borrowerId = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final clientCode = _generateClientCode();

    // Create PersonalData
    await _db.execute('''
      INSERT INTO PersonalData (id, fullName, clientCode, createdAt, updatedAt)
      VALUES (?, ?, ?, ?, ?)
    ''', [personalDataId, input.fullName, clientCode, now, now]);

    // Create Phone if provided
    if (input.phone != null && input.phone!.isNotEmpty) {
      final phoneId = _uuid.v4();
      await _db.execute('''
        INSERT INTO Phone (id, personalData, phone)
        VALUES (?, ?, ?)
      ''', [phoneId, personalDataId, input.phone]);
    }

    // Create Address if location provided
    if (input.locationId != null) {
      final addressId = _uuid.v4();
      await _db.execute('''
        INSERT INTO Address (id, personalData, street, location, createdAt)
        VALUES (?, ?, ?, ?, ?)
      ''', [addressId, personalDataId, input.street ?? '', input.locationId, now]);
    }

    // Create Borrower
    await _db.execute('''
      INSERT INTO Borrower (id, personalData, loanFinishedCount, createdAt, updatedAt)
      VALUES (?, ?, 0, ?, ?)
    ''', [borrowerId, personalDataId, now, now]);

    return ClientForLoan(
      id: personalDataId,
      borrowerId: borrowerId,
      fullName: input.fullName,
      clientCode: clientCode,
      phone: input.phone,
      locationId: input.locationId,
      isFromCurrentLocation: true, // New client is always in current location
      hasActiveLoan: false,
      loanFinishedCount: 0,
    );
  }

  /// Get borrower ID for a PersonalData ID, creating if necessary
  Future<String> getOrCreateBorrowerId(String personalDataId) async {
    // Check if borrower exists
    final existing = await _db.execute('''
      SELECT id FROM Borrower WHERE personalData = ?
    ''', [personalDataId]);

    if (existing.isNotEmpty) {
      return existing.first['id'] as String;
    }

    // Create borrower
    final borrowerId = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await _db.execute('''
      INSERT INTO Borrower (id, personalData, loanFinishedCount, createdAt, updatedAt)
      VALUES (?, ?, 0, ?, ?)
    ''', [borrowerId, personalDataId, now, now]);

    return borrowerId;
  }

  /// Get client details by PersonalData ID
  Future<ClientForLoan?> getClientById(String personalDataId) async {
    final results = await _db.execute('''
      SELECT
        pd.id,
        b.id as borrowerId,
        pd.fullName,
        pd.clientCode,
        (SELECT phone FROM Phone WHERE personalData = pd.id LIMIT 1) as phone,
        (SELECT a.location FROM Address a WHERE a.personalData = pd.id LIMIT 1) as locationId,
        (SELECT loc.name FROM Address a
         JOIN Location loc ON a.location = loc.id
         WHERE a.personalData = pd.id LIMIT 1) as locationName,
        COALESCE(b.loanFinishedCount, 0) as loanFinishedCount
      FROM PersonalData pd
      LEFT JOIN Borrower b ON b.personalData = pd.id
      WHERE pd.id = ?
    ''', [personalDataId]);

    if (results.isEmpty) return null;

    final row = results.first;
    final borrowerId = row['borrowerId'] as String?;

    // Get active loan if borrower exists
    ActiveLoanInfo? activeLoan;
    if (borrowerId != null) {
      final loanResults = await _db.execute('''
        SELECT
          l.id,
          l.requestedAmount,
          l.totalDebtAcquired,
          l.profitAmount,
          l.pendingAmountStored,
          l.totalPaid,
          l.signDate,
          lt.name as loantypeName
        FROM Loan l
        LEFT JOIN Loantype lt ON l.loantype = lt.id
        WHERE l.borrower = ? AND l.status = 'ACTIVE'
        ORDER BY l.signDate DESC
        LIMIT 1
      ''', [borrowerId]);

      if (loanResults.isNotEmpty) {
        final loanRow = loanResults.first;
        activeLoan = ActiveLoanInfo(
          loanId: loanRow['id'] as String,
          requestedAmount: (loanRow['requestedAmount'] as num?)?.toDouble() ?? 0,
          totalDebtAcquired: (loanRow['totalDebtAcquired'] as num?)?.toDouble() ?? 0,
          profitAmount: (loanRow['profitAmount'] as num?)?.toDouble() ?? 0,
          pendingAmount: (loanRow['pendingAmountStored'] as num?)?.toDouble() ?? 0,
          totalPaid: (loanRow['totalPaid'] as num?)?.toDouble() ?? 0,
          loantypeName: loanRow['loantypeName'] as String? ?? '',
          signDate: DateTime.parse(loanRow['signDate'] as String),
        );
      }
    }

    return ClientForLoan(
      id: row['id'] as String,
      borrowerId: borrowerId,
      fullName: row['fullName'] as String? ?? '',
      clientCode: row['clientCode'] as String?,
      phone: row['phone'] as String?,
      locationId: row['locationId'] as String?,
      locationName: row['locationName'] as String?,
      isFromCurrentLocation: true, // Single client lookup doesn't filter by location
      hasActiveLoan: activeLoan != null,
      activeLoan: activeLoan,
      loanFinishedCount: (row['loanFinishedCount'] as int?) ?? 0,
    );
  }

  /// Get clients with active loans for renewal (default options)
  ///
  /// Returns up to [limit] clients that have active loans and can be renewed.
  /// Used to show default options in the autocomplete before user types.
  /// Filters by the Lead (employee) assigned to the loan.
  Future<List<ClientForLoan>> getClientsWithActiveLoans({
    String? leadId,
    int limit = 5,
  }) async {
    String query = '''
      SELECT
        pd.id,
        b.id as borrowerId,
        pd.fullName,
        pd.clientCode,
        (SELECT phone FROM Phone WHERE personalData = pd.id LIMIT 1) as phone,
        (SELECT a.location FROM Address a WHERE a.personalData = pd.id LIMIT 1) as clientLocationId,
        (SELECT loc.name FROM Address a
         JOIN Location loc ON a.location = loc.id
         WHERE a.personalData = pd.id LIMIT 1) as locationName,
        COALESCE(b.loanFinishedCount, 0) as loanFinishedCount,
        l.id as activeLoanId,
        l.requestedAmount as activeLoanRequestedAmount,
        l.totalDebtAcquired as activeLoanTotalDebt,
        l.profitAmount as activeLoanProfit,
        l.pendingAmountStored as activeLoanPending,
        l.totalPaid as activeLoanTotalPaid,
        l.signDate as activeLoanSignDate,
        lt.name as activeLoanTypeName
      FROM Loan l
      JOIN Borrower b ON l.borrower = b.id
      JOIN PersonalData pd ON b.personalData = pd.id
      LEFT JOIN Loantype lt ON l.loantype = lt.id
      WHERE l.status = 'ACTIVE'
        AND l.renewedBy IS NULL
        AND l.pendingAmountStored > 0
    ''';

    final params = <dynamic>[];

    // Filter by Lead (employee) assigned to the loan
    if (leadId != null) {
      query += ' AND l.lead = ?';
      params.add(leadId);
    }

    query += '''
      ORDER BY l.signDate DESC
      LIMIT ?
    ''';
    params.add(limit);

    final results = await _db.execute(query, params);

    return results.map((row) {
      final activeLoanId = row['activeLoanId'] as String?;
      ActiveLoanInfo? activeLoan;

      if (activeLoanId != null) {
        activeLoan = ActiveLoanInfo(
          loanId: activeLoanId,
          requestedAmount: (row['activeLoanRequestedAmount'] as num?)?.toDouble() ?? 0,
          totalDebtAcquired: (row['activeLoanTotalDebt'] as num?)?.toDouble() ?? 0,
          profitAmount: (row['activeLoanProfit'] as num?)?.toDouble() ?? 0,
          pendingAmount: (row['activeLoanPending'] as num?)?.toDouble() ?? 0,
          totalPaid: (row['activeLoanTotalPaid'] as num?)?.toDouble() ?? 0,
          loantypeName: row['activeLoanTypeName'] as String? ?? '',
          signDate: DateTime.parse(row['activeLoanSignDate'] as String),
        );
      }

      return ClientForLoan(
        id: row['id'] as String,
        borrowerId: row['borrowerId'] as String?,
        fullName: row['fullName'] as String? ?? '',
        clientCode: row['clientCode'] as String?,
        phone: row['phone'] as String?,
        locationId: row['clientLocationId'] as String?,
        locationName: row['locationName'] as String?,
        isFromCurrentLocation: true, // Active loans are always from the selected lead
        hasActiveLoan: true,
        activeLoan: activeLoan,
        loanFinishedCount: (row['loanFinishedCount'] as int?) ?? 0,
      );
    }).toList();
  }

  /// Generate a unique client code
  String _generateClientCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'C${timestamp.substring(timestamp.length - 8)}';
  }
}
