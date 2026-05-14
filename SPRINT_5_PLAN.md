# Sprint 5 — Plan de Implementación: Corrección del Modo PC

## Estado: RE-ANÁLISIS DE MODO PC COMPLETO

---

## 1. ADVERTENCIA: Error en Sprint 4

El análisis de brechas del Sprint 4 **no captó correctamente la visión del usuario para el modo PC**. Se asumió que la PC solo actuaba como receptor/proyector, pero `mi_idea.txt` es claro:

> **"La app en mi pc: lo mismo que en la app del celular"**

La PC tiene la **misma interfaz personal** que el celular (buscador, lista de himnos, candado, conexión) **ADEMÁS** de un botón "Presentar". No es solo un receptor pasivo.

### Errores del Sprint 4 que este plan corrige:

| # | Lo que dijo Sprint 4 | Lo que realmente dice mi_idea.txt | Impacto |
|---|---------------------|-----------------------------------|---------|
| 1 | "Desktop sin Present → StandbyScreen" | "Desktop sin Present → HomeScreen (igual que celular)" | **CRÍTICO**: Usuario ve pantalla negra cuando debería ver su himnario |
| 2 | "DesktopWindowService convierte ventana actual en proyector" | "Presentar abre una **pestaña independiente** (2da ventana) para el proyector" | **CRÍTICO**: No se puede arrastrar a otra pantalla |
| 3 | "Present + himno → LiveControlScreen (pantalla completa)" | "Present + himno → 2da ventana proyecta + pantalla principal se convierte en **panel de control** (como el del emisor)" | **ALTO**: El control debe ser un overlay, no reemplazar la pantalla |
| 4 | "StandbyScreen es para modo desktop" | "StandbyScreen es para **Modo Receptor** (cuando seleccionas 'Receptor' en el diálogo de conexión)" | **ALTO**: StandbyScreen mal posicionado |

---

## 2. RE-ANÁLISIS DETALLADO: Modo PC vs mi_idea.txt (líneas 27-41)

### Línea 27-30: "La app en mi pc: lo mismo que en la app del celular..."

```
"lo mismo que en la app del celular, la barra de busqueda, el icono de candado,
 el icono de conexión, las alabanzas debajo de la barra de busqueda y a
 diferencia de la interfaz de celular tendrá en la parte inferior derecha
 un botón de presentar"
```

**Estado actual**: 🟡 PARCIAL
- ✅ HomeScreen tiene: AppBar con título + candado + conexión + buscador + filtros + lista de himnos
- ✅ PresentButton existe como FAB en desktop
- ❌ **Cuando `isDesktop && !isPresenting`**, `himnario_dual_app.dart` muestra `StandbyScreen()` en lugar de `HomeScreen()`
- ❌ La lógica `if (isDesktop) StandbyScreen()` en el home Stack ignora que la PC debe mostrar HomeScreen igual que el celular

**Qué debería pasar**: Cuando la PC está en modo normal (sin Presentar activo, sin rol de conexión), debe mostrar `HomeScreen` exactamente igual que el modo phone. StandbyScreen solo debe aparecer cuando el usuario ha seleccionado explícitamente "Receptor" en el diálogo de conexión.

### Línea 34-35: "hago clic sobre el botón de presentar..."

```
"hago clic sobre el botón de presentar y al darle clic a una alabanza
 la alabanza se mostrará en la segunda ventana en modo presentación
 (titulo, estrofa, coro, estrofa, coro, amén) y en mi pantalla principal
 de la app me mostrará un control igual que el control que describí
 cuando el celular actua como emisor"
```

**Estado actual**: ❌ INCORRECTO
- ✅ PresentButton togglea `isPresentingProvider`
- ✅ Cuando `isPresenting && isDesktop`, el tap de un himno llama `_selectHymnForProjection()`
- ❌ `_selectHymnForProjection()` navega a `/live-control` (que es una pantalla COMPLETA tipo LiveControlScreen con panel de preview, botón gigante SIGUIENTE, etc.)
- ❌ **NO abre una segunda ventana** — solo configura la ventana actual en modo fullscreen
- ❌ El control que debería mostrarse es un **panel simple** (como MinimalControlScreen) integrado en la misma HomeScreen, no una pantalla separada

