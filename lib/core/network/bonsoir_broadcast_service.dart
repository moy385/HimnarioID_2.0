import 'package:bonsoir/bonsoir.dart';
import 'package:logging/logging.dart';

/// Servicio de broadcast mDNS vía Bonsoir.
///
/// Publica un servicio `_himnario_grpc._tcp` en la red local para que
/// otros dispositivos puedan descubrirlo.
class BonsoirBroadcastService {
  final _log = Logger('BonsoirBroadcastService');
  BonsoirBroadcast? _broadcast;

  /// Inicia la publicación del servicio.
  ///
  /// [name] es el nombre visible del dispositivo.
  /// [port] es el puerto donde corre el servidor gRPC.
  /// [sessionId] es el ID único de sesión.
  /// [displayName] es el nombre del display configurado.
  Future<void> start({
    required String name,
    required int port,
    required String sessionId,
    required String displayName,
  }) async {
    if (_broadcast != null) return;
    try {
      final service = BonsoirService(
        name: name,
        type: '_himnario_grpc._tcp',
        port: port,
        attributes: {
          'sessionId': sessionId,
          'displayName': displayName,
        },
      );
      _broadcast = BonsoirBroadcast(service: service);
      await _broadcast!.initialize();
      await _broadcast!.start();
      _log.info(
        'BonsoirBroadcast iniciado: $name (_himnario_grpc._tcp) en puerto $port',
      );
    } catch (e) {
      _log.severe('Error iniciando BonsoirBroadcast: $e');
      rethrow;
    }
  }

  /// Detiene la publicación del servicio.
  Future<void> stop() async {
    await _broadcast?.stop();
    _broadcast = null;
    _log.info('BonsoirBroadcast detenido');
  }
}
