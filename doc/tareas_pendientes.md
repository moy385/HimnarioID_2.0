# Tareas Pendientes — HimnarioID 2.0

> **Fecha:** 21 de mayo de 2026 — 5ª revisión
> **Propósito:** Estado actual tras completar flujo Emisor/Receptor, orden himnos, filtro Convención y CRUD Usuarios backend.

---

## Resumen del Estado Actual

| Área | Estado | Notas |
|------|--------|-------|
| **Base de datos** | ✅ Funcional | 425 himnos (400 + 25 convenciones), SQLite **v4**, 13 tablas + `Himno_Busqueda` |
| **Home / Búsqueda** | ✅ Funcional | Búsqueda acento-insensible, filtros, scroll A-Z |
| **Búsqueda Android** | ✅ Optimizada | Debounce 400ms, N+1 eliminado, tabla pre-normalizada |
| **Detalle de himno** | ✅ Funcional | Acordes sobre texto con ChordOverlayText (Stack + Positioned + TextPainter) |
| **Acordes sobre texto** | ✅ Funcional | ChordParser + ChordPainter con caché LRU + ChordOverlayText |
| **Toggle acordes (Solfa)** | ✅ Funcional | showChords persistente en DB, botón Solfa funcional |
| **Admin CRUD** | ✅ Funcional | Himnos, categorías, países, pistas, fondos. Backend Usuarios listo (UI removida) |
| **Admin directo** | ✅ Funcional | Icono de ajustes sin login forzoso |
| **CRUD Usuarios (backend)** | ✅ Implementado | Datasource, repository, use cases, providers. UI removida del panel (conservada para futuro) |
| **Audio** | ✅ Funcional | Descarga, reproducción, bottom player |
| **Brocha (apariencia)** | ✅ Mejorada | Auto-refresh (Consumer), fondos color/imagen, selector HSV, paleta 22 colores, opacidad tarjetas |
| **Brocha conectada** | ✅ Funcional | IPC SET_CONFIG a ventana de proyección |
| **Fondos de pantalla** | ✅ Funcional | Color + imagen (file_picker), CRUD completo |
| **Eliminación de fondos** | ✅ Funcional | Invalida brocha/vista himno + borra archivo físico |
| **Almacenamiento local de fondos** | ✅ Implementado | FileStorageService copia a `{appDocs}/himnario_id/fondos/` al seleccionar, solo borra copia local |
| **Limpieza de código muerto** | ✅ Completado | 310 líneas eliminadas, 32 archivos. Eliminados: FondoPantallaTipo.video, 3 directorios huérfanos, login_screen, barrel files, 6 providers deprecados |
| **Escalado proyección** | ✅ Funcional | `projectionFontScale` independiente (0.5–3.0). Slider visible en móvil emisor conectado |
| **Orden himnos Oficiales primero** | ✅ Implementado | `CASE WHEN` en SQL getter `_defaultOrderBy` |
| **Filtro Convención** | ✅ Implementado | Chip en HomeScreen + ConnectedDashboard |
| **Scroll proyección** | ✅ Funcional | Condicional, SingleChildScrollView si desborda |
| **Reflow acordes proyección** | ✅ Funcional | StanzaLayoutEngine.processStanza |
| **Flujo presentación slides** | ✅ Funcional | Title → Lyrics → Amen con etiquetas |
| **Ventana de proyección** | ✅ Funcional | SubprocessWindowService + IPC JSON |
| **Modo Dual PC/Celular** | ✅ Funcional | Switch debug, rutas, botón Presentar |
| **Conexión Emisor/Receptor** | ✅ Completa y funcional | gRPC server + mDNS broadcast/discovery + flujo completo: discover, handshake, watchStatus, comandos de navegación, apariencia y envío automático de himno |
| **gRPC** | ✅ Implementado | GrpcDisplayServer (335 líneas, 7 comandos, handshake, watchStatus streaming). GrpcControlDataSource con keepalive, heartbeat, auto-reconexión |
| **F11 fullscreen** | ✅ Implementado | FullscreenHandler global en HimnarioDualApp |
| **Fondos de video** | ❌ Revertido | Crash irrecuperable en Linux (libmpv 0.41.0). Pendiente para futuro. |
| **Tests** | ✅ 274 tests | 263 unit/widget + 11 integración (~11 fallos conocidos) |
| **APK Android** | ✅ Funcional | Build release 65.5MB (fat APK) con JDK 17 en `/home/melquisedec/jdk17` |

