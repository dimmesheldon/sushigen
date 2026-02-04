import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sync_service.dart';

final syncServiceProvider = Provider((ref) => SyncService());

class SyncState {
  final bool isSyncing;
  final DateTime? lastSync;
  final String? error;
  final Map<String, int> unsyncedCounts;
  final String? currentOperation;

  SyncState({
    this.isSyncing = false,
    this.lastSync,
    this.error,
    this.unsyncedCounts = const {},
    this.currentOperation,
  });

  SyncState copyWith({
    bool? isSyncing,
    DateTime? lastSync,
    String? error,
    Map<String, int>? unsyncedCounts,
    String? currentOperation,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSync: lastSync ?? this.lastSync,
      error: error,
      unsyncedCounts: unsyncedCounts ?? this.unsyncedCounts,
      currentOperation: currentOperation,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  final SyncService _syncService;

  SyncNotifier(this._syncService) : super(SyncState()) {
    _loadUnsyncedCounts();
  }

  // Carregar contagem de itens não sincronizados
  Future<void> _loadUnsyncedCounts() async {
    final counts = await _syncService.getUnsyncedCounts();
    state = state.copyWith(unsyncedCounts: counts);
  }

  // Sincronizar agora (upload)
  Future<void> syncNow() async {
    if (state.isSyncing) return;

    state = state.copyWith(
      isSyncing: true,
      error: null,
      currentOperation: 'Preparando sincronização...',
    );

    try {
      state = state.copyWith(currentOperation: 'Sincronizando produtos...');
      await _syncService.syncProducts();

      state = state.copyWith(currentOperation: 'Sincronizando vendas...');
      await _syncService.syncSales();

      state = state.copyWith(
        currentOperation: 'Sincronizando fluxo de caixa...',
      );
      await _syncService.syncCashFlow();

      state = state.copyWith(
        isSyncing: false,
        lastSync: DateTime.now(),
        currentOperation: null,
      );

      // Recarregar contagens
      await _loadUnsyncedCounts();
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: e.toString(),
        currentOperation: null,
      );
    }
  }

  // Baixar dados do servidor (download)
  Future<void> downloadData() async {
    if (state.isSyncing) return;

    state = state.copyWith(
      isSyncing: true,
      error: null,
      currentOperation: 'Baixando dados...',
    );

    try {
      state = state.copyWith(currentOperation: 'Baixando produtos...');
      await _syncService.downloadProducts();

      state = state.copyWith(currentOperation: 'Baixando vendas...');
      await _syncService.downloadSales();

      state = state.copyWith(
        isSyncing: false,
        lastSync: DateTime.now(),
        currentOperation: null,
      );

      // Recarregar contagens
      await _loadUnsyncedCounts();
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: e.toString(),
        currentOperation: null,
      );
    }
  }

  // Sincronização bidirecional (upload + download)
  Future<void> syncBidirectional() async {
    if (state.isSyncing) return;

    state = state.copyWith(
      isSyncing: true,
      error: null,
      currentOperation: 'Sincronização bidirecional...',
    );

    try {
      // 1. Upload de dados locais
      state = state.copyWith(currentOperation: 'Enviando dados locais...');
      await _syncService.syncAll();

      // 2. Download de dados do servidor
      state = state.copyWith(currentOperation: 'Baixando dados do servidor...');
      await _syncService.downloadAll();

      state = state.copyWith(
        isSyncing: false,
        lastSync: DateTime.now(),
        currentOperation: null,
      );

      // Recarregar contagens
      await _loadUnsyncedCounts();
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: e.toString(),
        currentOperation: null,
      );
    }
  }

  // Atualizar contagens manualmente
  Future<void> refreshCounts() async {
    await _loadUnsyncedCounts();
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final syncService = ref.read(syncServiceProvider);
  return SyncNotifier(syncService);
});