**Qué debería pasar**:
1. Usuario presiona "Presentar" → se abre una **segunda ventana** (negra, sin decoraciones)
2. Usuario ve el HomeScreen normal con un indicador "Presentando..." en la parte superior
3. Usuario toca un himno → el himno aparece en la 2da ventana en modo presentación
4. La HomeScreen muestra un **control panel** en la parte inferior (prev/next, brocha, solfa, nota, lupa, salir)
5. El control panel NO reemplaza la HomeScreen — es un overlay/bottom bar

### Línea 36: "si abro la alabanza sin haber dado clic sobre el botón de presentar..."

```
"si abro la alabanza sin haber dado clic sobre el botón de presentar
 que abre la nueva pestaña, el himno se abre en mi pesataña principal,
 pero solo puedo avanzar y retroceder en modo presentación, no puedo
 editar la apariencia ni otro aspecto de la presentación"
```

**Estado actual**: ✅ CORRECTO (pero solo funciona si el home Stack se arregla)
- ✅ `himnario_dual_app.dart` ruta `/hymn-detail` verifica `isDesktop && !isPresenting` y usa `SimpleProjectionView`
- ✅ `SimpleProjectionView` solo tiene prev/next, sin FAB, sin controles
- ❌ Pero como el home Stack está mal, el usuario nunca llega a esta ruta desde desktop

**Qué debería pasar**: Una vez arreglado el home Stack, cuando el usuario está en HomeScreen (desktop, sin Presentar) y toca un himno, se navega a `/hymn-detail` que muestra SimpleProjectionView. Esto funciona pero está bloqueado por el home Stack incorrecto.

### Línea 38: "si hago clic sobre el icono de conexión..."

```
"si hago clic sobre el icono de conexión siempre tengo las dos opciones,
 emisor y receptor, si hago clic sobre emisor, mostrará la pantalla de
 esperando a que un dispositivo se conecte, y al tener un emisor conectado
 mostrará un fondo negro, esperando a que el usuario elija la alabanza"
```

**Estado actual**: 🟡 PARCIAL
- ✅ `DiscoverDisplaySheet` ya tiene selector Emisor/Receptor
- ✅ Al seleccionar "Emisor" → muestra escaneo de dispositivos
- ✅ Al seleccionar "Receptor" → cierra sheet, establece `ConnectionRole.receiver`
- ❌ Pero `HomeScreen` verifica `role == ConnectionRole.receiver` y muestra `ConnectedDashboard` (un simple texto "Modo Receptor activo") en lugar de `StandbyScreen` (que tiene info de servidor gRPC, animación de pulso, etc.)
- ❌ `StandbyScreen` actualmente se muestra para TODO desktop, no solo cuando es receptor

**Qué debería pasar**: 
- Cuando `role == receiver`, debe mostrarse `StandbyScreen` (conectada al binding del servidor gRPC)
- Cuando `role == emitter`, debe mostrarse `ConnectedDashboard` (que ya funciona)
- Cuando no hay rol (`role == none`), debe mostrarse `HomeScreen`

### Línea 40: "El ícono del candado se mantiene..."

**Estado actual**: ✅ CORRECTO
- ✅ Candado en AppBar leading de HomeScreen
- ✅ Navega a LoginScreen o AdminPanelScreen según auth

---

## 3. NUEVO DIAGRAMA DE FLUJO CORREGIDO (Modo PC)

