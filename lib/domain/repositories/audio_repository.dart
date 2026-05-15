import 'dart:async';

import '../entities/pista_audio.dart';

/// Callback para reportar progreso de descarga (0.0 a 1.0).
typedef DownloadProgressCallback = void Function(double progress);

/// Repositorio de audio.
/// Define el contrato para la reproducción de pistas de audio asociadas a himnos.
abstract class AudioRepository {
  /// Obtiene las pistas de audio de un himno.
  Future<List<PistaAudio>> getByHimno(int himnoId);

  /// Inicia la reproducción de una pista.
  Future<void> play(int pistaId);

  /// Detiene la reproducción actual.
  Future<void> stop();

  /// Pausa la reproducción actual.
  Future<void> pause();

  /// Reanuda la reproducción pausada.
  Future<void> resume();

  /// Navega a una posición específica.
  Future<void> seek(Duration position);

  /// Stream de cambios de posición.
  Stream<Duration> get onPositionChanged;

  /// Stream con la duración total.
  Stream<Duration?> get onDurationChanged;

  /// Indica si hay reproducción en curso.
  bool get isPlaying;

  // ─── Descarga de pistas ────────────────────────────────────

  /// Descarga una pista remota. Retorna la ruta local del archivo.
  Future<String> downloadPista(
    int pistaId, {
    DownloadProgressCallback? onProgress,
  });

  /// Verifica si la pista [pistaId] ya está descargada localmente.
  Future<bool> isDownloaded(int pistaId);

  /// Retorna la ruta local de la pista [pistaId], o `null` si no existe.
  Future<String?> getLocalPath(int pistaId);

  /// Cancela una descarga en curso para la pista [pistaId].
  void cancelDownload(int pistaId);
}
