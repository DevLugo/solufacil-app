import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'powersync_provider.dart';
import '../data/repositories/borrower_repository.dart';

/// Provider for BorrowerRepository instance
final borrowerRepositoryProvider = Provider<BorrowerRepository?>((ref) {
  final dbAsync = ref.watch(powerSyncDatabaseProvider);
  final db = dbAsync.valueOrNull;

  if (db == null) return null;

  return BorrowerRepository(db);
});

/// Configuration for client search
/// - leadId: Used to filter active loans for defaults (Lead's ID)
/// - locationId: Used to mark isFromCurrentLocation in search results
class ClientSearchConfig {
  final String? leadId;
  final String? locationId;

  const ClientSearchConfig({this.leadId, this.locationId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientSearchConfig &&
          runtimeType == other.runtimeType &&
          leadId == other.leadId &&
          locationId == other.locationId;

  @override
  int get hashCode => leadId.hashCode ^ locationId.hashCode;
}

/// State for client search
class ClientSearchState {
  final String query;
  final bool isLoading;
  final bool isLoadingDefaults;
  final List<ClientForLoan> results;
  final List<ClientForLoan> defaultClients; // Clients with active loans
  final String? error;

  const ClientSearchState({
    this.query = '',
    this.isLoading = false,
    this.isLoadingDefaults = false,
    this.results = const [],
    this.defaultClients = const [],
    this.error,
  });

  ClientSearchState copyWith({
    String? query,
    bool? isLoading,
    bool? isLoadingDefaults,
    List<ClientForLoan>? results,
    List<ClientForLoan>? defaultClients,
    String? error,
  }) {
    return ClientSearchState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      isLoadingDefaults: isLoadingDefaults ?? this.isLoadingDefaults,
      results: results ?? this.results,
      defaultClients: defaultClients ?? this.defaultClients,
      error: error,
    );
  }
}

/// Notifier for client search functionality
class ClientSearchNotifier extends StateNotifier<ClientSearchState> {
  final BorrowerRepository? _repository;
  final String? _leadId;
  final String? _locationId;
  Timer? _debounceTimer;
  static const _debounceDuration = Duration(milliseconds: 300);

  ClientSearchNotifier(this._repository, this._leadId, this._locationId) : super(const ClientSearchState()) {
    // Load default clients (with active loans) on initialization
    loadDefaultClients();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Load clients with active loans as default options
  Future<void> loadDefaultClients() async {
    if (_repository == null) return;

    state = state.copyWith(isLoadingDefaults: true);

    try {
      final defaults = await _repository.getClientsWithActiveLoans(
        leadId: _leadId,
        limit: 5,
      );
      state = state.copyWith(defaultClients: defaults, isLoadingDefaults: false);
    } catch (e) {
      state = state.copyWith(isLoadingDefaults: false);
    }
  }

  /// Search clients by name (with debounce)
  Future<void> search(String query) async {
    // Cancel any pending search
    _debounceTimer?.cancel();

    if (_repository == null) {
      state = state.copyWith(error: 'Database not available');
      return;
    }

    if (query.length < 2) {
      state = state.copyWith(query: query, results: [], isLoading: false);
      return;
    }

    // Show loading immediately for feedback
    state = state.copyWith(query: query, isLoading: true, error: null);

    // Debounce the actual search
    _debounceTimer = Timer(_debounceDuration, () async {
      try {
        final results = await _repository.searchClientsForLoan(
          query,
          locationId: _locationId,
        );
        // Only update if query hasn't changed
        if (state.query == query) {
          state = state.copyWith(results: results, isLoading: false);
        }
      } catch (e) {
        if (state.query == query) {
          state = state.copyWith(error: e.toString(), isLoading: false);
        }
      }
    });
  }

  /// Search clients by phone
  Future<void> searchByPhone(String phone) async {
    if (_repository == null) {
      state = state.copyWith(error: 'Database not available');
      return;
    }

    if (phone.length < 4) {
      state = state.copyWith(query: phone, results: [], isLoading: false);
      return;
    }

    state = state.copyWith(query: phone, isLoading: true, error: null);

    try {
      final results = await _repository.searchClientsByPhone(phone);
      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Clear search results
  void clear() {
    state = const ClientSearchState();
  }

  /// Create a new borrower/client
  Future<ClientForLoan?> createBorrower(CreateBorrowerInput input) async {
    if (_repository == null) return null;

    try {
      return await _repository.createBorrower(input);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Get client details with active loan info
  Future<ClientForLoan?> getClientDetails(String personalDataId) async {
    if (_repository == null) return null;

    try {
      return await _repository.getClientById(personalDataId);
    } catch (e) {
      return null;
    }
  }
}

/// Provider for client search notifier
/// Uses ClientSearchConfig to pass both leadId and locationId
final clientSearchProvider = StateNotifierProvider.family<ClientSearchNotifier, ClientSearchState, ClientSearchConfig>(
  (ref, config) {
    final repository = ref.watch(borrowerRepositoryProvider);
    return ClientSearchNotifier(repository, config.leadId, config.locationId);
  },
);

/// Provider for collateral/aval search (same as client but separate state)
final collateralSearchProvider = StateNotifierProvider.family<ClientSearchNotifier, ClientSearchState, ClientSearchConfig>(
  (ref, config) {
    final repository = ref.watch(borrowerRepositoryProvider);
    return ClientSearchNotifier(repository, config.leadId, config.locationId);
  },
);