```
┌─────────────────────────────────────────────────────────────────┐
│                    himnario_dual_app.dart (home)                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─ isPresenting == true ──────────────────────────────────┐    │
│  │  → HomeScreen + PresentOverlay (control bar at bottom)  │    │
│  │  → 2nd window open with projection                      │    │
│  │  → hymn tap: project to 2nd window, update control bar  │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌─ isDesktop && !isPresenting ────────────────────────────┐    │
│  │  → HomeScreen (same as phone) + PresentButton (FAB)     │    │
│  │  → hymn tap: SimpleProjectionView (prev/next only)      │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  ┌─ isPhone ───────────────────────────────────────────────┐    │
│  │  → HomeScreen (without PresentButton)                   │    │
│  │  → hymn tap: HymnDetailScreen (full features)           │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                  │
│  NOTA: ConnectionRole se maneja DENTRO de HomeScreen:           │
│  ┌─ role == receiver → StandbyScreen (gRPC server, black)      │
│  ├─ role == emitter  → ConnectedDashboard (hymn list + emit)   │
│  └─ role == none     → HomeScreen normal                       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. BRECHAS IDENTIFICADAS (Priorizadas)

### PC-01 [P0 — CRÍTICO] Home Stack incorrecto
**Archivos**: `lib/presentation/dual_mode_wrapper/himnario_dual_app.dart`
**Descripción**: El Stack principal muestra StandbyScreen cuando `isDesktop && !isPresenting`. Debe mostrar HomeScreen. StandbyScreen solo debe aparecer basado en `ConnectionRole.receiver`.
**Solución**:
```dart
// En lugar de:
home: Stack(
  children: [
    if (isPresenting) const LiveControlScreen()
    else if (isDesktop) const StandbyScreen()  // ❌ INCORRECTO
    else const HomeScreen(),
    const DeviceSwitch(),
  ],
),

