# 🤖 Prompt de Refactorización Estricta: Migración de Bonsoir a NSD para mDNS en Escritorio (Windows/Linux)

## 🎯 Objetivo
Reemplazar la librería `bonsoir` por `nsd` (Network Service Discovery) en el proyecto Flutter para habilitar el soporte nativo de publicación de servicios mDNS en plataformas de escritorio (Windows y Linux), resolviendo el fallo silencioso actual causado por la falta de compatibilidad nativa de Bonsoir en Desktop.

---

## 🛠️ Paso 1: Actualización de Dependencias (`pubspec.yaml`)

**Instrucción:** Localiza el archivo `pubspec.yaml` en la raíz del proyecto. Elimina la dependencia `bonsoir` y añade `nsd`. 

**Modificación exacta:**
```yaml
dependencies:
  flutter:
    sdk: flutter
  grpc: ^5.1.0
  # ELIMINAR: bonsoir: ^6.1.0
  # AÑADIR:
  nsd: ^2.1.2

📂 Paso 2: Reemplazo del Servicio de Broadcast (mdns_broadcast_service.dart)
Instrucción: Elimina por completo el archivo actual bonsoir_broadcast_service.dart (o donde se encuentre la clase BonsoirBroadcastService). Crea un nuevo archivo en su lugar llamado mdns_broadcast_service.dart e implementa la clase MdnsBroadcastService utilizando la API de nsd.

Código fuente de reemplazo:
import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:nsd/nsd.dart';

class MdnsBroadcastService {
  final _log = Logger('MdnsBroadcastService');
  Registration? _registration;

  /// Inicia la publicación del servicio en la red local.
  Future<void> start({
    required String name,
    required int port,
    required String sessionId,
    required String displayName,
  }) async {
    if (_registration != null) {
      _log.warning('El servicio mDNS ya está registrado.');
      return;
    }
    
    try {
      // Configuración del servicio mDNS. 
      // NOTA: nsd requiere que los valores del mapa 'txt' se codifiquen como List<int> (bytes).
      final service = Service(
        name: name,
        type: '_himnario._tcp',
        port: port,
        txt: {
          'sessionId': utf8.encode(sessionId),
          'displayName': utf8.encode(displayName),
        },
      );
      
      // Registro y publicación en la red local (LAN)
      _registration = await register(service);
      
      _log.info(
        'mDNS iniciado exitosamente: ${_registration!.service.name} '
        '(_himnario._tcp) en puerto $port'
      );
    } catch (e) {
      _log.severe('Error crítico iniciando mDNS con nsd: $e');
      rethrow;
    }
  }

  /// Detiene el broadcast y libera el puerto de descubrimiento.
  Future<void> stop() async {
    if (_registration != null) {
      try {
        await unregister(_registration!);
        _registration = null;
        _log.info('mDNS detenido y desregistrado correctamente.');
      } catch (e) {
        _log.severe('Error al detener el servicio mDNS: $e');
      }
    }
  }
}

🏗️ Paso 3: Actualización del Orquestador (app_initializer.dart)
Instrucción: Modifica el archivo de inicialización de la app (orquestador de arranque). Reemplaza las instancias y llamadas de BonsoirBroadcastService por la nueva clase MdnsBroadcastService. Asegúrate de actualizar los tipos de datos de las propiedades estáticas o globales correspondientes.

Revisión del bloque de inicialización del servidor de despliegue:
// 1. Asegúrate de cambiar la declaración de la propiedad global/estática:
// Antes: BonsoirBroadcastService? _bonsoirBroadcast;
// Después:
MdnsBroadcastService? _mdnsBroadcast;

// 2. Modifica el método de inicialización para que coincida con esta lógica exacta:
static Future<void> _initDisplayServer([ProviderContainer? container]) async {
  // A. Iniciar servidor gRPC
  try {
    _displayServer = GrpcDisplayServer(
      displayName: 'Display Principal',
      port: GrpcDisplayServer.defaultPort,
      container: container,
    );

    await _displayServer!.start();
    _log.info('Servidor gRPC iniciado en puerto ${_displayServer!.port}');
  } catch (e) {
    _log.severe('Error al iniciar servidor gRPC: $e');
    return;
  }

  // B. Iniciar broadcast mDNS (Nativo para Windows y Linux usando nsd)
  if (_platform == TargetPlatform.windows || _platform == TargetPlatform.linux) {
    try {
      _mdnsBroadcast = MdnsBroadcastService();
      await _mdnsBroadcast!.start(
        name: 'HimnarioID-${_displayServer!.displayName}',
        port: _displayServer!.port,
        sessionId: _displayServer!.sessionId,
        displayName: _displayServer!.displayName,
      );
      _log.info('Broadcast mDNS (nsd) iniciado correctamente en la red local.');
    } catch (e) {
      _log.severe('Error al iniciar broadcast mDNS con nsd: $e');
      _log.warning(
        'El servidor gRPC está funcionando, pero el descubrimiento mDNS falló. '
        'Los clientes móviles requerirán conexión manual mediante dirección IP.',
      );
    }
  }
}

🧹 Paso 4: Tareas de Limpieza y Recompilación
Instrucción: Una vez aplicados los cambios de código, ejecuta de manera secuencial los siguientes comandos en la terminal integrada para limpiar la caché de dependencias antiguas de bonsoir e instalar el motor nativo de nsd:
flutter pub clean
flutter pub get