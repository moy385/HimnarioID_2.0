import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart';

typedef DownloadProgressCallback = void Function(double progress);

/// Servicio para descargar pistas de audio desde URLs remotas.
///
/// Maneja descargas progresivas con soporte de cancelación,
/// almacenamiento en el directorio de documentos de la app,
/// y verificación de existencia de archivos descargados.
class AudioDownloadService {
  static final _log = Logger('AudioDownloadService');
  final Map<int, bool> _cancellationTokens = {};

  /// Descarga una pista de audio desde [url] y la guarda localmente.
  ///
  /// [pistaId] identifica la pista para propósitos de cancelación.
  /// [himnoId] y [fileName] determinan la ruta de destino:
  /// `<appDocDir>/audio/<himnoId>/<fileName>`.
  ///
  /// [onProgress] se invoca con un valor entre 0.0 y 1.0.
  ///
  /// Retorna la ruta absoluta del archivo descargado.
  ///
  /// Lanza [Exception] si la descarga falla o es cancelada.
  Future<String> downloadPista({
    required int pistaId,
    required String url,
    required int himnoId,
    required String fileName,
    DownloadProgressCallback? onProgress,
  }) async {
    _cancellationTokens[pistaId] = false;

    final appDir = await getApplicationDocumentsDirectory();
    final destDir = Directory('${appDir.path}/audio/$himnoId');
    if (!await destDir.exists()) {
      await destDir.create(recursive: true);
    }
    final localPath = '${destDir.path}/$fileName';

    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final totalBytes = response.contentLength;
      int receivedBytes = 0;
      final file = File(localPath);
      final sink = file.openWrite();

      await for (final chunk in response) {
        if (_cancellationTokens[pistaId] == true) {
          await sink.close();
          await file.delete();
          throw Exception('Descarga cancelada');
        }
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes != -1 && onProgress != null) {
          onProgress(receivedBytes / totalBytes);
        }
      }
      await sink.close();
      _log.info('Pista $pistaId descargada: $localPath');
      return localPath;
    } finally {
      client.close();
    }
  }

  /// Cancela una descarga en curso identificada por [pistaId].
  void cancelDownload(int pistaId) {
    _cancellationTokens[pistaId] = true;
  }

  /// Verifica si un archivo ya existe en la ruta [localPath].
  Future<bool> isDownloaded(String localPath) async {
    final file = File(localPath);
    return await file.exists();
  }

  /// Elimina el archivo en [path] si existe.
  Future<void> deleteLocalFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      _log.info('Archivo eliminado: $path');
    }
  }
}