// Debe ser:
home: Stack(
  children: [
    if (isPresenting)
      const HomeScreenWithControl()  // HomeScreen + control panel overlay
    else
      const HomeScreen(),  // HomeScreen para TODOS los modos
    const DeviceSwitch(),
  ],
),
```
**Nota**: El manejo de rol (receptor) se hace DENTRO de HomeScreen, verificando ConnectionRole.

### PC-02 [P0 — CRÍTICO] No existe segunda ventana real
**Archivos**: `lib/core/window_manager/window_service.dart`, `pubspec.yaml`
**Descripción**: `DesktopWindowService.openProjectionWindow()` solo configura la ventana ACTUAL en modo fullscreen. No crea una segunda ventana. Para abrir una ventana independiente se necesita un enfoque diferente.
**Solución propuesta**: Implementar usando `desktop_multi_window` (package) o mediante lanzamiento de un segundo proceso Flutter con argumentos `--projection-mode`.
- Opción A (recomendada): Usar `desktop_multi_window` para crear una segunda ventana Flutter dentro del mismo proceso
- Opción B: Lanzar la app como segundo proceso con `Process.start()` y argumento `--projection`
- Opción C (fallback): Mostrar la proyección en un Popup/Overlay dentro de la misma ventana, con opción de arrastrar a segunda pantalla
**Dependencias**: Investigar qué package usar. `desktop_multi_window` necesita revisión.

### PC-03 [P0 — CRÍTICO] Flujo Present + himno: navega a LiveControlScreen
**Archivos**: `lib/presentation/views_personal/dashboard/home_screen.dart`, `lib/presentation/views_personal/dashboard/present_button.dart`
**Descripción**: Cuando isPresenting=true y se toca un himno, se navega a `/live-control` (LiveControlScreen). Esto reemplaza completamente la HomeScreen. El usuario quiere:
1. Que el himno se muestre en la 2da ventana
2. Que la HomeScreen muestre un panel de control (no que desaparezca)
**Solución**: 
- Modificar `_selectHymnForProjection()` para que NO navegue a `/live-control`
- En su lugar, proyectar el himno a la 2da ventana y actualizar un `presentingControlProvider`
- Crear `PresentControlBar` widget que se muestra como bottom bar/overlay en HomeScreen cuando isPresenting=true
- El control bar debe tener: prev/next, brocha, solfa, nota, lupa, salir (igual que MinimalControlScreen)

### PC-04 [P1 — ALTO] StandbyScreen mal posicionado
**Archivos**: `lib/presentation/views_projection/display/standby_screen.dart`, `lib/presentation/views_personal/dashboard/home_screen.dart`
**Descripción**: 
- StandbyScreen se muestra en el home Stack para desktop (incorrecto)
- Cuando role==receiver, HomeScreen muestra ConnectedDashboard (un placeholder simple) en lugar de StandbyScreen
**Solución**: 
- HomeScreen debe verificar `connectionRoleProvider`:
  - Si `role == ConnectionRole.receiver` → mostrar StandbyScreen (con gRPC server info)
  - Si `role == ConnectionRole.emitter` → mostrar ConnectedDashboard
  - Si `role == ConnectionRole.none` → mostrar contenido normal (buscador + lista)
- Remover StandbyScreen del home Stack en himnario_dual_app.dart

### PC-05 [P1 — ALTO] Control panel para PC Present debe ser overlay, no pantalla separada
**Archivos**: Crear `lib/presentation/views_projection/controller/present_control_bar.dart`
**Descripción**: El control para PC cuando Presenta debe ser una barra/bottom sheet que se superpone a HomeScreen, similar a MinimalControlScreen pero integrada en la misma vista.
**Solución**: 
- Crear `PresentControlBar` widget con: prev/next, brocha, solfa, nota, lupa, salir
- Mostrar como `AnimatedContainer` en la parte inferior de HomeScreen cuando isPresenting=true
- Al presionar "Salir" → detener presentación, cerrar 2da ventana

### PC-06 [P1 — ALTO] gRPC/Socket communication entre ventanas
**Archivos**: `lib/data/datasources/remote/`
**Descripción**: Para que el control en la ventana principal afecte la proyección en la 2da ventana, se necesita comunicación entre procesos/ventanas.
**Solución**: 
- Si se usa `desktop_multi_window`: usar `SendPort`/`ReceivePort` de Flutter
- Si se usa segundo proceso: usar gRPC local (el servidor ya existe en el receptor)
- La 2da ventana escucha comandos (next, prev, blackout, config changes)

### PC-07 [P2 — MEDIO] Unificar flujo Receptor
**Archivos**: `lib/presentation/views_projection/display/receptor_binding.dart`
**Descripción**: Cuando la PC actúa como Receptor y recibe un himno, debe transicionar de StandbyScreen a LiveProjectionScreen. ReceptorBinding ya tiene la escucha pero la navegación no está implementada.
**Solución**: Implementar la transición StandbyScreen → LiveProjectionScreen cuando liveControlProvider detecta un himno cargado.

### PC-08 [P2 — MEDIO] PresentButton debe manejar ciclo de vida de 2da ventana
**Archivos**: `lib/presentation/views_personal/dashboard/present_button.dart`
**Descripción**: El botón Presentar debe:
- Al presionar "Presentar": abrir 2da ventana, establecer isPresenting=true
- Al presionar "Detener": cerrar 2da ventana, establecer isPresenting=false
- Si la 2da ventana se cierra manualmente: detectar y resetear isPresenting=false
**Solución**: Escuchar eventos de la 2da ventana vía Stream.

---

## 5. PLAN DE ACCIÓN — SPRINT 5

### Prioridades
- **P0 (Crítica)**: Bloqueante — sin esto la PC no funciona como el usuario espera
- **P1 (Alta)**: Funcionalidad core faltante
- **P2 (Media)**: Mejora importante de UX

### Mapa de rutas

```
Sprint 5.1 (Core Fixes — P0):
├── T-501: Corregir home Stack (himnario_dual_app.dart)
├── T-502: Integrar StandbyScreen con ConnectionRole.receiver
├── T-503: Crear PresentControlBar (overlay en HomeScreen)
└── T-504: Modificar flujo Present + himno (no navegar a LiveControlScreen)

Sprint 5.2 (2da Ventana — P0/P1):
├── T-505: Implementar 2da ventana real (desktop_multi_window / proceso)
├── T-506: Comunicación entre ventana principal y 2da ventana
└── T-507: Ciclo de vida de PresentButton con 2da ventana

