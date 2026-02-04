import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/release_info.dart';
import '../services/update_service.dart';

/// Estado do verificador de atualizações
class UpdateState {
  final bool isChecking;
  final bool hasUpdate;
  final ReleaseInfo? latestRelease;
  final String currentVersion;
  final String? error;
  final DateTime? lastChecked;

  UpdateState({
    this.isChecking = false,
    this.hasUpdate = false,
    this.latestRelease,
    this.currentVersion = '1.0.0',
    this.error,
    this.lastChecked,
  });

  UpdateState copyWith({
    bool? isChecking,
    bool? hasUpdate,
    ReleaseInfo? latestRelease,
    String? currentVersion,
    String? error,
    DateTime? lastChecked,
  }) {
    return UpdateState(
      isChecking: isChecking ?? this.isChecking,
      hasUpdate: hasUpdate ?? this.hasUpdate,
      latestRelease: latestRelease ?? this.latestRelease,
      currentVersion: currentVersion ?? this.currentVersion,
      error: error ?? this.error,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }
}

/// Provider do UpdateService
final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService(
    owner: 'dimmesheldon',
    repo: 'sushigen',
  );
});

/// Provider do estado de atualização
class UpdateNotifier extends StateNotifier<UpdateState> {
  final UpdateService _updateService;
  final SharedPreferences _prefs;

  UpdateNotifier(this._updateService, this._prefs) : super(UpdateState()) {
    _loadCurrentVersion();
    _loadLastChecked();
  }

  /// Carregar versão atual do app
  Future<void> _loadCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      state = state.copyWith(currentVersion: packageInfo.version);
    } catch (e) {
      print('❌ Erro ao carregar versão: $e');
    }
  }

  /// Carregar data da última verificação
  void _loadLastChecked() {
    final timestamp = _prefs.getInt('last_update_check');
    if (timestamp != null) {
      state = state.copyWith(
        lastChecked: DateTime.fromMillisecondsSinceEpoch(timestamp),
      );
    }
  }

  /// Salvar data da última verificação
  Future<void> _saveLastChecked() async {
    final now = DateTime.now();
    await _prefs.setInt('last_update_check', now.millisecondsSinceEpoch);
    state = state.copyWith(lastChecked: now);
  }

  /// Verificar se há atualizações disponíveis
  Future<void> checkForUpdates({bool silent = false}) async {
    if (state.isChecking) return;

    state = state.copyWith(isChecking: true, error: null);

    try {
      final latestRelease = await _updateService.getLatestRelease();

      if (latestRelease == null) {
        state = state.copyWith(
          isChecking: false,
          hasUpdate: false,
          error: silent ? null : 'Nenhuma atualização encontrada',
        );
        await _saveLastChecked();
        return;
      }

      // Comparar versões
      final hasUpdate = await _updateService.hasUpdate(state.currentVersion);

      state = state.copyWith(
        isChecking: false,
        hasUpdate: hasUpdate,
        latestRelease: latestRelease,
        error: null,
      );

      await _saveLastChecked();

      if (hasUpdate) {
        print('🎉 Nova versão disponível: ${latestRelease.version}');
      } else if (!silent) {
        print('✅ Você está usando a versão mais recente');
      }
    } catch (e) {
      state = state.copyWith(
        isChecking: false,
        hasUpdate: false,
        error: 'Erro ao verificar atualizações: $e',
      );
      await _saveLastChecked();
    }
  }

  /// Verificar se deve mostrar notificação de atualização
  /// (não mostrar mais de 1x por dia)
  bool shouldCheckForUpdates() {
    if (state.lastChecked == null) return true;

    final hoursSinceLastCheck =
        DateTime.now().difference(state.lastChecked!).inHours;

    // Verificar a cada 24 horas
    return hoursSinceLastCheck >= 24;
  }

  /// Marcar atualização como "lembrar depois"
  Future<void> remindLater() async {
    await _prefs.setInt(
      'remind_update_later',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Verificar se deve lembrar de atualizar
  bool shouldRemindUpdate() {
    final timestamp = _prefs.getInt('remind_update_later');
    if (timestamp == null) return true;

    final lastRemind = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final hoursSinceRemind = DateTime.now().difference(lastRemind).inHours;

    // Lembrar novamente após 24 horas
    return hoursSinceRemind >= 24;
  }

  /// Marcar atualização como ignorada
  Future<void> skipVersion(String version) async {
    await _prefs.setString('skipped_version', version);
  }

  /// Verificar se versão foi ignorada
  bool isVersionSkipped(String version) {
    final skippedVersion = _prefs.getString('skipped_version');
    return skippedVersion == version;
  }

  /// Limpar versão ignorada
  Future<void> clearSkippedVersion() async {
    await _prefs.remove('skipped_version');
  }
}

/// Provider do UpdateNotifier
final updateNotifierProvider =
    StateNotifierProvider<UpdateNotifier, UpdateState>((ref) {
  throw UnimplementedError('updateNotifierProvider must be overridden');
});

/// Provider helper para inicializar com SharedPreferences
final updateCheckerProvider =
    FutureProvider<UpdateNotifier>((ref) async {
  final updateService = ref.read(updateServiceProvider);
  final prefs = await SharedPreferences.getInstance();
  return UpdateNotifier(updateService, prefs);
});