---

## Evaluación de tablas restantes (21 mayo 2026)

@arqui evaluó las 3 tablas que faltaban (`Version_Pais`, `Arreglo_Musical`, `Himno_Categoria`) y determinó que **ninguna justifica un CRUD standalone**:

| Tabla | ¿CRUD Admin? | Motivo |
|-------|:------------:|--------|
| **Himno_Categoria** | ❌ | Ya gestionada desde `hymn_form_screen.dart` vía `CategoriaSelector` |
| **Version_Pais** | ❌ | Pertenece al contexto del himno. Mejora futura: multi-versión en formulario de himno |
| **Arreglo_Musical** | ❌ | Ya tiene capa de datos completa. UI pertenece al músico/usuario final, no al admin |

**El panel admin está completo con 4 tabs** (Categorías, Países, Pistas, Fondos).

---

## Prioridades

### 🔴 P0 — Bloqueante / Core

#### ✅ P0.1 — Acordes sobre el texto (COMPLETADO)
**Archivos**: `chord_parser.dart`, `chord_painter.dart`, `chord_overlay_text.dart`
**Estado**: ✅ Completado y mergeado a main

#### ✅ P0.2 — Transposición funcional con UI de acordes
**Archivos**: `transpose_providers.dart`, `chord_transposer.dart`
**Estado**: ✅ Completado

---

### 🟡 P1 — Alta prioridad

#### ✅ P1.1 — Probar flujo Presentar end-to-end en Linux
**Estado**: ✅ Probado

#### P1.2 — Reducir tamaño APK (split-per-abi)
**Archivos**: `android/`, comando build
**Descripción**: `--split-per-abi` para bajar de ~64MB a ~25MB. Firmar con keystore.
**Tiempo estimado**: ~1h

---

### 🔵 P2 — Media prioridad

#### P2.1 — Tests unitarios básicos
**Archivos**: `test/`
**Descripción**: Tests para ChordTransposer, StringUtils, StanzaLayoutEngine. Priorizar lógica pura.
**Tiempo estimado**: ~3h

#### P2.2 — Refactor: sheets compartidos
**Archivos**: Extraer lógica a `shared_widgets/control_sheets.dart`
**Tiempo estimado**: ~1.5h

#### ✅ P2.3 — Limpieza de código muerto (COMPLETADO)
**Archivos**: Todo el proyecto
**Descripción**: Eliminado FondoPantallaTipo.video, 3 directorios huérfanos (state_management/, app_controller/, app_display/), login_screen.dart, barrel files, 6 providers deprecados, imports no usados.
**Resultado**: 310 líneas eliminadas, 32 archivos cambiados, 0 errores/warnings.
**Fecha**: 20 mayo 2026 — Rama `chore/limpieza-codigo-muerto` mergeada a main.

---

### 🔵 P2 — Media prioridad (actualizado)

#### P2.4 — Orden himnos Oficiales primero ✅ Completado

#### P2.5 — Filtro Convención ✅ Completado

#### P2.6 — CRUD Usuarios backend ✅ Completado (UI removida, lógica conservada)

#### P2.7 — Merge feature/orden-filtros-admin-crud → main
**Descripción**: Fusionar la rama actual a main tras aprobación.

### 🟡 P1 — Nueva

#### P1.3 — Limpiar CHECK constraints SQL (cosmético)
**Archivos**: `lib/core/database/database_helper.dart`
**Descripción**: Las constraints SQL aún mencionan `'video'` como tipo válido. Requiere migración de BD (v5) para limpiar. No urgente — mantiene compatibilidad hacia atrás.
**Tiempo estimado**: ~30min

### 🟢 P3 — Baja prioridad / Mejora continua

