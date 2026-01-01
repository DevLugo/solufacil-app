import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/client_history_repository.dart';
import '../data/models/client_history.dart';
import '../data/models/loan.dart';
import '../core/config/app_config.dart';
import 'powersync_provider.dart';

/// Client history repository provider
final clientHistoryRepositoryProvider =
    FutureProvider<ClientHistoryRepository>((ref) async {
  final db = await ref.watch(powerSyncDatabaseProvider.future);
  return ClientHistoryRepository(db);
});

/// Search state
class SearchState {
  final String query;
  final List<ClientSearchResult> results;
  final bool isLoading;
  final String? error;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  SearchState copyWith({
    String? query,
    List<ClientSearchResult>? results,
    bool? isLoading,
    String? error,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Client search notifier
class ClientSearchNotifier extends StateNotifier<SearchState> {
  final Ref _ref;
  Timer? _debounceTimer;

  ClientSearchNotifier(this._ref) : super(const SearchState());

  /// Search clients with debounce
  void search(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Update query immediately
    state = state.copyWith(query: query);

    // If query is too short, clear results
    if (query.length < AppConfig.searchMinChars) {
      state = state.copyWith(results: [], isLoading: false);
      return;
    }

    // Show loading
    state = state.copyWith(isLoading: true);

    // Debounce the actual search
    _debounceTimer = Timer(
      Duration(milliseconds: AppConfig.searchDebounceMs),
      () => _performSearch(query),
    );
  }

  /// Perform the actual search
  Future<void> _performSearch(String query) async {
    try {
      final repository = await _ref.read(clientHistoryRepositoryProvider.future);
      final results = await repository.searchClients(query);

      // Only update if query hasn't changed
      if (state.query == query) {
        state = state.copyWith(
          results: results,
          isLoading: false,
          error: null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al buscar: ${e.toString()}',
      );
    }
  }

  /// Clear search
  void clear() {
    _debounceTimer?.cancel();
    state = const SearchState();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

/// Client search provider
final clientSearchProvider =
    StateNotifierProvider<ClientSearchNotifier, SearchState>((ref) {
  return ClientSearchNotifier(ref);
});

/// Selected client state
class SelectedClientState {
  final ClientSearchResult? selectedClient;
  final ClientHistory? history;
  final bool isLoading;
  final String? error;

  const SelectedClientState({
    this.selectedClient,
    this.history,
    this.isLoading = false,
    this.error,
  });

  SelectedClientState copyWith({
    ClientSearchResult? selectedClient,
    ClientHistory? history,
    bool? isLoading,
    String? error,
  }) {
    return SelectedClientState(
      selectedClient: selectedClient ?? this.selectedClient,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Selected client notifier
class SelectedClientNotifier extends StateNotifier<SelectedClientState> {
  final Ref _ref;

  SelectedClientNotifier(this._ref) : super(const SelectedClientState());

  /// Select a client and load their history
  Future<void> selectClient(ClientSearchResult client) async {
    state = SelectedClientState(
      selectedClient: client,
      isLoading: true,
    );

    try {
      final repository = await _ref.read(clientHistoryRepositoryProvider.future);
      final history = await repository.getClientHistory(client.id);

      state = SelectedClientState(
        selectedClient: client,
        history: history,
        isLoading: false,
      );
    } catch (e) {
      state = SelectedClientState(
        selectedClient: client,
        isLoading: false,
        error: 'Error al cargar historial: ${e.toString()}',
      );
    }
  }

  /// Clear selection
  void clear() {
    state = const SelectedClientState();
  }

  /// Refresh client history
  Future<void> refresh() async {
    if (state.selectedClient == null) return;
    await selectClient(state.selectedClient!);
  }
}

/// Selected client provider
final selectedClientProvider =
    StateNotifierProvider<SelectedClientNotifier, SelectedClientState>((ref) {
  return SelectedClientNotifier(ref);
});

/// Loan details provider
final loanDetailsProvider =
    FutureProvider.family<Loan?, String>((ref, loanId) async {
  final repository = await ref.watch(clientHistoryRepositoryProvider.future);
  return repository.getLoanDetails(loanId);
});
