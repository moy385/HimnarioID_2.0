# Tareas Pendientes — HimnarioID 2.0

> **Fecha:** 19 de mayo de 2026
> **Propósito:** Estado actual del proyecto después de features de acordes y reflow en proyección.

---

## Resumen del Estado Actual

| Área | Estado | Notas |
|------|--------|-------|
| **Base de datos** | ✅ Funcional | 400 himnos, SQLite **v4**, 13 tablas + `Himno_Busqueda` |
| **Home / Búsqueda** | ✅ Funcional | Búsqueda acento-insensible, filtros, scroll A-Z |
| **Búsqueda Android** | ✅ Optimizada | Debounce 400ms, N+1 eliminado, tabla pre-normalizada |
| **Detalle de himno** | ✅ Funcional | Acordes sobre texto con ChordOverlayText (Stack + Positioned + TextPainter) |
| **Acordes sobre texto** | ✅ Funcional | ChordParser + ChordPainter con caché LRU + ChordOverlayText |
| **Toggle acordes (Solfa)** | ✅ Funcional | showChords persistente en DB, botón Solfa funcional en PresentControlBar |
| **Admin CRUD** | ✅ Funcional | Himnos, categorías, países, pistas de audio |
| **Audio** | ✅ Funcional | Descarga, reproducción, bottom player |
| **Autenticación** | ✅ Funcional | Login admin/admin123, logout |
| **Brocha (apariencia)** | ✅ Funcional | Fuente, tamaño, color, fondos, negritas |
| **Brocha conectada** | ✅ Funcional | IPC SET_CONFIG a ventana de proyección |
| **Escalado proyección** | ✅ Funcional | `projectionFontScale` independiente (0.5–3.0) |
| **Scroll proyección** | ✅ Funcional | Condicional, auto-fit eliminado, SingleChildScrollView si desborda |
| **Reflow acordes proyección** | ✅ Funcional | StanzaLayoutEngine.processStanza, reduce líneas preservando acordes |
| **Flujo presentación slides** | ✅ Funcional | Title → Lyrics → Amen con etiquetas |
| **Ventana de proyección** | ✅ Funcional | SubprocessWindowService + IPC JSON |
| **Modo Dual PC/Celular** | ✅ Funcional | Switch debug, rutas, botón Presentar |
| **Conexión Emisor/Receptor** | ❌ No funcional | Infraestructura lista, flujo incompleto |
| **gRPC** | ❌ No implementado | Proto compilado, servidor no creado |
| **Tests** | ✅ ✅ 274 tests | 263 unit/widget + 11 integración (~11 fallos conocidos por tabla Pais) |
| **APK Android** | ✅ Funcional | Build release, 64.6MB (fat APK) |

---

## Prioridades

### 🔴 P0 — Bloqueante / Core

#### ✅ P0.1 — Acordes sobre el texto (COMPLETADO)
**Archivos**: `chord_parser.dart`, `chord_painter.dart`, `chord_overlay_text.dart`
**Descripción**: Implementado ChordParser (función pura), ChordPainter con caché LRU (64 entradas), ChordOverlayText (Stack + Positioned). 21 tests unitarios. 200+ líneas eliminadas de hymn_detail_screen.
**Estado**: ✅ Completado (feature mergeado a main)

#### ✅ P0.2 — Transposición funcional con UI de acordes
**Archivos**: `transpose_providers.dart`, `chord_transposer.dart`
**Descripción**: La transposición funciona correctamente con los acordes overlay. Dependencia de P0.1 resuelta.
**Estado**: ✅ Completado

---

### 🟡 P1 — Alta prioridad

#### ✅ P1.1 — Probar flujo Presentar end-to-end en Linux
**Archivos**: `home_screen.dart`, `present_control_bar.dart`, `live_projection_screen.dart`
**Descripción**: El flujo Presentar abre ventana de proyección con slides. Toggle de acordes funcional. Scroll condicional + reflow probados.
**Estado**: ✅ Probado

#### P1.2 — Reducir tamaño APK (split-per-abi)
**Archivos**: `android/`, comando build
**Descripción**: `--split-per-abi` para bajar de ~64MB a ~25MB. Firmar con keystore.
**Tiempo estimado**: ~1h

---

### 🔵 P2 — Media prioridad

#### P2.1 — Tests unitarios básicos
**Archivos**: `test/`
**Descripción**: Crear tests para el core: ChordTransposer (lógica crítica), StringUtils (normalizeForSearch, compareForSort), StanzaLayoutEngine. Priorizar lógica pura (sin dependencias).
**Tiempo estimado**: ~3h

#### P2.2 — Refactor: sheets compartidos
**Archivos**: Extraer lógica de `hymn_detail_screen.dart` a `shared_widgets/control_sheets.dart`
**Descripción**: Los sheets de Brocha, Solfa, Nota, Lupa están duplicados o inline en HymnDetailScreen. Extraerlos a widgets compartidos.
**Tiempo estimado**: ~1.5h

