import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:logging/logging.dart';

/// DataSource local para reproducción de audio.
///
/// Encapsula la implementación con [audioplayers] para reproducir
/// pistas desde assets o desde el sistema de archivos.
class AudioLocalDataSource {
  static final _log = Logger('AudioLocalDataSource');

  final AudioPlayer _player;

  /// Callback que se invoca cuando la reproducción finaliza.
  void Function()? onCompletion;

  AudioLocalDataSource({AudioPlayer? player})
      : _player = player ?? AudioPlayer() {
    _player.onPlayerComplete.listen((_) {
      _log.fine('Reproducción completada.');
      onCompletion?.call();
    });
  }

  /// Indica si hay una reproducción en curso.
  bool get isPlaying => _player.state == PlayerState.playing;

  /// Reproduce un archivo desde la carpeta de assets.
  ///
  /// [assetPath] debe ser una ruta relativa a assets/, ej: "audio/001.mp3".
  Future<void> playFromAsset(String assetPath) async {
    try {
      _log.info('Reproduciendo desde asset: $assetPath');
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      _log.severe('Error al reproducir asset $assetPath: $e');
      throw const AudioException(
        'Error al reproducir audio desde asset',
      );
    }
  }

  /// Reproduce un archivo desde el sistema de archivos.
  ///
  /// [filePath] debe ser una ruta absoluta al archivo.
  Future<void> playFromFile(String filePath) async {
    try {
      String resolvedPath = filePath;
      // Si el archivo no existe, intentar con nombre sanitizado
      if (!File(resolvedPath).existsSync()) {
        final dir = Directory(resolvedPath).parent;
        final fileName = resolvedPath.split('/').last;
        final sanitized = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
        final altPath = '${dir.path}/$sanitized';
        if (File(altPath).existsSync()) {
          resolvedPath = altPath;
          _log.info('Usando ruta sanitizada: $resolvedPath');
        }
      }

      _log.info('Reproduciendo desde archivo: $resolvedPath');
      await _player.play(DeviceFileSource(resolvedPath));
    } catch (e) {
      _log.severe('Error al reproducir archivo $filePath: $e');
      throw AudioException(
        'Error al reproducir audio desde archivo: $filePath',
      );
    }
  }

  /// Detiene la reproducción actual.
  Future<void> stop() async {
    try {
      await _player.stop();
      _log.fine('Reproducción detenida.');
    } catch (e) {
      _log.severe('Error al detener audio: $e');
      throw const AudioException('Error al detener la reproducción');
    }
  }

  /// Libera los recursos del reproductor.
  Future<void> dispose() async {
    await _player.dispose();
    _log.fine('Recursos de audio liberados.');
  }
}

/// Excepción específica para errores de audio.
class AudioException implements Exception {
  final String message;

  const AudioException(this.message);

  @override
  String toString() => 'AudioException: $message';
}
