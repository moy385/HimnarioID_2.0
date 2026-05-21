import 'dart:async';

import 'package:bonsoir/bonsoir.dart' hide BonsoirService;
import 'package:logging/logging.dart';

import 'domain/bonsoir_discovered_service.dart';

/// Servicio de descubrimiento mDNS vía Bonsoir.
///
/// Escanea servicios `_himnario_grpc._tcp` en la red local y emite
/// [BonsoirDiscoveredService] cada vez que un servicio es descubierto
/// o eliminado.
class BonsoirService {
  final _log = Logger('BonsoirService');
  BonsoirDiscovery? _discovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _eventSubscription;
  final _serviceController = StreamController<BonsoirDiscoveredService>.broadcast();

  /// Stream de servicios descubiertos/eliminados.
  Stream<BonsoirDiscoveredService> get onServiceChanged => _serviceController.stream;

  /// Inicia el escaneo de servicios mDNS.
  Future<void> start() async {
    if (_discovery != null) return;
    try {
      _discovery = BonsoirDiscovery(type: '_himnario_grpc._tcp');
      await _discovery!.initialize();
      _log.info('BonsoirDiscovery inicializado');
      _eventSubscription = _discovery!.eventStream?.listen(_onDiscoveryEvent);
      await _discovery!.start();
      _log.info('BonsoirDiscovery iniciado');
    } catch (e) {
      _log.severe('Error iniciando BonsoirDiscovery: $e');
      rethrow;
    }
  }

  void _onDiscoveryEvent(BonsoirDiscoveryEvent event) {
    switch (event) {
      case BonsoirDiscoveryServiceResolvedEvent(service: final service):
        _serviceController.add(
          BonsoirDiscoveredService(
            name: service.name,
            ip: service.host ?? '0.0.0.0',
            port: service.port,
            attributes: Map<String, String>.from(service.attributes),
            isNew: true,
            isRemoved: false,
          ),
        );
      case BonsoirDiscoveryServiceLostEvent(service: final service):
        _serviceController.add(
          BonsoirDiscoveredService(
            name: service.name,
            ip: service.host ?? '0.0.0.0',
            port: service.port,
            attributes: Map<String, String>.from(service.attributes),
            isNew: false,
            isRemoved: true,
          ),
        );
      default:
        break;
    }
  }

  /// Detiene el escaneo de servicios.
  Future<void> stop() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    await _discovery?.stop();
    _discovery = null;
    _log.info('BonsoirDiscovery detenido');
  }

  /// Libera recursos.
  void dispose() {
    _serviceController.close();
  }
}
