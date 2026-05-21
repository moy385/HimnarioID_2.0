import 'dart:async';

import 'package:bonsoir/bonsoir.dart' hide BonsoirService;
import 'package:logging/logging.dart';

import 'domain/bonsoir_discovered_service.dart';

/// Servicio de descubrimiento mDNS vía Bonsoir.
///
/// Escanea servicios `_himnario._tcp` en la red local y emite
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
      _discovery = BonsoirDiscovery(
        type: '_himnario._tcp',
        printLogs: true,
      );
      await _discovery!.initialize();
      _log.info('BonsoirDiscovery inicializado');

      // IMPORTANTE: Escuchar eventos ANTES de start()
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
      // 🔴 NUEVO: Manejar FoundEvent y resolver el servicio
      case BonsoirDiscoveryServiceFoundEvent(service: final service):
        _log.info('Servicio ENCONTRADO: ${service.name} — resolviendo...');
        if (_discovery != null) {
          service.resolve(_discovery!.serviceResolver);
        }
        break;

      case BonsoirDiscoveryServiceResolvedEvent(service: final service):
        _log.info('Servicio RESUELTO: ${service.name} en ${service.host}:${service.port}');
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
        break;

      case BonsoirDiscoveryServiceLostEvent(service: final service):
        _log.info('Servicio perdido: ${service.name}');
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
        break;

      default:
        _log.fine('Evento Bonsoir ignorado: ${event.runtimeType}');
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
