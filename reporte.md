# Reporte Completo — HimnarioID 2.0

> **Fechas:** 20–21 de mayo de 2026
> **Ramas involucradas:** `feature/conexion-lan-grpc` → `main` → `feature/flujo-emisor-receptor`

---

## Índice

1. [Resumen Ejecutivo](#1-resumen-ejecutivo)
2. [Fase 1: Migración Bonsoir → NSD](#2-fase-1-migración-bonsoir--nsd)
3. [Fase 2: Flujo Emisor/Receptor vía gRPC](#3-fase-2-flujo-emisorreceptor-vía-grpc)
4. [Agentes Participantes](#4-agentes-participantes)
5. [Archivos Creados](#5-archivos-creados)
6. [Archivos Modificados](#6-archivos-modificados)
7. [Archivos Eliminados](#7-archivos-eliminados)
8. [Errores y Bugs](#8-errores-y-bugs)
9. [Estado del Análisis Estático](#9-estado-del-análisis-estático)
10. [Arquitectura Resultante](#10-arquitectura-resultante)
11. [Pendientes](#11-pendientes)

---

## 1. Resumen Ejecutivo

Se completaron dos fases de trabajo en la infraestructura de red de HimnarioID 2.0:

| Fase | Objetivo | Estado |
|---|---|---|
| **Fase 1** | Migrar mDNS de Bonsoir a NSD para soporte nativo en Windows | ✅ Completado |
| **Fase 2** | Implementar flujo Emisor/Receptor: celular → control remoto, PC → display | ✅ Completado |

**Resultado final:** `dart analyze lib/` → **0 errores, 0 warnings**

---

## 2. Fase 1: Migración Bonsoir → NSD

### 2.1 Problema

La librería `bonsoir: ^6.1.0` no tiene soporte nativo en plataformas de escritorio (Windows/Linux), causando fallos silenciosos en el broadcast mDNS. La conexión LAN Emisor/Receptor no funcionaba en Windows.

### 2.2 Propuesta Original vs. Solución Aplicada

| Aspecto | Propuesto (`response.md`) | Aplicado | Razón |
|---|---|---|---|
| **Versión nsd** | `^2.1.2` | `^5.0.1` | La versión 2.1.2 no existe en pub.dev |
| **Alcance** | Solo broadcast | Broadcast + Discovery | Eliminar Bonsoir sin migrar discovery rompe 5 archivos |
| **Plataformas** | Windows + Linux | Solo Windows | `nsd` no soporta Linux |
| **TXT encoding** | `List<int>` | `Uint8List` | API de nsd v5.x espera `Uint8List` |
| **Limpieza** | No contemplada | 2 archivos eliminados | `bonsoir_broadcast_service.dart`, `bonsoir_service.dart` |

### 2.3 Cambios Realizados

| Archivo | Cambio |
|---|---|
| `pubspec.yaml` | `bonsoir: ^6.1.0` → `nsd: ^5.0.1` |
| `lib/core/network/mdns_broadcast_service.dart` | **Creado**: broadcast con `register(Service)` |
| `lib/core/network/nsd_discovery_service.dart` | **Creado**: discovery con `startDiscovery()` + `addServiceListener()` |
| `lib/core/network/mdns_discovery.dart` | Wrapper actualizado a `NsdDiscoveryService` |
| `lib/presentation/views_projection/providers/connection_providers.dart` | Provider migrado |
| `lib/bootstrap/app_initializer.dart` | Broadcast solo Windows, Linux log warning |
| `lib/core/network/permission_service.dart` | Comentarios actualizados |
| `lib/presentation/views_projection/controller/widgets/discover_display_sheet.dart` | Naming actualizado |
| `lib/core/network/bonsoir_broadcast_service.dart` | **Eliminado** |
| `lib/core/network/bonsoir_service.dart` | **Eliminado** |

---

## 3. Fase 2: Flujo Emisor/Receptor vía gRPC

### 3.1 Problema

Una vez establecida la conexión LAN (mDNS + gRPC), no existía el flujo de datos reactivo entre el controlador (celular) y el display (PC). El celular no podía enviar himnos completos ni controlar remotamente la proyección.

### 3.2 Plan Original vs. Solución Aplicada

El archivo `pasos.md` contenía el plan de arquitectura. @arqui identificó **7 problemas**:

| # | Problema | Corrección |
|---|---|---|
| 1 | `SetBackground` como RPC redundante | No crear, usar `SendCommand` existente |
| 2 | Asumía que `RemoteControlPanel` no existe | Usar `MinimalControlScreen` existente |
| 3 | `SendHymnContent` no especificaba cómo inyectar en `liveControlProvider` | Callback `onLoadHymnContent` |
| 4 | Fondos: celular usa datos locales, no remotos | `remoteBackgroundsProvider` + `GetAvailableBackgrounds` |
| 5 | No había callback de "cliente conectado" | `onClientConnected` en handshake |
| 6 | Flujo local vs remoto no coexistían | Ambos flujos separados |
| 7 | No auto-asignaba rol `emitter` al conectar | `connectionRoleProvider` en conexión exitosa |

### 3.3 Nuevos RPCs en Proto

```protobuf
rpc SendHymnContent (HymnPayload) returns (CommandResponse);
rpc GetAvailableBackgrounds (Empty) returns (BackgroundList);
```

**Mensajes creados:** `HymnPayload`, `StanzaPayload`, `BackgroundInfo`, `BackgroundList`

### 3.4 Cambios Realizados

| Archivo | Cambio |
|---|---|
| `proto/hymn_control.proto` | +2 RPCs, +4 mensajes |
| `lib/proto/generated/*` | 4 stubs regenerados con protoc |
| `lib/data/datasources/remote/grpc_display_server.dart` | +sendHymnContent, +getAvailableBackgrounds, +onClientConnected, +onLoadHymnContent, fix crash, fix resource leak |
| `lib/data/datasources/remote/grpc_control_datasource.dart` | +sendHymnContent, +getAvailableBackgrounds |
| `lib/bootstrap/app_initializer.dart` | +onClientConnected, +onLoadHymnContent |
| `lib/presentation/views_projection/providers/connection_providers.dart` | +remoteBackgroundsProvider |
| `lib/presentation/views_projection/display/receptor_binding.dart` | +isClientConnectedProvider |
| `lib/presentation/views_projection/controller/minimal_control_screen.dart` | Envío gRPC, fix bug carga inicial |
| `lib/presentation/views_projection/controller/widgets/discover_display_sheet.dart` | Auto-asignación rol emitter, fondos remotos |
| `lib/presentation/shared_widgets/control_sheets.dart` | Sección fondos remotos con FilterChips |

---

## 4. Agentes Participantes

| Agente | Rol en Fase 1 | Rol en Fase 2 |
|---|---|---|
| **@arqui** | Análisis de `response.md`, plan de migración | Evaluación de `pasos.md`, plan de 8 pasos, verificación post-implementación |
| **@curie** | — | Investigación de APIs: gRPC proto, nsd Android, Riverpod + streaming, multi-ventana |
| **@dev** | Implementación de la migración | Backend: proto, stubs, servidor, cliente, auto-proyección |
| **@design** | — | UI: MinimalControlScreen, navegación condicional, fondos remotos |
| **@orquestador** | Coordinación, reportes, merge | Coordinación, merge, corrección de bugs críticos, reporte |

---

## 5. Archivos Creados

| Archivo | Fase | Propósito |
|---|---|---|
| `lib/core/network/mdns_broadcast_service.dart` | 1 | Broadcast mDNS con nsd |
| `lib/core/network/nsd_discovery_service.dart` | 1 | Discovery mDNS con nsd |
| `reporte_red_himnario.md` | 1 | Extractos de código para depuración |
| `aplicacion.md` | 1+2 | Reporte completo de aplicación (migración + flujo) |

---

## 6. Archivos Modificados

| Archivo | Fase(s) |
|---|---|
| `pubspec.yaml` | 1, 2 |
| `lib/bootstrap/app_initializer.dart` | 1, 2 |
| `lib/core/network/mdns_discovery.dart` | 1 |
| `lib/core/network/permission_service.dart` | 1 |
| `lib/core/network/domain/bonsoir_discovered_service.dart` | 1 |
| `lib/core/network/domain/discovered_display.dart` | 1 |
| `lib/presentation/views_projection/providers/connection_providers.dart` | 1, 2 |
| `lib/presentation/views_projection/controller/widgets/discover_display_sheet.dart` | 1, 2 |
| `lib/presentation/views_projection/display/receptor_binding.dart` | 2 |
| `lib/presentation/views_projection/controller/minimal_control_screen.dart` | 2 |
| `lib/presentation/shared_widgets/control_sheets.dart` | 2 |
| `lib/data/datasources/remote/grpc_display_server.dart` | 2 |
| `lib/data/datasources/remote/grpc_control_datasource.dart` | 2 |
| `proto/hymn_control.proto` | 2 |
| `lib/proto/generated/hymn_control.pb.dart` | 2 |
| `lib/proto/generated/hymn_control.pbenum.dart` | 2 |
| `lib/proto/generated/hymn_control.pbgrpc.dart` | 2 |
| `lib/proto/generated/hymn_control.pbjson.dart` | 2 |
| `lib/proto/generated/hymn_control.pbserver.dart` | 2 |
| `doc/CONTEXTO_PROYECTO.md` | 1 |
| `doc/tareas_pendientes.md` | 1 |
| `macos/Flutter/GeneratedPluginRegistrant.swift` | 1 |
| `windows/flutter/generated_plugin_registrant.cc` | 1 |
| `windows/flutter/generated_plugins.cmake` | 1 |

---

## 7. Archivos Eliminados

| Archivo | Fase | Razón |
|---|---|---|
| `lib/core/network/bonsoir_broadcast_service.dart` | 1 | Reemplazado por `mdns_broadcast_service.dart` |
| `lib/core/network/bonsoir_service.dart` | 1 | Reemplazado por `nsd_discovery_service.dart` |

---

## 8. Errores y Bugs

### 8.1 Errores en la Propuesta Original (response.md)

| Error | Gravedad | Corregido por |
|---|---|---|
| `nsd ^2.1.2` no existe | Alta | @arqui |
| `txt: List<int>` tipo incorrecto | Alta | @arqui |
| No migrar discovery rompe compilación | Alta | @arqui |
| Linux no soportado por nsd | Media | @arqui |
| `dispose()` con referencias rotas | Media | @arqui |
| Archivos nativos no considerados | Media | @arqui |

### 8.2 Bugs Detectados en Verificación (@arqui)

| Bug | Archivo | Síntoma | Solución |
|---|---|---|---|
| **Crítico #1** | `minimal_control_screen.dart` | `stanzasProvider.whenData()` no se ejecuta en primera navegación (AsyncLoading). El himno nunca se carga. | Reemplazar por `ref.listen` que reacciona a loading→data |
| **Crítico #2** | `grpc_display_server.dart` | `clamp(0, -1)` crashea cuando `lyrics` está vacío. El stream `watchStatus` se rompe. | Guarda early-return si `lyrics.isEmpty` |
| **Medio #3** | `grpc_display_server.dart` | Resource leak: si el cliente cancela la subscripción, no se cierran sub, timerSub ni controller. | Envolver `await for` en `try/finally` |

---

## 9. Estado del Análisis Estático

```
$ dart analyze lib/

No issues found! (0 errores, 0 warnings)
```

Solo issues `info` de estilo (const constructors, trailing commas) — todos pre-existentes.

---

## 10. Arquitectura Resultante

### 10.1 Capas de Red

```
lib/core/network/
├── mdns_broadcast_service.dart      ← Broadcast mDNS (nsd register)
├── nsd_discovery_service.dart       ← Discovery mDNS (nsd startDiscovery)
├── mdns_discovery.dart              ← Wrapper → NsdDiscoveryService
├── permission_service.dart          ← Permisos red
├── connection_state.dart            ← Estados de conexión
└── domain/
    ├── discovered_display.dart
    └── bonsoir_discovered_service.dart

lib/data/datasources/remote/
├── grpc_display_server.dart         ← Servidor gRPC (PC/Display)
└── grpc_control_datasource.dart     ← Cliente gRPC (Celular/Control)
```

### 10.2 Flujo de Datos Emisor/Receptor

```
CELULAR (Control)                         PC (Display)
      │                                        │
      ├── Conecta mDNS ───────────────────────►│
      │   (nsd discovery)                      │ (nsd broadcast)
      │                                        │
      ├── handshake() ────────────────────────►│ onClientConnected
      │                                        │   → auto-abre ventana
      │                                        │
      ├── SendHymnContent() ──────────────────►│ onLoadHymnContent
      │   (payload completo:                   │   → liveControlProvider.loadHymn()
      │    título + estrofas)                  │   → ventana proyecta
      │                                        │
      ├── sendNextStanza() ───────────────────►│ nextSlide()
      │   (sendPrev, GO_TO_STANZA, etc.)       │
      │                                        │
      ├── GetAvailableBackgrounds() ──────────►│ FondoRepository
      │◄── BackgroundList                      │
      │                                        │
      └── SET_BACKGROUND(id) ─────────────────►│ Cambia fondo en PC
```

### 10.3 Inicialización

```
AppInitializer.initialize()
├── _initDatabase()
├── _initPlatform() → TargetPlatform
├── _initNetworkServices()
│   ├── Desktop Windows:
│   │   ├── GrpcDisplayServer.start()
│   │   │   ├── onCommand → LiveControlNotifier
│   │   │   ├── onJumpToHymn → carga himno local
│   │   │   ├── onClientConnected → isClientConnectedProvider
│   │   │   └── onLoadHymnContent → inyecta himno remoto
│   │   └── MdnsBroadcastService.start() → _himnario._tcp
│   ├── Desktop Linux:
│   │   └── GrpcDisplayServer.start() (sin broadcast)
│   └── Mobile (Android/iOS):
│       └── NsdDiscoveryService.start()
└── _initNsdDiscovery() (mobile)
```

---

## 11. Pendientes

| Tarea | Prioridad | Fase | Descripción |
|---|---|---|---|
| Probar en Windows | 🔴 Alta | 1+2 | Buildear `.exe` y verificar broadcast mDNS + control remoto |
| Probar en Android | 🔴 Alta | 2 | Verificar discovery + envío de himno + fondos |
| Buildear APK release | 🔴 Alta | 2 | `flutter build apk --release` con JDK 17 |
| Tipar `sendHymnContent`/`getAvailableBackgrounds` | 🟡 Media | 2 | Usar tipos fuertes en vez de `Map<String, dynamic>` |
| Sincronizar `selected` en fondos remotos | 🟡 Media | 2 | Reflejar fondo activo del display en chips UI |
| `_parseStanzaType` añadir `'puente'` | 🟢 Baja | 2 | Mapear `puente` → `EstrofaTipo.puente` |
| Renombrar `BonsoirDiscoveredService` | 🟢 Baja | 1 | Eliminar última referencia a Bonsoir |
| Integración avahi en Linux | 🟢 Baja | 1 | `Process.run('avahi-publish-service')` para broadcast en Linux |
| Documentar macOS | 🟢 Baja | 1 | Probar y documentar configuración Info.plist |

---

## Apéndice: Commits

```
a38a140 docs: reporte completo del flujo Emisor/Receptor en aplicacion.md
218c1ec fix: corregir bugs críticos detectados por @arqui
12910f6 docs: agregar pasos.md con plan de arquitectura UI Reactiva
74f8146 refactor: migración completa de Bonsoir a NSD para mDNS nativo
10ffb3a fix: service type mismatch broadcast/discovery
f800dcc fix: permision request moved to sheet
b756f94 fix: bugs críticos conexión LAN
2297d95 fix: bonsoir v6.1.0
969ea2f fix: correcciones para conexión LAN funcional
b246375 feat: conexión LAN vía gRPC keepalive + Bonsoir mDNS
```

---

*Documento generado por @orquestador — 21 de mayo de 2026*
