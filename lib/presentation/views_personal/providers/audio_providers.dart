import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/services/audio_download_service.dart';
import '../../../data/datasources/local/audio_local_datasource.dart';
import '../../../data/datasources/local/catalog_local_datasource.dart';
import '../../../data/repositories/audio_repository_impl.dart';
import '../../../domain/repositories/audio_repository.dart';

/// Provider del datasource local de audio (singleton).
final audioLocalDataSourceProvider = Provider<AudioLocalDataSource>((ref) {
  final dataSource = AudioLocalDataSource();
  ref.onDispose(() => dataSource.dispose());
  return dataSource;
});

/// Provider del repositorio de audio.
final audioRepositoryProvider = Provider<AudioRepository>((ref) {
  final audioDS = ref.read(audioLocalDataSourceProvider);
  final catalogDS = CatalogLocalDataSource(dbHelper: DatabaseHelper.instance);
  return AudioRepositoryImpl(
    audioDataSource: audioDS,
    catalogDataSource: catalogDS,
  );
});

/// Provider que indica si hay audio reproduciéndose actualmente.
final isAudioPlayingProvider = StateProvider<bool>((ref) => false);

// ─── Descarga de pistas ────────────────────────────────────────

/// Provider del servicio de descarga de audio.
final audioDownloadServiceProvider =
    Provider<AudioDownloadService>((ref) => AudioDownloadService());

/// Estado posible de una descarga de pista.
enum DownloadStatus { idle, downloading, done, error }

/// Estado observable de una descarga.
class DownloadState {
  final DownloadStatus status;
  final double progress;
  final String? errorMessage;

  const DownloadState({
    this.status = DownloadStatus.idle,
    this.progress = 0.0,
    this.errorMessage,
  });
}

/// Notifier que maneja el estado de descarga para una pista específica.
class DownloadPistaNotifier extends StateNotifier<DownloadState> {
  final Ref ref;
  final int pistaId;

  DownloadPistaNotifier(this.ref, this.pistaId)
      : super(const DownloadState());

  /// Inicia la descarga de la pista.
  Future<void> download() async {
    state = const DownloadState(status: DownloadStatus.downloading);
    try {
      final repo = ref.read(audioRepositoryProvider);
      await repo.downloadPista(
        pistaId,
        onProgress: (p) {
          state = DownloadState(
            status: DownloadStatus.downloading,
            progress: p,
          );
        },
      );
      state = const DownloadState(status: DownloadStatus.done);
    } catch (e) {
      state = DownloadState(
        status: DownloadStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Cancela la descarga en curso.
  void cancel() {
    final repo = ref.read(audioRepositoryProvider);
    repo.cancelDownload(pistaId);
    state = const DownloadState();
  }

  /// Reinicia el estado a idle.
  void reset() {
    state = const DownloadState();
  }
}

/// Provider family que crea un [DownloadPistaNotifier] por cada [pistaId].
final downloadPistaStateProvider =
    StateNotifierProvider.family<DownloadPistaNotifier, DownloadState, int>(
        (ref, pistaId) {
  return DownloadPistaNotifier(ref, pistaId);
});

/// Provider que verifica si una pista ya está descargada.
final isPistaDownloadedProvider =
    FutureProvider.family<bool, int>((ref, pistaId) async {
  final repo = ref.read(audioRepositoryProvider);
  return repo.isDownloaded(pistaId);
});
