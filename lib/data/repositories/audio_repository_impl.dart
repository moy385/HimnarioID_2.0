import 'package:logging/logging.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/pista_audio.dart';
import '../../domain/repositories/audio_repository.dart';
import '../datasources/local/audio_local_datasource.dart';

/// Implementación del repositorio de audio.
///
/// Usa [AudioLocalDataSource] para la reproducción real.
/// Los himnos se buscan en assets/audio/{himnoId}.mp3 de forma sintética.
class AudioRepositoryImpl implements AudioRepository {
  static final _log = Logger('AudioRepositoryImpl');

  final AudioLocalDataSource _dataSource;

  /// Cache de pistas de audio para acceso rápido.
  final Map<int, PistaAudio> _pistaCache = {};

  AudioRepositoryImpl({AudioLocalDataSource? dataSource})
      : _dataSource = dataSource ?? AudioLocalDataSource();

  @override
  Future<List<PistaAudio>> getByHimno(int himnoId) async {
    try {
      // Búsqueda sintética: asume assets/audio/{himnoId}.mp3
      final pista = PistaAudio(
        id: himnoId,
        himnoId: himnoId,
        rutaArchivo: 'audio/$himnoId.mp3',
        descripcion: 'Pista principal',
        formato: 'mp3',
      );

      _pistaCache[himnoId] = pista;
      _log.fine('Pista encontrada para himno $himnoId: $pista');
      return [pista];
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

      await _dataSource.playFromAsset(pista.rutaArchivo);
      _log.info('Reproduciendo pista $pistaId: ${pista.rutaArchivo}');
    } on AudioFailure {
      rethrow;
    } catch (e) {
      _log.severe('Error al reproducir pista $pistaId: $e');
      throw AudioFailure('Error al reproducir audio: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _dataSource.stop();
      _log.info('Reproducción detenida.');
    } catch (e) {
      _log.severe('Error al detener audio: $e');
      throw AudioFailure('Error al detener la reproducción: $e');
    }
  }
}