Sprint 5.3 (Polish — P1/P2):
├── T-508: Transición StandbyScreen → LiveProjectionScreen (Receptor)
├── T-509: Refactor HomeScreen para manejar roles correctamente
├── T-510: Pruebas y dart analyze
└── T-511: Documentación y cleanup
```

---

## 6. TAREAS DETALLADAS

### TAREA-501 [P0] — Corregir home Stack en himnario_dual_app.dart
**Archivos**: `lib/presentation/dual_mode_wrapper/himnario_dual_app.dart`
**Descripción**: Reemplazar la lógica del Stack principal. Eliminar StandbyScreen del Stack. HomeScreen debe ser el widget base para TODOS los modos (phone, desktop, desktop+presenting).
**Detalles**:
```dart
// NUEVA LÓGICA (reemplazar el home: Stack actual)
home: Stack(
  children: [
    // HomeScreen es SIEMPRE la base (phone, desktop, desktop+presenting)
    const HomeScreen(),
    
    // Overlay de control cuando se está presentando
    if (isDesktop && isPresenting)
      const _PresentingOverlay(),
    
    // DeviceSwitch siempre visible en debug
    const DeviceSwitch(),
  ],
),
```
- Eliminar import de StandbyScreen (ya no se usa aquí)
- Crear `_PresentingOverlay` widget inline o en archivo separado
- Mantener rutas existentes (/hymn-detail, /live-control, /arrangement-editor)

### TAREA-502 [P0] — Integrar StandbyScreen con ConnectionRole.receiver
**Archivos**: `lib/presentation/views_personal/dashboard/home_screen.dart`, `lib/presentation/views_projection/display/standby_screen.dart`, `lib/presentation/views_projection/display/receptor_binding.dart`
**Descripción**: 
1. En `HomeScreen.build()`, mover el chequeo de `role == ConnectionRole.receiver` arriba y mostrar `StandbyScreen` envuelto en `ReceptorBinding` en lugar de `ConnectedDashboard`
2. Simplificar ConnectedDashboard para solo modo Emisor
3. StandbyScreen actualmente tiene `backgroundColor: Colors.black` y es una pantalla completa — esto está bien para el modo receptor
**Detalles**:
```dart
// En HomeScreen.build(), reemplazar:
if (isConnected || role == ConnectionRole.receiver) {
  return const ConnectedDashboard();
}

