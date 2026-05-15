import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:logging/logging.dart';

import '../../core/errors/failures.dart';
import '../../core/services/audio_download_service.dart' hide DownloadProgressCallback;
import '../../domain/entities/pista_audio.dart';
import '../../domain/repositories/audio_repository.dart';
import '../datasources/local/audio_local_datasource.dart';
import '../datasources/local/catalog_local_datasource.dart';

/// Implementación del repositorio de audio.
///
/// Usa [AudioLocalDataSource] para la reproducción y
/// [CatalogLocalDataSource] para consultar pistas desde la BD.
class AudioRepositoryImpl implements AudioRepository {
  static final _log = Logger('AudioRepositoryImpl');

  final AudioLocalDataSource _audioDataSource;
  final CatalogLocalDataSource _catalogDataSource;
  final AudioDownloadService _downloadService;

  /// Cache de pistas de audio por ID de pista.
  final Map<int, PistaAudio> _pistaCache = {};

  AudioRepositoryImpl({
    AudioLocalDataSource? audioDataSource,
    CatalogLocalDataSource? catalogDataSource,
    AudioDownloadService? downloadService,
  })  : _audioDataSource = audioDataSource ?? AudioLocalDataSource(),
        _catalogDataSource = catalogDataSource ?? CatalogLocalDataSource(),
        _downloadService = downloadService ?? AudioDownloadService();

  @override
  Future<List<PistaAudio>> getByHimno(int himnoId) async {
    try {
      final models = await _catalogDataSource.getPistasByHimno(himnoId);
      final pistas = models.map((m) => m.toEntity()).toList();

      // Poblar caché por ID de pista
      for (final pista in pistas) {
        _pistaCache[pista.id] = pista;
      }

      _log.fine('${pistas.length} pista(s) encontrada(s) para himno $himnoId');
      return pistas;
    } catch (e) {
      _log.severe('Error al obtener pistas del himno $himnoId: $e');
      throw AudioFailure('Error al obtener pistas de audio: $e');
    }
  }

  @override
  Future<void> play(int pistaId) async {
    try {
      final pista = _pistaCache[pistaId];
      if (pista == null) {
        throw AudioFailure('Pista de audio no encontrada (id: $pistaId)');
      }

      // Si la ruta es absoluta (empieza con /), usar playFromFile
      // Si no, usar playFromAsset (para assets del bundle)
      if (pista.rutaArchivo.startsWith('/')) {
        await _audioDataSource.playFromFile(pista.rutaArchivo);
      } else {
        await _audioDataSource.playFromAsset(pista.rutaArchivo);
      }
      _log.info('Reproduciendo pista $pistaId: ${pista.rutaArchivo}');
    } on AudioFailure {
      rethrow;
    } catch (e) {
      _log.severe('Error al reproducir pista $pistaId: $e');
      throw AudioFailure('Error al reproducir audio: $e');
    }
  }

  @override
  bool get isPlaying => _audioDataSource.isPlaying;

  @override
  Stream<Duration> get onPositionChanged => _audioDataSource.onPositionChanged;

  @override
  Stream<Duration?> get onDurationChanged => _audioDataSource.onDurationChanged;

  @override
  Future<void> stop() async {
    try {
      await _audioDataSource.stop();
      _log.info('Reproducción detenida.');
    } catch (e) {
      _log.severe('Error al detener audio: $e');
      throw AudioFailure('Error al detener la reproducción: $e');
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _audioDataSource.pause();
    } catch (e) {
      _log.severe('Error al pausar: $e');
    }
  }

  @override
  Future<void> resume() async {
    try {
      await _audioDataSource.resume();
    } catch (e) {
      _log.severe('Error al reanudar: $e');
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await _audioDataSource.seek(position);
    } catch (e) {
      _log.severe('Error al seek: $e');
    }
  }

  // ─── Descarga de pistas ────────────────────────────────────

  @override
  Future<String> downloadPista(
    int pistaId, {
    DownloadProgressCallback? onProgress,
  }) async {
    final pista = _pistaCache[pistaId];
    if (pista == null) {
      // Intentar cargar desde BD
      throw AudioFailure('Pista no encontrada en caché (id: $pistaId)');
    }
    if (pista.urlRemota == null || pista.urlRemota!.isEmpty) {
      throw AudioFailure('La pista $pistaId no tiene URL remota');
    }

    final extension = pista.formato != null ? '.${pista.formato}' : '.mp3';
    final fileName = 'pista_${pistaId}_${pista.himnoId}$extension';

    try {
      final localPath = await _downloadService.downloadPista(
        pistaId: pistaId,
        url: pista.urlRemota!,
        himnoId: pista.himnoId,
        fileName: fileName,
        onProgress: onProgress,
      );
      return localPath;
    } catch (e) {
      _log.severe('Error descargando pista $pistaId: $e');
      throw AudioFailure('Error al descargar pista: $e');
    }
  }

  @override
  Future<bool> isDownloaded(int pistaId) async {
    final localPath = await getLocalPath(pistaId);
    if (localPath == null) return false;
    return _downloadService.isDownloaded(localPath);
  }

  @override
  Future<String?> getLocalPath(int pistaId) async {
    final pista = _pistaCache[pistaId];
    if (pista == null) return null;

    // Si la ruta ya es local (empieza con /), retornarla directamente
    if (pista.rutaArchivo.startsWith('/')) {
      return pista.rutaArchivo;
    }

    // Si tiene urlRemota, construir la ruta de descarga esperada
    if (pista.urlRemota != null && pista.urlRemota!.isNotEmpty) {
      final appDir =
          await path_provider.getApplicationDocumentsDirectory();
      final extension = pista.formato != null ? '.${pista.formato}' : '.mp3';
      final fileName = 'pista_${pistaId}_${pista.himnoId}$extension';
      final localPath = '${appDir.path}/audio/${pista.himnoId}/$fileName';
      return localPath;
    }

    return null;
  }

  @override
  void cancelDownload(int pistaId) {
    _downloadService.cancelDownload(pistaId);
  }
}
