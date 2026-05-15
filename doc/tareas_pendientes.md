# Tareas Pendientes — HimnarioID 2.0

> **Fecha:** 15 de mayo de 2026
> **Propósito:** Evaluación real del estado del proyecto después del revert de acordes y limpieza de archivos sprint obsoletos.

---

## Resumen del Estado Actual

| Área | Estado | Notas |
|------|--------|-------|
| **Base de datos** | ✅ Funcional | 400 himnos, SQLite v3, esquema normalizado |
| **Home / Búsqueda** | ✅ Funcional | Búsqueda acento-insensible, filtros, scroll A-Z |
| **Detalle de himno** | 🟡 Parcial | Chords inline (regresión), sin posicionamiento sobre texto |
| **Admin CRUD** | ✅ Funcional | Himnos, categorías, países, pistas de audio |
| **Audio** | ✅ Funcional | Descarga, reproducción, bottom player |
| **Autenticación** | ✅ Funcional | Login admin/admin123, logout |
| **Modo Dual PC/Celular** | 🟡 Parcial | Switch debug, botón Presentar, rutas configuradas |
| **Ventana de proyección** | 🟡 Parcial | WindowService implementado, IPC sin probar |
| **Conexión Emisor/Receptor** | ❌ No funcional | Infrastructure exists, flujo incompleto |
| **gRPC** | ❌ No implementado | Proto compilado, servidor no creado |
| **Tests** | ❌ No existen | 0 tests unitarios, 0 tests de widget |
| **APK Android** | ✅ Funcional | Build debug funcional con JDK 17 |

---

## Prioridades

### 🔴 P0 — Bloqueante / Core

#### P0.1 — Acordes sobre el texto (RE-IMPLEMENTAR)
**Archivos**: `hymn_detail_screen.dart`, `stanza_layout_engine.dart`, nuevo widget de acordes
**Descripción**: El usuario pidió originalmente que los acordes se muestren SOBRE el texto (no inline). Por el revert perdimos toda la lógica de posicionamiento. Hay que re-implementarla desde cero o restaurar los commits.
**Enfoques**:
- **Opción A**: Restaurar los commits de acordes (`git cherry-pick 6d663f3 44e115f a25e287 af5af3d`) y luego arreglar los problemas que el usuario detectó.
- **Opción B**: Re-implementar con un enfoque más simple desde el principio.
**Tiempo estimado**: ~2-4h

#### P0.2 — Transposición funcional con UI de acordes
**Archivos**: `transpose_providers.dart`, `chord_transposer.dart`
**Descripción**: La transposición funciona a nivel de datos pero los acordes inline se ven mal. La UI necesita mostrar correctamente los acordes transpuestos sobre el texto.
**Dependencias**: P0.1
**Tiempo estimado**: ~1h

---

### 🟡 P1 — Alta prioridad (después de acordes)

#### P1.1 — `dart analyze` 0 errores
**Archivos**: Todo el proyecto
**Descripción**: Correr `dart analyze lib/` y arreglar todos los errores, warnings e infos. Después del revert puede haber imports rotos o código muerto.
**Tiempo estimado**: ~30min

#### P1.2 — Probar flujo Presentar + himno en PC
**Archivos**: `himnario_dual_app.dart`, `present_control_bar.dart`, `home_screen.dart`
**Descripción**: Verificar que al presionar "Presentar" y tocar un himno, el himno se proyecta y el control overlay aparece en la pantalla principal. SubprocessWindowService (IPC stdin/stdout) no se ha probado nunca.
**Tiempo estimado**: ~2h

#### P1.3 — Probar/arreglar StandbyScreen con ConnectionRole.receiver
**Archivos**: `home_screen.dart`, `standby_screen.dart`, `receptor_binding.dart`
**Descripción**: Cuando el usuario selecciona "Receptor" en el diálogo de conexión, debe mostrarse StandbyScreen (fondo negro, info del servidor). Actualmente el flujo está configurado en código pero no se ha probado.
**Tiempo estimado**: ~1h

#### P1.4 — Integrar MinimalControlScreen funcional
**Archivos**: `minimal_control_screen.dart`, `shared_widgets/control_sheets.dart`
**Descripción**: Los botones Brocha, Solfa, Nota, Lupa en MinimalControlScreen son placeholders. Necesitan conectarse a los mismos sheets que HymnDetailScreen.
**Tiempo estimado**: ~2h

---

### 🔵 P2 — Media prioridad

#### P2.1 — Tests unitarios básicos
**Archivos**: `test/`
**Descripción**: Crear tests para el core: ChordTransposer (lógica crítica), StringUtils (normalizeForSearch, compareForSort), StanzaLayoutEngine. Priorizar lógica pura (sin dependencias).
**Tiempo estimado**: ~3h

#### P2.2 — Verificar APK build en release
**Archivos**: `android/`
**Descripción**: Probar `flutter build apk --release --split-per-abi` para obtener APK más pequeño (~20-30MB vs 177MB debug). Verificar que la BD embebida funciona.
**Tiempo estimado**: ~1h

#### P2.3 — Refactor: sheets compartidos
**Archivos**: Extraer lógica de `hymn_detail_screen.dart` a `shared_widgets/control_sheets.dart`
**Descripción**: Los sheets de Brocha, Solfa, Nota, Lupa están duplicados o inline en HymnDetailScreen. Extraerlos a widgets compartidos para reutilizarlos en MinimalControlScreen.
**Dependencias**: P1.4
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
P0.1 Acordes ─── sin dependencias ───→ [PRIMERO]
  └── P0.2 Transposición ─── depende de P0.1
       └── P1.1 dart analyze ─── puede ir en paralelo
            └── P2.4 Cleanup ─── después de P1.1

P1.2 Probar Present ─── sin dependencias
P1.3 StandbyScreen ─── sin dependencias
P1.4 MinimalControl ─── sin dependencias
  └── P2.3 Refactor sheets ─── ayuda a P1.4

P3.1 gRPC server ─── sin dependencias (pero complejo)
  └── P3.2 Emisor completo ─── depende de P3.1
```

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

1. **Acordes inline vs overlay**: El usuario pidió originalmente acordes SOBRE el texto. El revert nos devolvió a inline (bold). Esta es la tarea #1 a resolver.
2. **La infraestructura de proyección está armada pero no probada**: WindowService, SubprocessWindowService, PresentControlBar, SimpleProjectionView, etc. existen pero nunca se verificaron en un entorno real.
3. **No hay tests**: Cero cobertura. Para un proyecto con 400 himnos y lógica crítica de transposición, esto es un riesgo.
4. **El APK debug funciona**: Pero ocupa ~177MB. Release con split-per-abi sería ~20-30MB.
5. **Los archivos sprint en la raíz ya se eliminaron**: Ya no están en el repositorio.

---

*Documento generado por @orquestador — 15 de mayo de 2026*
