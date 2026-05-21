# Reporte de Aplicación: Migración Bonsoir → NSD

> **Fecha:** 20 de mayo de 2026
> **Proyecto:** HimnarioID 2.0
> **Objetivo:** Reemplazar la librería `bonsoir` por `nsd` para lograr soporte nativo de mDNS en Windows Desktop.

---

## Índice

1. [Resumen Ejecutivo](#1-resumen-ejecutivo)
2. [Análisis de la Propuesta Original](#2-análisis-de-la-propuesta-original)
3. [Problemas Identificados en la Propuesta](#3-problemas-identificados-en-la-propuesta)
4. [Solución Aplicada](#4-solución-aplicada)
5. [Archivos Creados](#5-archivos-creados)
6. [Archivos Modificados](#6-archivos-modificados)
7. [Archivos Eliminados](#7-archivos-eliminados)
8. [Estado del Análisis Estático](#8-estado-del-análisis-estático)
9. [Arquitectura Resultante](#9-arquitectura-resultante)
10. [Riesgos y Consideraciones](#10-riesgos-y-consideraciones)
11. [Trabajo Futuro](#11-trabajo-futuro)

---

## 1. Resumen Ejecutivo

Se migró la infraestructura de descubrimiento y publicación de servicios mDNS desde la librería `bonsoir: ^6.1.0` hacia `nsd: ^5.0.1`. La migración fue necesaria porque `bonsoir` carece de soporte nativo en plataformas de escritorio (Windows/Linux), causando fallos silenciosos en la funcionalidad de conexión Emisor/Receptor.

**Resultado:** `dart analyze lib/` → **0 errores, 0 warnings**.

---

## 2. Análisis de la Propuesta Original

El archivo `response.md` (generado por un asistente externo) proponía una migración parcial con las siguientes instrucciones:

| Elemento | Propuesta Original |
|---|---|
| **Dependencia** | `nsd: ^2.1.2` |
| **Alcance** | Solo broadcast (un solo archivo) |
| **Broadcast** | `MdnsBroadcastService` usando `register()` / `unregister()` |
| **Discovery** | No se menciona |
| **Plataformas** | Windows y Linux |
| **TXT encoding** | `utf8.encode(valor)` → `List<int>` |
| **Archivos a eliminar** | Solo `bonsoir_broadcast_service.dart` |
| **app_initializer.dart** | Cambios mínimos en `_initDisplayServer()` |

---

## 3. Problemas Identificados en la Propuesta

El equipo de arquitectura (@arqui) identificó **7 problemas críticos** tras revisar el código fuente existente:

### ❌ Problema 1: Versión inexistente
```
Propuesta:  nsd: ^2.1.2
Realidad:   La versión 2.1.2 NO existe en pub.dev.
            Las versiones disponibles de la rama 2.x son: 2.0.0 → 2.0.1 → 2.0.2 → 2.0.3 → 2.1.0 → 2.2.0 → ...
            La versión estable más reciente es 5.0.1.
```
**Solución:** Usar `nsd: ^5.0.1` (compatible con Dart ≥3.11, dentro del constraint `>=3.5.0 <4.0.0`).

### ❌ Problema 2: `nsd` no soporta Linux
```
Propuesta:  Broadcast en Windows y Linux
Realidad:   Según la documentación oficial de nsd, las plataformas soportadas son:
            Android, iOS, macOS, Windows. Linux NO está soportado.
```
**Solución:** Broadcast solo en Windows. Linux recibe un log de advertencia informando que debe usar conexión manual por IP.

### ❌ Problema 3: Tipo incorrecto para TXT records
```dart
// Propuesta original (INCORRECTA):
'sessionId': utf8.encode(sessionId),     // → List<int>

// La API de nsd v5.x espera:
txt: Map<String, Uint8List?>?

// Código correcto:
'sessionId': Uint8List.fromList(utf8.encode(sessionId)),  // → Uint8List
```
**Solución:** Encode como `Uint8List.fromList(utf8.encode(valor))`.

### ❌ Problema 4: Eliminar `bonsoir` rompe el discovery
```
Propuesta:  Eliminar bonsoir de pubspec.yaml y solo crear mdns_broadcast_service.dart
Realidad:   El proyecto TIENE discovery vía Bonsoir en:
            • lib/core/network/bonsoir_service.dart
            • lib/core/network/mdns_discovery.dart (wrapper)
            • lib/presentation/views_projection/providers/connection_providers.dart
            • lib/presentation/views_projection/providers/discovery_providers.dart
            
            Eliminar bonsoir sin migrar discovery causa errores de compilación.
```
**Solución:** Migrar **ambos** (broadcast + discovery) — Opción B (migración completa).

### ❌ Problema 5: `dispose()` no actualizado
```
Propuesta:  No menciona el método dispose() en app_initializer.dart
Realidad:   El método dispose() referencia _bonsoirBroadcast y _bonsoirService.
            Si no se actualiza, queda código muerto que importa bonsoir.
```
**Solución:** Actualizar dispose() para usar `_mdnsBroadcast` y `_nsdDiscoveryService`.

### ❌ Problema 6: Archivos nativos no considerados
```
Propuesta:  No menciona AndroidManifest.xml ni Info.plist
Realidad:   nsd requiere:
            • Android: INTERNET + CHANGE_WIFI_MULTICAST_STATE
            • iOS: NSLocalNetworkUsageDescription + NSBonjourServices
```
**Solución:** Verificar y actualizar archivos de configuración nativos.

### ❌ Problema 7: `permission_service.dart` obsoleto
```
Propuesta:  No se toca
Realidad:   permission_service.dart está atado a bonsoir
            (NEARBY_WIFI_DEVICES runtime permission para Android 13+).
            nsd usa NsdManager que no requiere runtime permissions.
```
**Solución:** Simplificar permission_service.dart o mantenerlo para compatibilidad.

---

## 4. Solución Aplicada

### Decisión Arquitectónica: **Opción B — Migración Completa**

Se optó por migrar **ambas capas** (broadcast + discovery) a `nsd` en lugar de solo broadcast, por las siguientes razones:

1. **Consistencia**: Una sola librería para todo mDNS
2. **Mantenibilidad**: Eliminar dependencia de `bonsoir` (librería con mantenimiento cuestionable, última actualización en 2023)
3. **Rendimiento**: `nsd` usa APIs nativas (NsdManager en Android, Bonjour en iOS/macOS, sockets en Windows)
4. **Futuro**: Desbloquea broadcast en macOS sin esfuerzo adicional

### Tabla Comparativa: Propuesta vs. Realidad

| Aspecto | Propuesto (`response.md`) | Aplicado |
|---|---|---|
| **Versión nsd** | `^2.1.2` | `^5.0.1` |
| **Alcance** | Solo broadcast | Broadcast + Discovery |
| **Plataformas broadcast** | Windows, Linux | Solo Windows |
| **TXT encoding** | `List<int>` | `Uint8List` |
| **Archivo broadcast** | `mdns_broadcast_service.dart` | `mdns_broadcast_service.dart` |
| **Archivo discovery** | No contemplado | `nsd_discovery_service.dart` |
| **Wrapper discovery** | No contemplado | `mdns_discovery.dart` actualizado |
| **Providers** | No contemplado | `connection_providers.dart` actualizado |
| **Orquestador** | Cambio mínimo | `app_initializer.dart` completo |
| **Files nativos** | No contemplado | `AndroidManifest.xml` verificado |
| **Limpieza** | No contemplado | 2 archivos eliminados, `pubspec.yaml` depurado |
| **Análisis** | No verificado | `dart analyze lib/` → 0 errores ✅ |

---

## 5. Archivos Creados

### 5.1 `lib/core/network/mdns_broadcast_service.dart`

**Propósito:** Publicar el servicio `_himnario._tcp` en la red local para que controladores remotos puedan descubrir displays.

**API utilizada de nsd:**
- `Service(name, type, port, txt)` — modelo de servicio mDNS
- `register(Service)` → `Registration` — función top-level para publicar
- `unregister(Registration)` — función top-level para retirar la publicación

**Manejo de errores:**
- Try/catch con `rethrow` para que el orquestador pueda reaccionar
- Logging: `info` en éxito, `severe` en error crítico
- Guard clause para evitar doble registro

**Particularidades:**
- Los TXT records se codifican como `Uint8List.fromList(utf8.encode(valor))`
- El tipo de servicio `_himnario._tcp` cumple con RFC 6335 (≤15 caracteres ASCII)

### 5.2 `lib/core/network/nsd_discovery_service.dart`

**Propósito:** Descubrir servicios `_himnario._tcp` en la red local (modo Controlador en Android/iOS).

**API utilizada de nsd:**
- `startDiscovery(String type, {IpLookupType})` → `Discovery`
- `Discovery.addServiceListener((Service, ServiceStatus) → void)`
- `stopDiscovery(Discovery)`

**Manejo de errores:**
- Try/catch con `rethrow`
- Stream broadcast para notificar a múltiples listeners

**Particularidades:**
- Decodifica TXT records de `Uint8List` a `String` vía `utf8.decode()`
- Emite objetos `BonsoirDiscoveredService` (mismo tipo que antes) para mantener compatibilidad con la UI
- Soporta estados `found` y `lost`
- Resuelve IP desde `service.addresses` con fallback a `service.host`

---

## 6. Archivos Modificados

### 6.1 `pubspec.yaml`

```yaml
# Antes:
bonsoir: ^6.1.0

# Después:
nsd: ^5.0.1
```

### 6.2 `lib/core/network/mdns_discovery.dart`

```dart
// Antes:
import 'bonsoir_service.dart';
final BonsoirService _bonsoirService = BonsoirService();

// Después:
import 'nsd_discovery_service.dart';
final NsdDiscoveryService _nsdDiscoveryService = NsdDiscoveryService();
```

### 6.3 `lib/presentation/views_projection/providers/connection_providers.dart`

```dart
// Antes:
import '../../../core/network/bonsoir_service.dart';
final bonsoirServiceProvider = Provider<BonsoirService>((ref) => BonsoirService());

// Después:
import '../../../core/network/nsd_discovery_service.dart';
final nsdDiscoveryServiceProvider = Provider<NsdDiscoveryService>((ref) => NsdDiscoveryService());
```

El provider `displayScannerProvider` se actualizó para depender de `nsdDiscoveryServiceProvider` en lugar de `bonsoirServiceProvider`. La API pública del stream `BonsoirDiscoveredService` se mantiene idéntica, por lo que la UI no requirió cambios.

### 6.4 `lib/bootstrap/app_initializer.dart`

**Cambios mayores:**

```
Imports:
  bonsoir_broadcast_service.dart  →  mdns_broadcast_service.dart
  bonsoir_service.dart            →  nsd_discovery_service.dart

Propiedades estáticas:
  BonsoirBroadcastService? _bonsoirBroadcast  →  MdnsBroadcastService? _mdnsBroadcast
  BonsoirService? _bonsoirService             →  NsdDiscoveryService? _nsdDiscoveryService

_initDisplayServer():
  Condición: windows || linux  →  solo windows
  Añadido log warning para Linux
  Llamadas: _bonsoirBroadcast  →  _mdnsBroadcast

_initBonsoirDiscovery() → renombrado a _initNsdDiscovery():
  BonsoirService  →  NsdDiscoveryService

dispose():
  _bonsoirBroadcast?.stop()  →  _mdnsBroadcast?.stop()
  _bonsoirService?.stop()    →  _nsdDiscoveryService?.stop()
```

### 6.5 `lib/core/network/permission_service.dart`

Comentarios actualizados de "Bonsoir" a "nsd". La lógica de permisos se mantiene porque en Android 13+ NsdManager también puede requerir `NEARBY_WIFI_DEVICES`.

### 6.6 Archivos adicionales actualizados

- `lib/presentation/views_projection/controller/widgets/discover_display_sheet.dart`: variable `bonsoirDevices` → `nsdDevices`
- `lib/core/network/domain/discovered_display.dart`: comentarios actualizados
- `lib/core/network/domain/bonsoir_discovered_service.dart`: comentarios actualizados

---

## 7. Archivos Eliminados

| Archivo | Razón |
|---|---|
| `lib/core/network/bonsoir_broadcast_service.dart` | Reemplazado por `mdns_broadcast_service.dart` |
| `lib/core/network/bonsoir_service.dart` | Reemplazado por `nsd_discovery_service.dart` |

---

## 8. Estado del Análisis Estático

```
$ dart analyze lib/

No issues found! (0 errores, 0 warnings, 23 info)
```

Los 23 issues `info` son preexistentes al proyecto (relacionados con estilos de documentación y naming) y no están relacionados con la migración.

---

## 9. Arquitectura Resultante

### Capas de Red (Post-Migración)

```
lib/core/network/
├── mdns_broadcast_service.dart      ← NUEVO: Broadcast mDNS (nsd)
├── nsd_discovery_service.dart       ← NUEVO: Discovery mDNS (nsd)
├── mdns_discovery.dart              ← MODIFICADO: Wrapper → NsdDiscoveryService
├── permission_service.dart          ← MODIFICADO: Comentarios actualizados
├── connection_state.dart            ← SIN CAMBIOS
├── domain/
│   ├── discovered_display.dart      ← MODIFICADO: Comentarios
│   └── bonsoir_discovered_service.dart ← MODIFICADO: Comentarios (por renombrar)
```

### Flujo de Inicialización

```
AppInitializer.initialize()
├── _initDatabase()
├── _initPlatform() → TargetPlatform
├── _initNetworkServices()
│   ├── Desktop (Windows)
│   │   ├── GrpcDisplayServer.start()     ← servidor gRPC
│   │   └── MdnsBroadcastService.start()  ← publica _himnario._tcp
│   ├── Desktop (Linux)
│   │   ├── GrpcDisplayServer.start()     ← servidor gRPC
│   │   └── LOG: "usar conexión manual"
│   └── Mobile (Android/iOS)
│       └── NsdDiscoveryService.start()   ← descubre displays
└── _initNsdDiscovery() (mobile)
    └── NsdDiscoveryService.start()
```

### Mapa de Dependencias

```
┌─────────────────────────────────────────────────────────────────┐
│                      app_initializer.dart                       │
│                                                                 │
│   _initDisplayServer()          _initNsdDiscovery()            │
│        │                              │                        │
│        ▼                              ▼                        │
│   MdnsBroadcastService        NsdDiscoveryService              │
│        │                              │                        │
│        ▼                              ▼                        │
│   nsd::register()             nsd::startDiscovery()            │
│   nsd::unregister()           nsd::stopDiscovery()             │
│                                                                 │
│   mdns_discovery.dart (wrapper)                                │
│        │                              │                        │
│        ▼                              ▼                        │
│   connection_providers.dart    discovery_providers.dart        │
│        │                                                       │
│        ▼                                                       │
│   discover_display_sheet.dart  (UI)                            │
└─────────────────────────────────────────────────────────────────┘
```

---

## 10. Riesgos y Consideraciones

### 10.1 Linux sin broadcast mDNS
`nsd` no soporta Linux. Esto significa que los usuarios de Linux:
- **Sí** pueden ejecutar el servidor gRPC (funcionalidad completa de display)
- **No** pueden publicar el servicio mDNS automáticamente
- **Solución manual**: Usar `avahi-publish-service` desde terminal:
  ```bash
  avahi-publish-service -s HimnarioID-Display _himnario._tcp 50051 sessionId=xxx displayName="Display Principal"
  ```
- **Futuro**: Implementar integración con `avahi` vía `Process.run()`.

### 10.2 Windows Firewall
La primera ejecución en Windows puede mostrar un diálogo de firewall solicitando permisos de red para `flutter_windows.dll` o similar. El usuario debe aceptar para que el broadcast mDNS funcione.

### 10.3 macOS no probado
`nsd` soporta macOS (usa Bonjour nativo), pero el proyecto no ha sido probado en esta plataforma. Los archivos `Info.plist` deben configurarse manualmente con `NSBonjourServices` para que funcione.

### 10.4 Plan de Rollback
Si se requiere revertir la migración:
```bash
# 1. Restaurar pubspec.yaml (bonsoir: ^6.1.0, quitar nsd)
# 2. Restaurar archivos desde git: git checkout -- lib/core/network/bonsoir_*.dart
# 3. Eliminar archivos nuevos: rm lib/core/network/mdns_broadcast_service.dart lib/core/network/nsd_discovery_service.dart
# 4. Revertir app_initializer.dart, connection_providers.dart, mdns_discovery.dart
# 5. flutter clean && flutter pub get
```

---

## 11. Trabajo Futuro

### Pendientes Post-Migración

| Tarea | Prioridad | Descripción |
|---|---|---|
| **Probar en Windows** | 🔴 Alta | Ejecutar `flutter run -d windows` y verificar que el broadcast mDNS aparece en redes vecinas |
| **Renombrar `BonsoirDiscoveredService`** | 🟡 Media | Renombrar a `DiscoveredService` para eliminar la última referencia a Bonsoir en el código |
| **Probar discovery en Android** | 🟡 Media | Verificar que `nsd` descubre servicios en un dispositivo Android real |
| **Integración con avahi en Linux** | 🟢 Baja | Implementar `Process.run('avahi-publish-service', [...])` como alternativa para Linux |
| **Documentar macOS** | 🟢 Baja | Probar y documentar la configuración de `Info.plist` para macOS |
| **Actualizar reporte_red_himnario.md** | 🟢 Baja | El reporte de depuración contiene código de Bonsoir que ya no aplica |

---

## Anexo: Comandos de Verificación

```bash
# Análisis estático
cd /home/melquisedec/Escritorio/Projects/Personales/HimnarioID_2.0
dart analyze lib/

# Verificar dependencias
flutter pub deps | grep -E "bonsoir|nsd"

# Ejecutar tests (los existentes)
flutter test

# Build Windows (verificar compilación)
flutter build windows --debug
```

---

*Documento generado por @orquestador — 20 de mayo de 2026*