#### P2.4 — Limpieza de código muerto
**Archivos**: Todo el proyecto
**Descripción**: Eliminar imports no usados, widgets placeholder, código comentado. Después de los múltiples sprints y el revert, probablemente hay archivos/imports huérfanos.
**Tiempo estimado**: ~1h

---

### 🟢 P3 — Baja prioridad / Mejora continua

#### P3.1 — gRPC server (bin/server.dart)
**Archivos**: Nuevo `bin/server.dart`, `lib/core/network/grpc_server.dart`
**Descripción**: Implementar el servidor gRPC real para la comunicación Emisor-Receptor. El proto ya está compilado en `lib/proto/generated/`. Sin esto, el modo Emisor/Receptor no funciona.
**Dependencias**: P1.3
**Tiempo estimado**: ~4h

#### P3.2 — Modo Emisor completo
**Archivos**: `connected_dashboard.dart`, `minimal_control_screen.dart`
**Descripción**: Cuando el celular actúa como Emisor y se conecta a un Receptor, el dashboard debe cambiar (ConnectedDashboard) y al seleccionar himno abrir MinimalControlScreen. El flujo está armado pero no funcional.
**Dependencias**: P3.1
**Tiempo estimado**: ~3h

#### P3.3 — Detección automática de plataforma en producción
**Archivos**: `dual_mode_providers.dart`
**Descripción**: En release, la app debe detectar automáticamente si está en PC o celular (sin el switch debug). Actualmente `_detectInitialMode` tiene un stub comentado.
**Tiempo estimado**: ~30min

#### P3.4 — File Picker para Fondos de Pantalla
**Archivos**: `fondo_tab.dart`
**Descripción**: Agregar upload de imágenes/videos para los fondos de pantalla del modo proyección. Actualmente solo hay campo de texto para la ruta. Requiere `file_picker` (ya en pubspec).
**Tiempo estimado**: ~1h

#### P3.5 — Tests de widgets e integración
**Archivos**: `test/`
**Descripción**: Tests de widgets para screens principales (HomeScreen, HymnDetailScreen, LoginScreen, Admin panel). Tests de integración para DB + repositorios.
**Dependencias**: P2.1
**Tiempo estimado**: ~6h

---

## Dependencias entre tareas

```
P0.1 Acordes ─── [COMPLETADO] ✓
  └── P0.2 Transposición ─── [COMPLETADO] ✓
       └── P2.4 Cleanup ─── AHORA EJECUTABLE

P1.1 Probar Present ─── [COMPLETADO] ✓
P1.2 Split APK ─── sin dependencias
```

**Nota:** P2.1, P3.5 (tests) ya están parcialmente completos (274 tests existentes: 263 unit/widget + 11 integración).
**Nota:** P3.3 (detección plataforma) ya no aplica — el modo dual funciona con switch debug.

---

## Archivos sprint eliminados

Los siguientes archivos fueron generados por agentes (`arqui`) como planes de trabajo y **ya no son necesarios**:

| Archivo | Contenido | Estado |
|---------|-----------|--------|
| `PLAN_SPRINT_3.md` | Plan de Sprint 3 (comparativa vs deseado) | ❌ Obsoleto |
| `SPRINT_4_PLAN.md` | Plan de Sprint 4 (11 tareas P0-P3) | ❌ Obsoleto |
| `REPORTE_SPRINT4.md` | Reporte técnico del Sprint 4 | ❌ Obsoleto |
| `SPRINT_5_PLAN.md` | Plan de Sprint 5 (corrección modo PC) | ❌ Obsoleto |
| `SPRINT_5_FIXES.md` | Plan Sprint 5.2 (IPC + QA fixes) | ❌ Obsoleto |
| `TASKS_DEV_SPRINT5.md` | Tareas @dev para Sprint 5.2 | ❌ Obsoleto |
| `TASKS_DESIGN_SPRINT5.md` | Tareas @design para Sprint 5.2 | ❌ Obsoleto |
| `TASKS_QA_SPRINT5.md` | Tareas @qa para Sprint 5.2 | ❌ Obsoleto |

Razón: Eran documentos de planificación interna generados por agentes. Su contenido está desactualizado y no refleja el estado real del proyecto. Ningún archivo del código fuente los referenciaba.

---

## Notas importantes

1. **Acordes overlay implementados**: ChordOverlayText usa Stack + Positioned + TextPainter con caché LRU. Toggle global con `showChords` persistente en DB.
2. **La proyección ya es funcional**: WindowService, SubprocessWindowService, slides, brocha conectada, escalado independiente — todo probado en Linux.
3. **274 tests existentes**: 263 unit/widget (incluyendo 21 tests nuevos de ChordParser) + 11 tests de integración (~11 fallos conocidos por tabla Pais).
4. **APK release**: 64.6MB (fat APK). Con `--split-per-abi` bajaría a ~25MB.
5. **JDK 17 obligatorio** para build Android (JDK 25 no compatible con Gradle 8.14).
6. **Búsqueda Android optimizada**: tabla `Himno_Busqueda` con texto pre-normalizado + debounce + batch queries.

---

*Documento actualizado por @orquestador — 19 de mayo de 2026*