// Con:
final role = ref.watch(connectionRoleProvider);
if (role == ConnectionRole.receiver) {
  return const ReceptorBinding(child: StandbyScreen());
}
if (role == ConnectionRole.emitter) {
  return const ConnectedDashboard();
}
```
- ConnectedDashboard solo se muestra cuando role == emitter

### TAREA-503 [P0] — Crear PresentControlBar (overlay widget)
**Archivos**: CREAR `lib/presentation/views_projection/controller/present_control_bar.dart`
**Descripción**: Widget de control que se superpone a HomeScreen cuando isPresenting=true. Tiene los mismos botones que MinimalControlScreen pero integrado como barra inferior.
**Widgets necesarios**:
```
PresentControlBar (ConsumerWidget)
├── Indicador: "Presentando [himno título]" + botón "Salir"
├── Navegación: [← Anterior] [→ Siguiente]
├── Función: [Brocha] [Solfa] [Nota] [Lupa]
└── Conexión con liveControlProvider para comandos
```
**Comportamiento**:
- Al presionar "Salir" → llama a detener presentación (cierra 2da ventana, resetea isPresenting)
- Anterior/Siguiente → navega en liveControlProvider
- Brocha → showBrushSheet (ya existe)
- Solfa → showSolfaSheet (ya existe)
- Nota → showNoteSheet (ya existe)
- Lupa → showSearchSheet (ya existe)
- Los sheets deben modificar la proyección en la 2da ventana (enviar comandos)

### TAREA-504 [P0] — Modificar flujo Present + himno
**Archivos**: `lib/presentation/views_personal/dashboard/home_screen.dart`
**Descripción**: Cuando isPresenting=true y se toca un himno, NO navegar a /live-control. En su lugar:
1. Cargar el himno en liveControlProvider (esto ya se hace)
2. Enviar el himno a la 2da ventana para que lo muestre
3. Actualizar el PresentControlBar con el título del himno
4. NO hacer Navigator.push — mantener HomeScreen visible
**Detalles**: Modificar `_selectHymnForProjection()` para que solo cargue el himno en el provider y envíe a la 2da ventana, sin navegar.

### TAREA-505 [P1] — Implementar 2da ventana real
**Archivos**: `lib/core/window_manager/`, `pubspec.yaml`
**Descripción**: Investigar e implementar la creación de una segunda ventana para proyección.
**Enfoques a evaluar**:

**Opción A: desktop_multi_window** (recomendada)
- Package: https://pub.dev/packages/desktop_multi_window
- Permite crear ventanas Flutter secundarias dentro del mismo proceso
- Comunicación via SendPort/ReceivePort
- Las ventanas secundarias pueden tener su propio widget tree

**Opción B: Lanzar segundo proceso**
- Usar `dart:io` Process.start para lanzar la misma app con `--projection`
- Comunicación via gRPC (el servidor ya existe en ReceptorBinding)
- Más complejo pero más estable

**Opción C: Web (para test)**
- Usar `window.open()` + BroadcastChannel (ya implementado como stub en WebWindowService)
- Funciona para web pero no para desktop nativo

**Implementación**:
1. Agregar dependencia (desktop_multi_window u otro)
2. Refactorizar WindowService para crear verdadera 2da ventana
3. La 2da ventana debe ser: negra, sin decoraciones, mostrar LiveProjectionScreen o StandbyScreen
4. Comunicación bidireccional: comandos desde la principal, eventos desde la secundaria

### TAREA-506 [P1] — Comunicación entre ventanas
**Archivos**: `lib/core/window_manager/` (nuevo archivo de comunicación)
**Descripción**: Establecer canal de comunicación entre la ventana principal y la 2da ventana.
**Canales**:
- Principal → 2da: loadHymn, nextStanza, prevStanza, blackout, configChange
- 2da → Principal: windowClosed, keyPressed, resizeEvent
**Implementación**:
- Si se usa desktop_multi_window: usar `SendPort`/`ReceivePort` con `WindowController.fromApp` y `WindowController.toApp`
- Si se usa gRPC: usar el mismo canal que el modo receptor/emisor
- Crear `ProjectionChannel` service que abstrae la comunicación

### TAREA-507 [P1] — Ciclo de vida PresentButton con 2da ventana
**Archivos**: `lib/presentation/views_personal/dashboard/present_button.dart`
**Descripción**: Mejorar PresentButton para manejar el ciclo de vida completo:
1. Presionar "Presentar": 
   - Crear 2da ventana via WindowService
   - Esperar confirmación de que se abrió
   - Establecer isPresenting=true
   - Cambiar texto a "Detener Presentación"
2. Presionar "Detener": 
   - Cerrar 2da ventana via WindowService
   - Limpiar liveControlProvider
   - Establecer isPresenting=false
3. Detectar cierre inesperado de la 2da ventana:
   - Escuchar eventos del WindowService
   - Si la ventana se cierra sin autorización, resetear estado

### TAREA-508 [P1] — Transición StandbyScreen → LiveProjectionScreen (Receptor)
**Archivos**: `lib/presentation/views_projection/display/receptor_binding.dart`, `lib/presentation/views_projection/display/standby_screen.dart`
**Descripción**: Cuando la PC está en modo Receptor y recibe un himno (via gRPC), debe transicionar automáticamente de StandbyScreen a LiveProjectionScreen.
**Detalles**:
- ReceptorBinding ya escucha liveControlProvider
- Implementar transición: cuando `next.hymn != null && previous?.hymn == null`, navegar o cambiar estado
- Agregar provider `currentDisplayScreenProvider` que alterne entre StandbyScreen y LiveProjectionScreen
- Regresar a StandbyScreen cuando el himno se descargue (hymn == null)

### TAREA-509 [P2] — Refactor HomeScreen para manejo correcto de roles
**Archivos**: `lib/presentation/views_personal/dashboard/home_screen.dart`
**Descripción**: Reorganizar la lógica de HomeScreen para que maneje correctamente los 4 estados del modo dual/PC:
1. Phone normal → mostrar buscador + lista + FAB normal
2. Desktop normal → mostrar buscador + lista + PresentButton
3. Desktop Presentando → mostrar buscador + lista + PresentControlBar overlay
4. Rol Emisor → mostrar ConnectedDashboard
5. Rol Receptor → mostrar StandbyScreen
**Detalles**: La lógica actual tiene if/else anidados que se han vuelto complejos. Refactorizar para claridad.

### TAREA-510 [P2] — Pruebas y dart analyze
**Archivos**: tests existentes + nuevos
**Descripción**: 
- Escribir tests unitarios para PresentControlBar
- Escribir tests para nuevo WindowService
- Escribir tests para la comunicación entre ventanas
- Verificar dart analyze 0 errors/warnings/info

### TAREA-511 [P2] — Cleanup y documentación
**Descripción**: 
- Eliminar archivos/imports no usados
- Actualizar comentarios en archivos modificados
- Verificar que no haya dead code

---

## 7. DEPENDENCIAS ENTRE TAREAS

```
T-501 (home Stack fix) ─── sin dependencias ───→ [PRIMERO]
    │
    ├── T-502 (StandbyScreen rol fix) ─── sin dependencias ───→ [PARALELO con 501]
    │
    ├── T-503 (PresentControlBar) ─── sin dependencias ───→ [PARALELO con 501]
    │
    ├── T-504 (flujo Present+himno) ─── depende de T-503 ───→ [DESPUÉS de 503]
    │
    ├── T-505 (2da ventana real) ─── investigación primero ───→ [PUEDE EMPEZAR TEMPRANO]
    │
    ├── T-506 (comunicación ventanas) ─── depende de T-505 ───→ [DESPUÉS de 505]
    │
    └── T-507 (ciclo vida PresentButton) ─── depende de T-505, T-506 ───→ [AL FINAL]
