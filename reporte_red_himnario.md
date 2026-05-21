# Reporte de Depuración — Publicación mDNS

## Dependencias de Red

```yaml
  # Comunicación LAN (gRPC + mDNS)
  grpc: ^5.1.0
  bonsoir: ^6.1.0
```

## Implementación del Servidor gRPC

```dart
/// Inicia el servidor gRPC escuchando en todas las interfaces.
///
/// Intenta puertos desde [defaultPort] hasta [defaultPort + 9] (50051-50060)
/// en caso de que el puerto esté ocupado.
Future<void> start() async {
  if (_isRunning) {
    _log.warning('El servidor ya está en ejecución.');
    return;
  }

  final maxAttempts = 10;
  int lastError = 0;

  for (int i = 0; i < maxAttempts; i++) {
    final tryPort = defaultPort + i;
    try {
      _server = Server.create(
        services: [this],
        keepAliveOptions: ServerKeepAliveOptions(
          minIntervalBetweenPingsWithoutData: Duration(seconds: 10),
          maxBadPings: 3,
        ),
      );
      await _server!.serve(
        address: InternetAddress.anyIPv4,
        port: tryPort,
      );
      _actualPort = tryPort;
      _isRunning = true;
      _log.info(
        'Servidor gRPC iniciado en 0.0.0.0:$tryPort '
        '(displayName: $displayName, sessionId: $sessionId)',
      );
      return;
    } catch (e) {
      lastError = tryPort;
      _log.warning('Puerto $tryPort no disponible ($e), intentando siguiente...');
      _server = null;
    }
  }

  _log.severe(
    'No se pudo iniciar servidor en ningún puerto entre '
    '$defaultPort-${defaultPort + maxAttempts - 1}. '
    'Último error: puerto $lastError',
  );
  throw Exception(
    'No hay puertos disponibles en rango '
    '$defaultPort-${defaultPort + maxAttempts - 1}',
  );
}
```

## Implementación del mDNS / Broadcast

### Capa 1: Servicio de broadcast Bonsoir

```dart
class BonsoirBroadcastService {
  final _log = Logger('BonsoirBroadcastService');
  BonsoirBroadcast? _broadcast;
  StreamSubscription<BonsoirBroadcastEvent>? _eventSubscription;

  /// Inicia la publicación del servicio.
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
        type: '_himnario._tcp',
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
        'BonsoirBroadcast iniciado: $name (_himnario._tcp) en puerto $port',
      );
    } catch (e) {
      _log.severe('Error iniciando BonsoirBroadcast: $e');
      rethrow;
    }
  }

  Future<void> stop() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    await _broadcast?.stop();
    _broadcast = null;
    _log.info('BonsoirBroadcast detenido');
  }
}
```

### Capa 2: Orquestación desde AppInitializer

```dart
/// Inicia el servidor gRPC para modo Display.
static Future<void> _initDisplayServer([ProviderContainer? container]) async {
  // 1. Iniciar servidor gRPC
  try {
    _displayServer = GrpcDisplayServer(
      displayName: 'Display Principal',
      port: GrpcDisplayServer.defaultPort,
      container: container,
    );

    // ... configuración de callbacks ...

    await _displayServer!.start();
    _log.info('Servidor gRPC iniciado en puerto ${_displayServer!.port}');
  } catch (e) {
    _log.severe('Error al iniciar servidor gRPC: $e');
    return;
  }

  // 2. Iniciar broadcast Bonsoir (solo Windows/Linux)
  if (_platform == TargetPlatform.windows ||
      _platform == TargetPlatform.linux) {
    try {
      _bonsoirBroadcast = BonsoirBroadcastService();
      await _bonsoirBroadcast!.start(
        name: 'HimnarioID-${_displayServer!.displayName}',
        port: _displayServer!.port,
        sessionId: _displayServer!.sessionId,
        displayName: _displayServer!.displayName,
      );
      _log.info('Broadcast Bonsoir iniciado correctamente.');
    } catch (e) {
      _log.severe('Error al iniciar broadcast Bonsoir: $e');
      _log.warning(
        'El servidor gRPC está funcionando, pero el broadcast mDNS '
        'falló. Usa conexión manual con la IP de esta máquina.',
      );
    }
  }
}
```

## Captura de Logs (Try/Catch)

### Try/Catch #1 — Servidor gRPC (app_initializer.dart:132-184)

```dart
    try {
      _displayServer = GrpcDisplayServer(
        displayName: 'Display Principal',
        port: GrpcDisplayServer.defaultPort,
        container: container,
      );

      // ... callbacks ...

      await _displayServer!.start();
      _log.info('Servidor gRPC iniciado en puerto ${_displayServer!.port}');
    } catch (e) {
      _log.severe('Error al iniciar servidor gRPC: $e');
      // No relanzar — la app puede funcionar sin servidor gRPC
      return;
    }
```

### Try/Catch #2 — Broadcast Bonsoir (app_initializer.dart:190-205)

```dart
    try {
      _bonsoirBroadcast = BonsoirBroadcastService();
      await _bonsoirBroadcast!.start(
        name: 'HimnarioID-${_displayServer!.displayName}',
        port: _displayServer!.port,
        sessionId: _displayServer!.sessionId,
        displayName: _displayServer!.displayName,
      );
      _log.info('Broadcast Bonsoir iniciado correctamente.');
    } catch (e) {
      _log.severe('Error al iniciar broadcast Bonsoir: $e');
      _log.warning(
        'El servidor gRPC está funcionando, pero el broadcast mDNS '
        'falló. Usa conexión manual con la IP de esta máquina.',
      );
    }
```

### Try/Catch #3 — Broadcast Bonsoir interno (bonsoir_broadcast_service.dart:28-53)

```dart
    try {
      final service = BonsoirService(
        name: name,
        type: '_himnario._tcp',
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
        'BonsoirBroadcast iniciado: $name (_himnario._tcp) en puerto $port',
      );
    } catch (e) {
      _log.severe('Error iniciando BonsoirBroadcast: $e');
      rethrow;
    }
```
