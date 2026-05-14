import 'dart:async';

import 'package:logging/logging.dart';
import 'package:multicast_dns/multicast_dns.dart';

import 'connection_state.dart';

/// Servicio de descubrimiento mDNS para encontrar displays en la LAN.
///
/// Escanea el servicio `_himnario._tcp.local` y emite dispositivos encontrados
/// a través de un stream reactivo.
class MdnsDiscovery {
  static final _log = Logger('MdnsDiscovery');

  static const String _serviceType = '_himnario._tcp.local';
  static const Duration _searchDuration = Duration(seconds: 5);

  MDnsClient? _client;
  StreamSubscription<PtrResourceRecord>? _ptrSubscription;
  final StreamController<DeviceInfo> _deviceController =
      StreamController<DeviceInfo>.broadcast();

  bool _isRunning = false;

  /// Stream de dispositivos descubiertos en la red.
  Stream<DeviceInfo> get onDeviceDiscovered => _deviceController.stream;

  /// Indica si el descubrimiento está activo.
  bool get isRunning => _isRunning;

  /// Inicia el escaneo de dispositivos mDNS en la LAN.
  Future<void> startDiscovery() async {
    if (_isRunning) {
      _log.warning('El descubrimiento ya está en ejecución.');
      return;
    }

    _isRunning = true;

    try {
      _client = MDnsClient();
      await _client!.start();

      _log.info('Iniciando descubrimiento mDNS para $_serviceType...');

      // 1. Buscar PTR records para el tipo de servicio
      _ptrSubscription = _client!
          .lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer(_serviceType),
      )
          .listen((ptrRecord) {
        _log.info('Servicio encontrado: ${ptrRecord.domainName}');

        // 2. Para cada instancia, resolver SRV record
        _resolveServiceInstance(ptrRecord.domainName);
      });

      // Detener automáticamente después de un tiempo
      await Future.delayed(_searchDuration);
    } catch (e) {
      _log.severe('Error en descubrimiento mDNS: $e');
    } finally {
      await stopDiscovery();
    }
  }

  /// Resuelve una instancia de servicio (SRV + Address).
  Future<void> _resolveServiceInstance(String instanceName) async {
    try {
      // Resolver SRV record para obtener target y puerto
      final srvRecords = await _client!
          .lookup<SrvResourceRecord>(
            ResourceRecordQuery.service(instanceName),
          )
          .toList();

      for (final srv in srvRecords) {
        _log.info('SRV: target=${srv.target}, port=${srv.port}');

        // Resolver dirección IP del target
        final ipRecords = await _client!
            .lookup<IPAddressResourceRecord>(
              ResourceRecordQuery.addressIPv4(srv.target),
            )
            .toList();

        if (ipRecords.isEmpty) {
          // Intentar con IPv6
          final ipv6Records = await _client!
              .lookup<IPAddressResourceRecord>(
                ResourceRecordQuery.addressIPv6(srv.target),
              )
              .toList();
          ipRecords.addAll(ipv6Records);
        }

        final deviceName = instanceName.contains('.')
            ? instanceName.substring(0, instanceName.indexOf('.'))
            : instanceName;

        for (final ipRecord in ipRecords) {
          final device = DeviceInfo(
            name: deviceName,
            ip: ipRecord.address.address,
            port: srv.port,
          );
          _log.info('Dispositivo descubierto: $device');
          _deviceController.add(device);
        }
      }
    } catch (e) {
      _log.warning('Error al resolver instancia $instanceName: $e');
    }
  }

  /// Realiza un escaneo único y retorna la lista de dispositivos encontrados.
  Future<List<DeviceInfo>> discoverDevices() async {
    final devices = <DeviceInfo>[];
    final subscription = onDeviceDiscovered.listen((device) {
      devices.add(device);
    });

    await startDiscovery();

    // Dar tiempo para recoger resultados
    await Future.delayed(_searchDuration);

    await subscription.cancel();
    return devices;
  }

  /// Detiene el descubrimiento y libera recursos.
  Future<void> stopDiscovery() async {
    _isRunning = false;
    await _ptrSubscription?.cancel();
    _ptrSubscription = null;
    _client?.stop();
    _client = null;
    _log.info('Descubrimiento mDNS detenido.');
  }

  /// Libera todos los recursos.
  void dispose() {
    _deviceController.close();
  }
}
