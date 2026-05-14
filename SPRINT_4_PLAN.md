# Sprint 4 — Plan de Implementación

## Estado: ANÁLISIS DE BRECHAS COMPLETO

---

## 1. ANÁLISIS DE BRECHAS (mi_idea.txt vs Código Actual)

### 1.1 App Celular — Pantalla Principal

| # | Visión del Usuario | Estado Actual | Brecha |
|---|-------------------|---------------|--------|
| 1.1 | Buscador y filtros en home | ✅ HomeScreen con HymnSearchBar + FilterChips | COMPLETO |
| 1.2 | Ícono conexión (top-right) | ✅ Cast button → DiscoverDisplaySheet | COMPLETO |
| 1.3 | **Ícono candado (top-left, admin)** | ❌ **No existe en AppBar leading** | **CRÍTICA** |
| 1.4 | Al seleccionar himno → título + scroll estrofas | ✅ HymnDetailScreen implementado | COMPLETO |
| 1.5 | FAB dinámico (equis vertical) | ✅ FabMenu con 4 opciones | COMPLETO |
| 1.6 | Brocha: fondo/fuente/tamaño | ✅ _showBrochaSheet con slider + colores | COMPLETO |
| 1.7 | Nota: pistas audio + controles | ✅ _showNotaSheet con lista de pistas | COMPLETO |
| 1.8 | Solfa: modo músico + transposición + crear arreglo | 🟡 Tiene transposición + toggle acordes. "Crear arreglo" está en PopupMenu (AppBar), NO integrado en Solfa sheet | **MEDIA** |
| 1.9 | Lupa: búsqueda sin salir | ✅ _showLupaDialog con SearchDelegate | COMPLETO |

### 1.2 Conexión — Emisor/Receptor

| # | Visión del Usuario | Estado Actual | Brecha |
|---|-------------------|---------------|--------|
| 2.1 | Botón conexión → 2 opciones (receptor/emisor) | ❌ DiscoverDisplaySheet muestra solo device discovery, **sin selector Emisor/Receptor** | **CRÍTICA** |
| 2.2 | Emisor busca dispositivo → conecta | 🟡 ConnectedDashboard existe pero se activa automáticamente al conectar, no hay selección de rol | **ALTA** |
| 2.3 | Emisor: misma vista inicio con ícono salir | ✅ ConnectedDashboard con AppBar "Modo Emisor" + botón desconectar | COMPLETO |
| 2.4 | Emisor selecciona himno → panel control minimalista | 🟡 MinimalControlScreen existe pero botones Brocha/Solfa/Nota/Lupa son **placeholders sin funcionalidad** | **ALTA** |
| 2.5 | Panel control: flechas, brocha, solfa, nota, lupa, salir | 🟡 Tiene flechas (prev/next) y placeholders. Brocha/Solfa/Nota/Lupa sin implementar | **ALTA** |

### 1.3 Admin (Candado)

| # | Visión del Usuario | Estado Actual | Brecha |
|---|-------------------|---------------|--------|
| 3.1 | Login admin/admin123 | ✅ LoginScreen + AuthNotifier | COMPLETO |
| 3.2 | Menú hamburguesa con hoja+lápiz (CRUD himnos) | ❌ AdminPanelScreen usa **ListView simple**, no hamburger menu | **MEDIA** |
| 3.3 | CRUD himnos con búsqueda, agregar, editar, eliminar | ✅ HymnListScreen + HymnFormScreen completos | COMPLETO |
| 3.4 | Herramientas (CRUD catálogos: país, categorías, pistas, fondos) | ✅ CatalogPanelScreen con 4 tabs | COMPLETO |
| 3.5 | Subir imágenes/videos para fondos | ❌ **FondoTab no tiene file picker/upload** — solo campo de texto para ruta | **ALTA** |

### 1.4 App PC

