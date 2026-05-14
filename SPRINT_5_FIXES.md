# SPRINT 5.2 — Plan de Corrección: IPC entre ventanas + QA

> **Fecha:** 2026-05-14
> **Arquitecto:** @arqui
> **Contexto:** HimnarioID 2.0 — 2 problemas identificados tras revisión técnica

---

## Índice

1. [Resumen Ejecutivo](#1-resumen-ejecutivo)
2. [Problema 1 — Segunda ventana no recibe himnos (CRÍTICO)](#2-problema-1--segunda-ventana-no-recibe-himnos-crítico)
3. [Problema 2 — Issues menores de QA (5 items)](#3-problema-2--issues-menores-de-qa-5-items)
4. [Plan de Implementación Detallado](#4-plan-de-implementación-detallado)
5. [Archivos Afectados](#5-archivos-afectados)
6. [Delegación de Tareas](#6-delegación-de-tareas)
7. [Protocolo de Comunicación JSON (stdin/stdout)](#7-protocolo-de-comunicación-json-stdinstdout)

---

## 1. Resumen Ejecutivo

Tras el análisis del código fuente de HimnarioID 2.0, se identificaron **2 problemas** que requieren corrección inmediata:

| # | Problema | Prioridad | Tipo | Causa Raíz |
|---|----------|-----------|------|------------|
| 1 | Segunda ventana no recibe himnos | **CRÍTICO** | IPC faltante | `SubprocessWindowService` lanza un segundo proceso vía `Process.start` pero **no escribe datos a su stdin**. El segundo proceso (`ProjectionApp`) muestra `StandbyScreen` permanente porque su `liveControlProvider` nunca se actualiza — el provider está en otro espacio de memoria. |
| 2 | Issues menores de QA (5 items) | **Alta** | Calidad | Tests faltantes, colores hardcodeados, `context.mounted` ausente, `ref.listenManual` en `build()`, issues de estilo dart analyze. |

**Solución Problema 1**: Establecer un protocolo de comunicación vía stdin/stdout entre el proceso principal y el proceso hijo de proyección usando JSON delimitado por newline (`\n`).

---

## 2. Problema 1 — Segunda ventana no recibe himnos (CRÍTICO)

### Síntoma
Al presionar "Presentar" se abre una segunda ventana (proceso separado con `--projection`), pero esta ventana siempre muestra `StandbyScreen` aunque el usuario cargue un himno en la ventana principal.

### Causa Raíz
`SubprocessWindowService.openProjectionWindow()` en `window_service.dart` lanza un segundo proceso vía `Process.start()`:
```dart
_projectionProcess = await Process.start(
  Platform.resolvedExecutable,
  ['--projection'],
  workingDirectory: Directory.current.path,
);
```

Este proceso ejecuta `main()` con `args.contains('--projection')`, que inicia `ProjectionApp`. Pero **no existe ningún mecanismo de comunicación** entre los dos procesos:
- ❌ No se escribe nada al `stdin` del proceso hijo
- ❌ No se lee el `stdout` del proceso hijo (solo se escucha para logging)
- ❌ `ProjectionApp` tiene su propio `ProviderContainer` con `LiveControlNotifier` vacío
- ❌ La ventana principal escribe a su propio `liveControlProvider`, no al del hijo

### Estado actual de los archivos

#### `SubprocessWindowService` (window_service.dart:115-175)
- ✅ Lanza proceso con `Process.start(Platform.resolvedExecutable, ['--projection'])`
- ✅ Escucha `stdout` y `stderr` para logging (pero no parsea)
- ✅ Escucha `exitCode` para detectar cierre
- ❌ **No tiene método `sendMessage()`**
- ❌ **No guarda referencia al `stdin` del proceso hijo**

#### `ProjectionApp` (projection_app.dart:18-43)
- ✅ Es un `ConsumerWidget` que escucha `liveControlProvider`
- ✅ Muestra `LiveProjectionScreen` si `liveState.hymn != null`, o `StandbyScreen` si no
- ❌ **No escucha `stdin`** para recibir comandos del proceso padre
- ❌ Muestra `StandbyScreen` permanentemente (no hay quien actualice `liveControlProvider`)

#### `LiveControlNotifier` (live_control_providers.dart:97-174)
- ✅ Tiene todos los métodos necesarios: `loadHymn()`, `nextStanza()`, `prevStanza()`, `goToStanza()`, `toggleBlackout()`
- ✅ Tiene `updateFromServer()` para recibir estado externo
- ❌ No se usa desde el proceso padre

#### `main.dart` (main.dart:18-62)
- ✅ Maneja el flag `--projection` para lanzar `ProjectionApp`
- ✅ Crea su propio `ProviderContainer`

#### `_selectHymnForProjection()` (home_screen.dart:65-92)
- ✅ Carga el himno en `liveControlProvider` local
- ❌ Tiene comentario: "El envío a la 2da ventana se maneja en la capa de comunicación (Sprint 5.2)"
- ❌ **No llama a `windowService.sendMessage()`**

#### `PresentControlBar` (present_control_bar.dart)
- ✅ Navegación prev/next actualiza `liveControlProvider` local
- ❌ **No envía comandos a la 2da ventana**

### Solución — Comunicación vía stdin/stdout (JSON protocol)

Se implementará un protocolo de mensajes JSON delimitados por newline (`\n`) entre el proceso principal (padre) y el proceso de proyección (hijo).

```
┌──────────────────────────────┐     ┌──────────────────────────────┐
│   VENTANA PRINCIPAL          │     │   VENTANA DE PROYECCIÓN      │
│   (SubprocessWindowService)  │     │   (ProjectionApp)             │
│                              │     │                              │
│  sendMessage({...}) ─────────┼────>│  stdin listener              │
│                              │     │  parse JSON → update provider │
│                              │     │                              │
│  stdout listener <───────────┼─────│  sendResponse({...})         │
└──────────────────────────────┘     └──────────────────────────────┘
```

#### Cambios necesarios

##### 1. `window_service.dart` — Agregar `sendMessage()` y soporte IPC

```dart
class SubprocessWindowService implements WindowService {
  Process? _projectionProcess;
  StreamController<WindowEvent> _eventController = ...;
  
  /// StreamController para mensajes entrantes desde el proceso hijo
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream de mensajes recibidos desde el proceso hijo
  Stream<Map<String, dynamic>> get onChildMessage => _messageController.stream;

  @override
  Future<void> openProjectionWindow(Map<String, dynamic> args) async {
    if (_projectionProcess != null) return;
    
    _projectionProcess = await Process.start(
      Platform.resolvedExecutable,
      ['--projection'],
      workingDirectory: Directory.current.path,
    );

    // Escuchar stdout del hijo (respuestas)
    _projectionProcess!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      try {
        final message = jsonDecode(line) as Map<String, dynamic>;
        _messageController.add(message);
      } catch (_) {}
    });

    // Escuchar stderr para logging
    _projectionProcess!.stderr.listen((data) {
      // log
    });

    _projectionProcess!.exitCode.then((code) {
      _projectionProcess = null;
      _eventController.add(const WindowEvent(type: WindowEventType.closed));
    });

    _eventController.add(WindowEvent(type: WindowEventType.opened, data: args));
  }

  /// Envía un mensaje JSON al proceso hijo a través de su stdin.
  Future<void> sendMessage(Map<String, dynamic> message) async {
    if (_projectionProcess == null) return;
    final jsonLine = '${jsonEncode(message)}\n';
    _projectionProcess!.stdin.write(jsonLine);
  }

  @override
  Future<void> closeProjectionWindow() async {
    if (_projectionProcess != null) {
      _projectionProcess!.kill();
      _projectionProcess = null;
    }
    _eventController.add(const WindowEvent(type: WindowEventType.closed));
  }
}
```

##### 2. `WindowService` abstract — Agregar `sendMessage()` al contrato

```dart
abstract class WindowService {
  Future<void> openProjectionWindow(Map<String, dynamic> args);
  Future<void> closeProjectionWindow();
  Future<void> sendMessage(Map<String, dynamic> message); // NUEVO
  Stream<WindowEvent> get onWindowEvent;
}
```

Implementar `sendMessage` como no-op en `DesktopWindowService`, `WebWindowService`, `MobileWindowService`.

##### 3. `projection_app.dart` — Escuchar stdin

```dart
class ProjectionApp extends ConsumerStatefulWidget {
  const ProjectionApp({super.key});
  @override
  ConsumerState<ProjectionApp> createState() => _ProjectionAppState();
}

class _ProjectionAppState extends ConsumerState<ProjectionApp> {
  StreamSubscription<String>? _stdinSubscription;

  @override
  void initState() {
    super.initState();
    _listenToStdin();
  }

  void _listenToStdin() {
    _stdinSubscription = stdin
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      try {
        final message = jsonDecode(line) as Map<String, dynamic>;
        _handleMessage(message);
      } catch (e) {
        // Ignorar mensajes mal formados
      }
    });
  }

  void _handleMessage(Map<String, dynamic> message) {
    final notifier = ref.read(liveControlProvider.notifier);
    switch (message['type'] as String?) {
      case 'LOAD_HYMN':
        final himnoJson = message['himno'] as Map<String, dynamic>;
        final estrofasJson = message['estrofas'] as List<dynamic>;
        final himno = Himno.fromJson(himnoJson);
        final estrofas = estrofasJson.map((e) => Estrofa.fromJson(e as Map<String, dynamic>)).toList();
        notifier.loadHymn(himno, estrofas);
        break;
      case 'NEXT_STANZA':
        notifier.nextStanza();
        break;
      case 'PREV_STANZA':
        notifier.prevStanza();
        break;
      case 'GO_TO_STANZA':
        final index = message['index'] as int;
        notifier.goToStanza(index);
        break;
      case 'SET_CONFIG':
        // TODO: manejar configuración si es necesario
        break;
      case 'BLACKOUT':
        final enabled = message['enabled'] as bool;
        if (enabled) {
          notifier.blackout();
        } else {
          notifier.toggleBlackout(); // o un método específico
        }
        break;
      default:
        // Mensaje desconocido
    }
  }

  @override
  void dispose() {
    _stdinSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... mismo build que antes
  }
}
```

##### 4. `home_screen.dart` — Conectar `_selectHymnForProjection()` a `sendMessage()`

```dart
Future<void> _selectHymnForProjection(
  BuildContext context,
  WidgetRef ref,
  Himno himno,
) async {
  try {
    final repo = ref.read(hymnRepositoryProvider);
    final himnoCompleto = await repo.getHymnById(himno.id);
    final versionPaisId = himnoCompleto.primaryVersionPaisId;
    final estrofas = await repo.getStanzas(versionPaisId);

    // 1. Cargar en liveControlProvider local (actualiza PresentControlBar)
    ref.read(liveControlProvider.notifier).loadHymn(
          himnoCompleto,
          estrofas,
          versionPaisId: versionPaisId,
        );

    // 2. Enviar a la 2da ventana vía WindowService.sendMessage()
    final windowService = ref.read(windowServiceProvider);
    await windowService.sendMessage({
      'type': 'LOAD_HYMN',
      'himno': himnoCompleto.toJson(),
      'estrofas': estrofas.map((e) => e.toJson()).toList(),
    });

  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar himno: $e')),
      );
    }
  }
}
```

Nota: Asume que `Himno.toJson()` y `Estrofa.toJson()` existen. Si no existen, se deberán implementar o pasar los campos manualmente.

##### 5. `present_control_bar.dart` — Conectar navegación a `sendMessage()`

En `_buildNavigationRow`, después de modificar `liveControlProvider`, enviar el comando a la 2da ventana:

```dart
// En prevStanza:
ref.read(liveControlProvider.notifier).prevStanza();
ref.read(windowServiceProvider).sendMessage({'type': 'PREV_STANZA'});

// En nextStanza:
ref.read(liveControlProvider.notifier).nextStanza();
ref.read(windowServiceProvider).sendMessage({'type': 'NEXT_STANZA'});
```

##### 6. `present_control_bar.dart` — Conectar blackout a `sendMessage()`

```dart
// En toggle blackout:
ref.read(liveControlProvider.notifier).toggleBlackout();
ref.read(windowServiceProvider).sendMessage({
  'type': 'BLACKOUT',
  'enabled': !liveState.isBlackout,
});
```

---

## 3. Problema 2 — Issues menores de QA (5 items)

### #1 — Faltan tests para SimpleProjectionView
**Archivo**: `test/` (nuevo)
**Qué hacer**: Crear tests unitarios/widget para `SimpleProjectionView`.
**Agente**: @dev

Tests a cubrir:
- Renderiza título del himno
- Muestra loading indicator mientras carga estrofas
- Muestra mensaje "sin versiones" cuando `primaryVersionPaisId < 0`
- Muestra navegación prev/next cuando hay estrofas
- Botón siguiente avanza a siguiente estrofa
- Botón anterior retrocede a estrofa anterior
- Muestra mensaje de error cuando el provider falla

### #2 — Colors.orange hardcodeado en standby_screen.dart
**Archivo**: `lib/presentation/views_projection/display/standby_screen.dart`
**Líneas**: 151, 163, 169
**Problema**: `Colors.orange` usado directamente en lugar de `colorScheme`.
**Agente**: @design

```dart
// ❌ Línea 151:
color: Colors.orange.withValues(alpha: 0.4),
// ❌ Línea 163:
color: Colors.orange,
// ❌ Línea 169:
color: Colors.orange,

// ✅ Reemplazar con colorScheme:
// Usar colorScheme.tertiary o colorScheme.error (para advertencia)
color: colorScheme.tertiary.withValues(alpha: 0.4),  // línea 151
color: colorScheme.tertiary,                          // línea 163
color: colorScheme.tertiary,                          // línea 169
```

### #3 — Navigator.pop sin context.mounted en discover_display_sheet.dart
**Archivo**: `lib/presentation/views_projection/controller/widgets/discover_display_sheet.dart`
**Línea**: 88
**Problema**: `Navigator.pop(context)` sin verificar `context.mounted`.
**Agente**: @dev

```dart
// ❌ Línea 88:
Navigator.pop(context);

// ✅:
if (context.mounted) Navigator.pop(context);
```

### #4 — ref.listenManual en build() en minimal_control_screen.dart
**Archivo**: `lib/presentation/views_projection/controller/minimal_control_screen.dart`
**Línea**: 29
**Problema**: `ref.listenManual` se usa dentro del método `build()`. Según la documentación de Riverpod, `ref.listenManual` está diseñado para usarse fuera del `build` (como en `initState`). En `build` se debe usar `ref.listen`.
**Agente**: @dev

```dart
// ❌ Línea 29 — ANTIGUO (listenManual en build):
ref.listenManual(hymnDetailProvider(hymnId), (prev, next) { ... });

// ✅ NUEVO — ref.listen en build (es seguro según docs de Riverpod):
ref.listen(hymnDetailProvider(hymnId), (prev, next) { ... });
```

**Fundamentación**: 
- La documentación oficial de Riverpod dice: *"It is safe to use WidgetRef.listen inside the build method of a widget. This is how the method is designed to be used. If you want to listen to providers outside of build (such as State.initState), use WidgetRef.listenManual instead."*
- `ref.listenManual` en `build()` es un anti-pattern porque puede causar fugas de memoria y comportamiento inesperado.

### #5 — 37 info issues de estilo
**Contexto**: `dart analyze lib/` reporta 37 info-level issues.
**Agente**: @dev

**Solución**: Ejecutar `dart fix --apply` y revisar manualmente los cambios.

```bash
cd /home/melquisedec/Escritorio/Projects/Personales/HimnarioID_2.0
dart fix --dry-run    # ver qué cambios se harán
dart fix --apply      # aplicar cambios automáticos
dart analyze lib/     # verificar resultado
```

---

## 4. Plan de Implementación Detallado

### Fase 1: IPC entre ventanas (Problema 1 — CRÍTICO)
| # | Tarea | Responsable | Archivos |
|---|-------|-------------|----------|
| 1.1 | Agregar `sendMessage()` al contrato `WindowService` abstract | @dev | `window_service.dart` |
| 1.2 | Implementar `sendMessage()` en `SubprocessWindowService` (escribe JSON a stdin) + escuchar stdout | @dev | `window_service.dart` |
| 1.3 | Implementar `sendMessage()` no-op en `DesktopWindowService`, `WebWindowService`, `MobileWindowService` | @dev | `window_service.dart` |
| 1.4 | Refactorizar `ProjectionApp` a `ConsumerStatefulWidget` para escuchar stdin en `initState` | @dev | `projection_app.dart` |
| 1.5 | Implementar `_handleMessage()` con switch de tipos de mensaje | @dev | `projection_app.dart` |
| 1.6 | Conectar `_selectHymnForProjection()` en `home_screen.dart` a `windowService.sendMessage()` | @dev | `home_screen.dart` |
| 1.7 | Conectar navegación prev/next en `PresentControlBar` a `windowService.sendMessage()` | @dev | `present_control_bar.dart` |
| 1.8 | Agregar `dart:convert` y `dart:io` imports donde falten | @dev | `window_service.dart`, `projection_app.dart` |
| 1.9 | Verificar que `Himno.toJson()` y `Estrofa.toJson()` existan en las entidades (o usar fromJson manual) | @dev | dominio/entidades |

### Fase 2: QA fixes (Problema 2)
| # | Tarea | Responsable | Archivos |
|---|-------|-------------|----------|
| 2.1 | Crear tests para `SimpleProjectionView` | @dev | `test/widget/simple_projection_view_test.dart` |
| 2.2 | Reemplazar `Colors.orange` con `colorScheme.tertiary` en standby_screen.dart | @design | `standby_screen.dart` |
| 2.3 | Agregar `context.mounted` check en `discover_display_sheet.dart:88` | @dev | `discover_display_sheet.dart` |
| 2.4 | Reemplazar `ref.listenManual` por `ref.listen` en `minimal_control_screen.dart:29` | @dev | `minimal_control_screen.dart` |
| 2.5 | Ejecutar `dart fix --apply` y verificar resultado | @dev | múltiples archivos |

### Fase 3: Verificación (@qa)
| # | Tarea | Responsable |
|---|-------|-------------|
| 3.1 | Verificar que `dart analyze lib/` da 0 errors/warnings/info | @qa |
| 3.2 | Ejecutar `flutter test` (tests existentes + nuevos) | @qa |
| 3.3 | Verificar que la 2da ventana recibe himnos correctamente | @qa |
| 3.4 | Verificar modo phone sigue funcionando (regresión) | @qa |
| 3.5 | Verificar que los colores hardcodeados fueron reemplazados | @qa |

---

## 5. Archivos Afectados

### Modificaciones Directas

| Archivo | Problema | Cambio |
|---------|----------|--------|
| `lib/core/window_manager/window_service.dart` | #1 | Agregar `sendMessage()` al abstract + implementar en `SubprocessWindowService` |
| `lib/presentation/views_projection/display/projection_app.dart` | #1 | Refactor a `ConsumerStatefulWidget` + escuchar stdin + `_handleMessage()` |
| `lib/presentation/views_personal/dashboard/home_screen.dart` | #1 | Conectar `_selectHymnForProjection()` a `windowService.sendMessage()` |
| `lib/presentation/views_projection/controller/present_control_bar.dart` | #1 | Conectar navegación a `windowService.sendMessage()` |
| `lib/presentation/views_projection/display/standby_screen.dart` | #2.2 | Reemplazar `Colors.orange` con `colorScheme.tertiary` |
| `lib/presentation/views_projection/controller/widgets/discover_display_sheet.dart` | #2.3 | Agregar `context.mounted` check |
| `lib/presentation/views_projection/controller/minimal_control_screen.dart` | #2.4 | Reemplazar `ref.listenManual` por `ref.listen` |

### Archivos Nuevos

| Archivo | Propósito |
|---------|-----------|
| `test/widget/simple_projection_view_test.dart` | Tests para SimpleProjectionView |

---

## 6. Delegación de Tareas

### @dev — Prioridad CRÍTICA

```
FASE 1 (IPC — CRÍTICO):
  [P0] 1.1-1.3: sendMessage() en WindowService + SubprocessWindowService
  [P0] 1.4-1.5: ProjectionApp escucha stdin + handleMessage()
  [P0] 1.6: Conectar _selectHymnForProjection() a sendMessage()
  [P0] 1.7: Conectar PresentControlBar navegación a sendMessage()
  [P0] 1.8: Imports necesarios
  [P0] 1.9: Verificar toJson() en entidades

FASE 2 (QA — ALTA):
  [P1] 2.1: Tests para SimpleProjectionView
  [P1] 2.3: context.mounted check en discover_display_sheet.dart
  [P1] 2.4: ref.listenManual → ref.listen en minimal_control_screen.dart
  [P1] 2.5: dart fix --apply

VERIFICACIÓN:
  [P0] dart analyze lib/ → 0 errors/warnings/info
  [P0] flutter test → todos los tests pasan
```

### @design — Prioridad ALTA

```
FASE 2 (QA — ALTA):
  [P1] 2.2: Reemplazar Colors.orange con colorScheme.tertiary en standby_screen.dart
       Líneas: 151, 163, 169
       Usar colorScheme.tertiary (para indicador de warning/no-disponible)
       Verificar contraste con fondo negro
```

### @qa — Después de que @dev y @design terminen

```
FASE 3 (VERIFICACIÓN):
  [P0] 3.1: dart analyze lib/ → 0 errors/warnings/info
  [P0] 3.2: flutter test → todos los tests pasan
  [P0] 3.3: Verificar IPC funcional (2da ventana recibe himnos)
  [P0] 3.4: Regresión modo phone
  [P1] 3.5: Verificar colores no hardcodeados
```

---

## 7. Protocolo de Comunicación JSON (stdin/stdout)

### Formato
Mensajes JSON delimitados por newline (`\n`).
Cada mensaje es una línea JSON independiente.

### Mensajes Principal → Proyección (stdin del hijo)

```json
// Cargar un himno completo
{"type": "LOAD_HYMN", "himno": {"id": 1, "titulo": "...", ...}, "estrofas": [{"contenido": "...", ...}]}

// Navegación
{"type": "NEXT_STANZA"}
{"type": "PREV_STANZA"}
{"type": "GO_TO_STANZA", "index": 2}

// Configuración
{"type": "SET_CONFIG", "backgroundColor": "#000000", "fontSize": 24}

// Blackout
{"type": "BLACKOUT", "enabled": true}
```

### Mensajes Proyección → Principal (stdout del hijo) — futuro
```json
{"type": "WINDOW_CLOSED"}
{"type": "KEY_PRESSED", "key": "ArrowRight"}
{"type": "ACK", "messageType": "LOAD_HYMN", "status": "ok"}
```

---

## Referencias

1. [Riverpod docs — Ref.listen vs listenManual](https://github.com/rrousselgit/riverpod/blob/master/website/docs/concepts2/refs.mdx)
2. [Dart Process.start API](https://api.dart.dev/stable/dart-io/Process/start.html)
3. [Dart Stream transformations](https://dart.dev/libraries/async/using-streams)
4. [Dart stdin API](https://api.dart.dev/stable/dart-io/stdin.html)

---

## Notas Adicionales

- **`SubprocessWindowService` ya existe y funciona** — solo falta agregar `sendMessage()` y la escucha de stdin en `ProjectionApp`.
- **No se requiere cambiar el mecanismo de creación de ventanas** — el proceso separado ya se lanza correctamente.
- **Las entidades `Himno` y `Estrofa`** deben tener métodos `toJson()` y `fromJson()`. Si no existen, se deben agregar o pasar los campos manualmente en los mensajes.
- **El orden de implementación recomendado**: Fase 1 completa (IPC), luego Fase 2 (QA). No mezclar.
- **`dart fix --apply`** debe ejecutarse DESPUÉS de los cambios de código, no antes, para evitar conflictos.

---

*Fin de SPRINT_5_FIXES.md — 14 de mayo de 2026*