```

---

## 8. REGLAS PARA TODOS LOS AGENTES

1. **`dart analyze lib/` debe dar 0 errors, 0 warnings, 0 info** después de cada cambio
2. **Programación funcional**: constructores `const`, widgets inmutables, `if`/`for` de colección
3. **Sin colores hardcodeados**: usar siempre `colorScheme` y `textTheme` de Material Design 3. No se tolera `Colors.black` (usar `colorScheme` o `Color(0xFF...)` cuando sea necesario como en StandbyScreen que es intencionalmente negro)
4. **Riverpod manual**: sin riverpod_annotation, usar StateNotifierProvider manual
5. **Freezed para entidades**: todas las entities deben ser Freezed (no aplica para widgets/providers nuevos)
6. **Context7**: consultar documentación de `desktop_multi_window` u otros packages antes de implementar
7. **Testing**: toda nueva funcionalidad debe tener test asociado
8. **No romper funcionalidad existente**: verificar que el modo phone/celular sigue funcionando igual

---

## 9. RESUMEN DE ARCHIVOS A MODIFICAR/CREAR

### Archivos a MODIFICAR:
| Archivo | Tareas |
|---------|--------|
| `lib/presentation/dual_mode_wrapper/himnario_dual_app.dart` | T-501 |
| `lib/presentation/views_personal/dashboard/home_screen.dart` | T-502, T-504, T-509 |
| `lib/presentation/views_personal/dashboard/present_button.dart` | T-507 |
| `lib/presentation/views_projection/display/standby_screen.dart` | T-502, T-508 |
| `lib/presentation/views_projection/display/receptor_binding.dart` | T-508 |
| `lib/core/window_manager/window_service.dart` | T-505 |
| `lib/core/window_manager/window_providers.dart` | T-505 |
| `pubspec.yaml` | T-505 (nueva dependencia) |

### Archivos a CREAR:
| Archivo | Tareas | Descripción |
|---------|--------|-------------|
| `lib/presentation/views_projection/controller/present_control_bar.dart` | T-503 | Control bar overlay para PC Present |
| `lib/core/window_manager/window_channel.dart` | T-506 | Comunicación entre ventanas |

---

## 10. RIESGOS Y MITIGACIONES

| Riesgo | Impacto | Mitigación |
|--------|---------|------------|
| `desktop_multi_window` no funciona en Linux | Alto | Tener plan B: lanzar segundo proceso con gRPC |
| La comunicación entre ventanas es inestable | Alto | Implementar timeouts y reintentos |
| El overlay de control tapa elementos de HomeScreen | Medio | Diseñar PresentControlBar colapsable/ocultable |
| Romper el modo phone/celular | Crítico | Tests de regresión en cada PR |
| dart analyze da errores por imports condicionales | Medio | Usar `kIsWeb` y condicionales correctamente |

---

*Fin del plan Sprint 5 — 14 de mayo de 2026*