| # | Visión del Usuario | Estado Actual | Brecha |
|---|-------------------|---------------|--------|
| 4.1 | Misma app con botón "Presentar" | ✅ PresentButton existe en HomeScreen (solo desktop) | COMPLETO |
| 4.2 | **Presentar abre ventana independiente (negra) para proyector** | ❌ **DesktopWindowService y WebWindowService son STUBS** — no abren ventanas reales | **CRÍTICA** |
| 4.3 | Al dar clic himno → se muestra en 2da ventana + panel control | ❌ No hay integración entre botón Presentar y navegación de himnos | **CRÍTICA** |
| 4.4 | Sin Presentar: himno se abre en pestaña principal, solo avanzar/retroceder | ❌ HymnDetailScreen actual tiene transposición, audio, FAB completo — no es modo limitado | **ALTA** |
| 4.5 | Conexión: emisor (esperando conexión) + receptor (pantalla negra) | 🟡 StandbyScreen existe pero no hay flujo completo emisor→conexión→recepción | **ALTA** |

### 1.5 Switch PC/Celular

| # | Visión del Usuario | Estado Actual | Brecha |
|---|-------------------|---------------|--------|
| 5.1 | Switch debug en inferior izquierda | ✅ DeviceSwitch en bottom-left con toggle phone/desktop | COMPLETO |
| 5.2 | Cambia interfaz y opciones según modo | 🟡 HimnarioDualApp conmuta entre StandbyScreen/HomeScreen pero **no cambia comportamientos** | **ALTA** |
| 5.3 | En producción: detección automática de plataforma | 🟡 _detectInitialMode tiene stub comentado | **BAJA** |

---

## 2. PLAN DE ACCIÓN — SPRINT 4

### Prioridades
- **P0 (Crítica)**: Bloqueante para demo
- **P1 (Alta)**: Funcionalidad core faltante
- **P2 (Media)**: Mejora importante de UX
- **P3 (Baja)**: Pulido

---

### TAREA-001 [P0] — Candado (Lock Icon) en HomeScreen
**Asignado**: @dev  
**Descripción**: Agregar IconButton con candado en `leading` del AppBar de HomeScreen. Al presionar, navega a LoginScreen si no está autenticado, o a AdminPanelScreen si ya hay sesión.  
**Archivos**: `lib/presentation/views_personal/dashboard/home_screen.dart`  
**Dependencias**: Ninguna  
**Detalles**: 
- Usar `Icons.lock_outline` / `Icons.lock` según estado auth
- Leer `authProvider` para saber si hay sesión
- Navegar a LoginScreen (push) o AdminPanelScreen (pushReplacement)

### TAREA-002 [P0] — Selector Emisor/Receptor en DiscoverDisplaySheet
**Asignado**: @dev (+ @design para UI)  
**Descripción**: Modificar DiscoverDisplaySheet (o crear pantalla intermedia) que muestre 2 opciones: "Soy Emisor (controlar proyección)" y "Soy Receptor (mostrar en pantalla)".  
**Archivos**: `lib/presentation/views_projection/controller/widgets/discover_display_sheet.dart`  
**Dependencias**: Ninguna  
**Detalles**:
- Si selecciona "Emisor" → activa escaneo de dispositivos (like current)
- Si selecciona "Receptor" → cierra sheet, activa modo Receptor (StandbyScreen)
- Añadir enum `ConnectionRole { emitter, receiver, none }` en `connection_state.dart`
- Modificar `ConnectionNotifier` para manejar el rol

### TAREA-003 [P0] — DesktopWindowService real (abrir 2da ventana)
**Asignado**: @dev  
**Descripción**: Implementar `DesktopWindowService.openProjectionWindow` para abrir una segunda ventana real usando `window_manager`. La ventana debe ser negra, sin decoraciones, mostrar `LiveProjectionScreen` o `StandbyScreen`.  
**Archivos**: `lib/core/window_manager/window_service.dart`, `lib/core/window_manager/window_state.dart`, `lib/core/window_manager/window_providers.dart`  
**Dependencias**: pubspec.yaml ya tiene `window_manager: ^0.5.1`  
**Detalles**:
- Usar `WindowManager.instance.createWindow()` con `WindowOptions`
- La nueva ventana debe abrir `index.html?mode=projection` (web) o nueva isolate Flutter
- Comunicación via `BroadcastChannel` o argumentos de línea de comandos
- Manejar ciclo de vida: abrir/cerrar/eventos

