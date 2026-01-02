import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'powersync_provider.dart';
import '../data/models/loan_type.dart';

/// Provider for loan types from PowerSync database
final loanTypesProvider = FutureProvider<List<LoanType>>((ref) async {
  final dbAsync = ref.watch(powerSyncDatabaseProvider);
  final db = dbAsync.valueOrNull;

  if (db == null) return [];

  final results = await db.execute('''
    SELECT * FROM Loantype
    ORDER BY weekDuration ASC, rate ASC
  ''');

  return results.map((row) => LoanType.fromRow(row)).toList();
});

/// Provider for a specific loan type by ID
final loanTypeByIdProvider = FutureProvider.family<LoanType?, String>((ref, id) async {
  final loanTypes = await ref.watch(loanTypesProvider.future);
  return loanTypes.where((lt) => lt.id == id).firstOrNull;
});
