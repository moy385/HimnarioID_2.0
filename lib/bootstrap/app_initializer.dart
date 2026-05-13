import 'package:logging/logging.dart';

/// Inicializador de la aplicación.
/// Se encarga de configurar todos los servicios antes de que Flutter renderice.
class AppInitializer {
  static final _log = Logger('AppInitializer');

  /// Inicializa todos los servicios necesarios para la app.
  /// Debe llamarse antes de runApp().
  static Future<void> initialize() async {
    _log.info('Inicializando HimnarioID 2.0...');

    // 1. Configurar logging
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      // En producción, enviar a un archivo o servicio externo
      // ignore: avoid_print
      print('[${record.level.name}] ${record.loggerName}: ${record.message}');
    });

    // 2. Inicializar base de datos SQLite
    await _initDatabase();

    // 3. Configurar detección de plataforma
    await _initPlatform();

    // 4. Inicializar servicios de red (mDNS/gRPC)
    await _initNetworkServices();

    _log.info('Inicialización completada.');
  }

  static Future<void> _initDatabase() async {
    // TODO: Implementar inicialización de Drift/SQLite
    _log.info('Base de datos: Pendiente de implementación');
  }

  static Future<void> _initPlatform() async {
    // TODO: Detectar si es web, desktop o mobile
    _log.info('Plataforma: Pendiente de detección');
  }

  static Future<void> _initNetworkServices() async {
    // TODO: Inicializar mDNS y servidor/cliente gRPC
    _log.info('Servicios de red: Pendiente de implementación');
  }
}