### TAREA-004 [P0] — Integración PresentButton + Navegación de Himnos (PC Mode)
**Asignado**: @dev  
**Descripción**: Cuando el usuario está en modo Desktop y presiona Presentar, al hacer clic en un himno debe: 1) abrir proyección en 2da ventana con el himno, 2) convertir pantalla principal en panel de control (MinimalControlScreen o LiveControlScreen).  
**Archivos**: `lib/presentation/views_personal/dashboard/home_screen.dart`, `lib/presentation/views_personal/dashboard/present_button.dart`, `lib/presentation/dual_mode_wrapper/himnario_dual_app.dart`  
**Dependencias**: TAREA-003  
**Detalles**:
- Cuando `_isPresenting == true`, el `onTap` de HymnCard debe proyectar himno + navegar a control
- En HomeScreen, cuando `_isPresenting && isDesktop`, mostrar lista de himnos con indicador de proyección
- Provider `isPresentingProvider` para compartir estado

### TAREA-005 [P1] — Funcionalidad real en MinimalControlScreen
**Asignado**: @dev  
**Descripción**: Conectar los botones Brocha, Solfa, Nota, Lupa de MinimalControlScreen a funcionalidad real (mismos sheets que HymnDetailScreen).  
**Archivos**: `lib/presentation/views_projection/controller/minimal_control_screen.dart`  
**Dependencias**: Ninguna  
**Detalles**:
- Brocha → abrir _showBrochaSheet (reutilizar lógica)
- Solfa → abrir _showSolfaSheet (transposición + toggle acordes + "crear arreglo")
- Nota → abrir _showNotaSheet (pistas de audio)
- Lupa → abrir búsqueda de himnos
- Refactor: extraer sheets a widgets compartidos en `shared_widgets/`

### TAREA-006 [P1] — Modo Presentación Simple (sin Present button)
**Asignado**: @dev  
**Descripción**: Cuando el usuario NO ha presionado "Presentar" y selecciona un himno en modo Desktop, debe mostrar una vista simplificada con solo navegación (anterior/siguiente) sin FAB, sin transposición, sin audio player.  
**Archivos**: Crear `lib/presentation/views_projection/display/simple_projection_view.dart`  
**Dependencias**: Ninguna  
**Detalles**:
- Nuevo widget `SimpleProjectionView` que recibe Himno
- Solo muestra título + estrofas navegables (prev/next)
- Sin FAB, sin controles de audio, sin transposición
- En `himnario_dual_app.dart`, cuando `!isPresenting && isDesktop`, usar esta vista

### TAREA-007 [P1] — File Picker para Fondos (Upload)
**Asignado**: @dev  
**Descripción**: Agregar botón "Seleccionar archivo" en FondoTab que use `file_picker` para imágenes/videos. Guardar la ruta seleccionada.  
**Archivos**: `lib/presentation/views_admin/crud_catalogs/fondo_tab.dart`, `pubspec.yaml` (+`file_picker`)  
**Dependencias**: Agregar dependencia `file_picker: ^8.0.0`  
**Detalles**:
- Usar `FilePicker.platform.pickFiles(type: FileType.media)`
- Mostrar preview de imagen seleccionada
- Guardar ruta en el campo `rutaArchivo`