#### ✅ P3.1 — Servidor gRPC (bin/server.dart)
**Archivos**: `lib/data/datasources/remote/grpc_display_server.dart`, `lib/bootstrap/app_initializer.dart`
**Descripción**: Servidor gRPC creado e integrado. 335 líneas, implementa HymnControlServiceBase con 7 tipos de comando (NEXT, PREV, GO_TO_STANZA, GO_TO_CHORUS, BLACKOUT, CLEAR_BLACKOUT, JUMP_TO_HYMN, PING), handshake con versión de protocolo, y watchStatus streaming con ProviderContainer.
**Estado**: ✅ Completado

#### ✅ P3.2 — Modo Emisor completo (COMPLETADO)
**Archivos**: `connected_dashboard.dart`, `minimal_control_screen.dart`
**Estado**: ✅ Completado — flujo Emisor/Receptor funcional vía gRPC con discover, handshake, watchStatus, comandos de navegación, apariencia y envío automático de himno

#### ✅ P3.3 — Detección automática de plataforma (COMPLETADO)
**Archivos**: `app_initializer.dart`, `dual_mode_providers.dart`
**Estado**: ✅ Completado — detección por TargetPlatform en AppInitializer que decide iniciar servidor gRPC (desktop) o discovery mDNS (mobile)

#### P3.4 — Fondos de video (a futuro)
**Archivos**: Requiere re-implementar con soporte nativo de video
**Descripción**: Se intentó con `video_player_media_kit` + libmpv, pero libmpv 0.41.0 crashea en Linux con `assertion 'group_index >= 0'`. Esperar a que Ubuntu actualice libmpv o migrar a otro backend.
**Tiempo estimado**: ~5h (cuando sea viable)

#### P3.5 — Tests de widgets e integración
**Archivos**: `test/`
**Dependencias**: P2.1
**Tiempo estimado**: ~6h

---

## Dependencias entre tareas

```
P1.2 Split APK ─── sin dependencias
P1.3 CHECK SQL ─── migracion BD (v4→v5)
~~P3.1 gRPC servidor ───→ P3.2 Modo Emisor~~ ✅ P3.1 completado
P2.1 Tests core ───→ P3.5 Tests widgets
```

---

## Notas importantes

1. **Brocha mejorada**: Consumer reemplazó StatefulBuilder, fondos se refrescan automáticamente tras crear/editar/eliminar. Selector HSV + paleta 22 colores.
2. **Eliminación de fondos**: Al borrar un fondo, se invalida `fondosActivosProvider` (brocha + vista himno se actualizan). `DeleteFondoUseCase` usa `FileStorageService.deleteIfAppFile()` que solo borra si está dentro del directorio app.
3. **Fondos copiados a directorio local**: `FileStorageService` en `lib/core/utils/`. Al seleccionar imagen con file_picker, se copia a `{appDocs}/himnario_id/fondos/` con nombre único. Al eliminar el fondo, solo se borra la copia local, nunca el original del usuario.
4. **Fondos de video REVERTIDOS**: Se implementó con `video_player_media_kit` pero se descartó por crash en Linux. Todo el código fue revertido. La rama `main` está limpia.
5. **Limpieza de código muerto completada**: 310 líneas eliminadas, 32 archivos. Se eliminaron `FondoPantallaTipo.video`, 3 directorios huérfanos, `login_screen.dart`, barrel files, y 6 providers deprecados.
6. **274 tests existentes**: 263 unit/widget + 11 integración (~11 fallos conocidos por tabla Pais).
7. **APK release**: 62MB (fat APK). Con `--split-per-abi` bajaría a ~25MB cada uno.
8. **JDK 17 obligatorio** para build Android (JDK 25 no compatible con Gradle 8.14). Ubicación: `/home/melquisedec/jdk17`.
9. **Infraestructura de red completada**: Servidor gRPC (GrpcDisplayServer, 335 líneas, 7 comandos), broadcast mDNS (BonsoirBroadcastService), descubrimiento (MdnsDiscovery + BonsoirService), detección de plataforma, y orquestación centralizada en AppInitializer con try/catch en cada capa.
10. **Broadcast mDNS**: Limitado a Windows y Linux (Bonsoir no está disponible en macOS en Flutter desktop). En móvil se usa discovery Bonsoir para encontrar displays.

---

*Documento actualizado por @orquestador — 20 de mayo de 2026 (4ª revisión)*
