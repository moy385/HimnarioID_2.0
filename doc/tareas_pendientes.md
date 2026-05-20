# Tareas Pendientes — HimnarioID 2.0

> **Fecha:** 20 de mayo de 2026 — 2ª revisión
> **Propósito:** Estado actual del proyecto tras FileStorageService, copia local de fondos y APK build.

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
| **Admin CRUD** | ✅ Funcional | Himnos, categorías, países, pistas, fondos |
| **Admin directo** | ✅ Funcional | Icono de ajustes sin login forzoso |
| **Audio** | ✅ Funcional | Descarga, reproducción, bottom player |
| **Brocha (apariencia)** | ✅ Mejorada | Auto-refresh (Consumer), fondos color/imagen, selector HSV, paleta 22 colores, opacidad tarjetas |
| **Brocha conectada** | ✅ Funcional | IPC SET_CONFIG a ventana de proyección |
| **Fondos de pantalla** | ✅ Funcional | Color + imagen (file_picker), CRUD completo |
| **Eliminación de fondos** | ✅ Funcional | Invalida brocha/vista himno + borra archivo físico |
| **Almacenamiento local de fondos** | ✅ Implementado | FileStorageService copia a `{appDocs}/himnario_id/fondos/` al seleccionar, solo borra copia local |
| **Escalado proyección** | ✅ Funcional | `projectionFontScale` independiente (0.5–3.0) |
| **Scroll proyección** | ✅ Funcional | Condicional, SingleChildScrollView si desborda |
| **Reflow acordes proyección** | ✅ Funcional | StanzaLayoutEngine.processStanza |
| **Flujo presentación slides** | ✅ Funcional | Title → Lyrics → Amen con etiquetas |
| **Ventana de proyección** | ✅ Funcional | SubprocessWindowService + IPC JSON |
| **Modo Dual PC/Celular** | ✅ Funcional | Switch debug, rutas, botón Presentar |
| **Conexión Emisor/Receptor** | ❌ No funcional | Infraestructura lista, flujo incompleto |
| **gRPC** | ❌ No implementado | Proto compilado, servidor no creado |
| **Fondos de video** | ❌ Revertido | Crash irrecuperable en Linux (libmpv 0.41.0). Pendiente para futuro. |
| **Tests** | ✅ 274 tests | 263 unit/widget + 11 integración (~11 fallos conocidos) |
| **APK Android** | ✅ Funcional | Build release 62MB (fat APK) con JDK 17 en `/home/melquisedec/jdk17` |

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

#### P2.3 — Limpieza de código muerto
**Archivos**: Todo el proyecto
**Descripción**: Eliminar imports no usados, widgets placeholder, código comentado. El revert de video pudo dejar código huérfano.
**Tiempo estimado**: ~1h

---

### 🟢 P3 — Baja prioridad / Mejora continua

#### P3.1 — Servidor gRPC (bin/server.dart)
**Archivos**: Nuevo `bin/server.dart`, `lib/core/network/grpc_server.dart`
**Tiempo estimado**: ~4h

#### P3.2 — Modo Emisor completo
**Archivos**: `connected_dashboard.dart`, `minimal_control_screen.dart`
**Dependencias**: P3.1
**Tiempo estimado**: ~3h

#### P3.3 — Detección automática de plataforma en producción
**Archivos**: `dual_mode_providers.dart`
**Tiempo estimado**: ~30min

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
P2.4 Cleanup ─── EJECUTABLE
P1.2 Split APK ─── sin dependencias
P3.1 gRPC servidor ───→ P3.2 Modo Emisor
P2.1 Tests core ───→ P3.5 Tests widgets
```

---

## Notas importantes

1. **Brocha mejorada**: Consumer reemplazó StatefulBuilder, fondos se refrescan automáticamente tras crear/editar/eliminar. Selector HSV + paleta 22 colores.
2. **Eliminación de fondos**: Al borrar un fondo, se invalida `fondosActivosProvider` (brocha + vista himno se actualizan). `DeleteFondoUseCase` usa `FileStorageService.deleteIfAppFile()` que solo borra si está dentro del directorio app.
3. **Fondos copiados a directorio local**: `FileStorageService` en `lib/core/utils/`. Al seleccionar imagen con file_picker, se copia a `{appDocs}/himnario_id/fondos/` con nombre único. Al eliminar el fondo, solo se borra la copia local, nunca el original del usuario.
4. **Fondos de video REVERTIDOS**: Se implementó con `video_player_media_kit` pero se descartó por crash en Linux. Todo el código fue revertido. La rama `main` está limpia.
5. **274 tests existentes**: 263 unit/widget + 11 integración (~11 fallos conocidos por tabla Pais).
6. **APK release**: 62MB (fat APK). Con `--split-per-abi` bajaría a ~25MB cada uno.
7. **JDK 17 obligatorio** para build Android (JDK 25 no compatible con Gradle 8.14). Ubicación: `/home/melquisedec/jdk17`.

---

*Documento actualizado por @orquestador — 20 de mayo de 2026 (2ª revisión)*