### TAREA-008 [P1] — "Crear Arreglo" en Solfa Sheet
**Asignado**: @dev  
**Descripción**: Integrar la opción "Crear Arreglo Personalizado" dentro del sheet de Solfa (no solo en PopupMenu).  
**Archivos**: `lib/presentation/views_personal/hymn_scroll/hymn_detail_screen.dart` (método _showSolfaSheet)  
**Dependencias**: Ninguna  
**Detalles**:
- Agregar ListTile "Crear Arreglo Personalizado" al final del sheet Solfa
- Al presionar, navegar a ArrangementEditorScreen

### TAREA-009 [P2] — Admin: Hamburger Menu en AdminPanelScreen
**Asignado**: @design  
**Descripción**: Cambiar AdminPanelScreen de ListView simple a Drawer (hamburger menu) con las opciones: "Himnos" (hoja+lápiz) y "Herramientas" (catálogos).  
**Archivos**: `lib/presentation/views_admin/admin_panel_screen.dart`  
**Dependencias**: Ninguna  
**Detalles**:
- Drawer con Icon(Icons.edit_note) + "Administrar Himnos" → HymnListScreen
- Drawer con Icon(Icons.build) + "Catálogos" → CatalogPanelScreen
- Mantener AppBar con título y logout button

### TAREA-010 [P2] — DiscoveryProviders y ConnectionRole
**Asignado**: @dev  
**Descripción**: Refactorizar sistema de conexión para soportar roles (emisor/receptor). Mejorar `ConnectionState` con `ConnectionRole`.  
**Archivos**: `lib/core/network/connection_state.dart`, `lib/presentation/views_projection/providers/connection_providers.dart`  
**Dependencias**: TAREA-002  
**Detalles**:
- Agregar `role` a `Connected` state
- Modificar `ConnectionNotifier` para setear rol al conectar
- Ajustar UI según rol

### TAREA-011 [P3] — Detección automática de plataforma en release
**Asignado**: @dev  
**Descripción**: En `DualModeNotifier._detectInitialMode()`, implementar detección real usando `dart:io` Platform o `dart:html` / `UniversalPlatform`.  
**Archivos**: `lib/presentation/dual_mode_wrapper/dual_mode_providers.dart`  
**Dependencias**: Ninguna  
**Detalles**:
- Usar `Platform.isLinux || Platform.isMacOS || Platform.isWindows` → desktop
- Usar `kIsWeb` para web (desktop behavior)
- Default: phone

---

## 3. MAPA DE RUTAS

```
Sprint 4.1 (Core - P0/P1):
├── TAREA-001: Candado en HomeScreen [dev] 
├── TAREA-002: Selector Emisor/Receptor [dev+design]
├── TAREA-003: DesktopWindowService real [dev] ← bloqueante
├── TAREA-004: Integración Present + Hymn nav [dev] ← depende de 003
├── TAREA-005: MinimalControlScreen funcional [dev]
└── TAREA-006: SimpleProjectionView [dev]

Sprint 4.2 (Features - P1/P2):
├── TAREA-007: File Picker Fondos [dev]
├── TAREA-008: "Crear Arreglo" en Solfa [dev]
├── TAREA-009: Hamburger Menu Admin [design]
└── TAREA-010: Refactor ConnectionRole [dev]

Sprint 4.3 (Polish - P3):
├── TAREA-011: Detección plataforma [dev]
├── QA: Tests para nuevas features [qa]
└── dart analyze: 0 errors, 0 warnings, 0 info
```

---

## 4. REGLAS PARA TODOS LOS AGENTES

1. **`dart analyze lib/` debe dar 0 errores, 0 warnings, 0 info** después de cada cambio
2. **Programación funcional**: constructores `const`, widgets inmutables, `if`/`for` de colección
3. **Sin colores hardcodeados**: usar siempre `colorScheme` y `textTheme` de Material Design 3
4. **Comentarios concisos**: solo lo necesario, en inglés o español consistente
5. **Riverpod manual**: sin riverpod_annotation, usar StateNotifierProvider manual
6. **Freezed para entidades**: todas las entities deben ser Freezed
7. **Context7 style**: widgets inmutables, evitar StatefulWidget cuando se pueda
