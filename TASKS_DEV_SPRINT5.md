# Tareas para @dev — Sprint 5.2 (IPC + QA)

## ⚠️ LEE PRIMERO: SPRINT_5_FIXES.md

Este sprint implementa comunicación entre procesos (IPC) para que la segunda ventana de proyección reciba himnos, y corrige 5 issues de QA.

---

## INSTRUCCIONES GENERALES

1. **`dart analyze lib/` debe dar 0 errors, 0 warnings, 0 info** después de cada cambio
2. **Riverpod manual**: sin riverpod_annotation, usar StateNotifierProvider manual
3. **Sin colores hardcodeados**: usar siempre `colorScheme` y `textTheme`
4. **Constructores const** cuando sea posible
5. **`.env` y secrets**: No usar, todo configuración en providers
6. **No romper funcionalidad existente**: modo phone/celular debe seguir funcionando

---

## TAREA-DEV-601 [P0 — CRÍTICO] Agregar `sendMessage()` a WindowService

### Archivo
`lib/core/window_manager/window_service.dart`

### Qué hacer
1. Agregar `Future<void> sendMessage(Map<String, dynamic> message)` al abstract class `WindowService`
2. Implementar en `SubprocessWindowService`:
   - Guardar referencia al `stdin` del proceso hijo
   - Método `sendMessage()` que convierte el map a JSON + `\n` y lo escribe al stdin
   - Escuchar `stdout` del hijo con `utf8.decoder` + `LineSplitter` para parsear respuestas JSON
   - Agregar `Stream<Map<String, dynamic>> get onChildMessage` para recibir mensajes del hijo
3. Implementar `sendMessage()` como no-op (vacío) en `DesktopWindowService`, `WebWindowService`, `MobileWindowService`

### Código de referencia
```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io' show Directory, Platform, Process;

abstract class WindowService {
  Future<void> openProjectionWindow(Map<String, dynamic> args);
  Future<void> closeProjectionWindow();
  Future<void> sendMessage(Map<String, dynamic> message); // NUEVO
  Stream<WindowEvent> get onWindowEvent;
}

class SubprocessWindowService implements WindowService {
  Process? _projectionProcess;
  final StreamController<WindowEvent> _eventController = StreamController<WindowEvent>.broadcast();
  final StreamController<Map<String, dynamic>> _messageController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onChildMessage => _messageController.stream;

  @override
  Future<void> openProjectionWindow(Map<String, dynamic> args) async {
    if (_projectionProcess != null) return;
    _projectionProcess = await Process.start(
      Platform.resolvedExecutable,
      ['--projection'],
      workingDirectory: Directory.current.path,
    );

    // Escuchar stdout del hijo para respuestas
    _projectionProcess!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      try {
        final message = jsonDecode(line) as Map<String, dynamic>;
        _messageController.add(message);
      } catch (_) {}
    });

    _projectionProcess!.stderr.listen((data) {});
    _projectionProcess!.exitCode.then((code) {
      _projectionProcess = null;
      _eventController.add(const WindowEvent(type: WindowEventType.closed));
    });
    _eventController.add(WindowEvent(type: WindowEventType.opened, data: args));
  }

  @override
  Future<void> sendMessage(Map<String, dynamic> message) async {
    if (_projectionProcess == null) return;
    final jsonLine = '${jsonEncode(message)}\n';
    _projectionProcess!.stdin.write(jsonLine);
  }

  @override
  Future<void> closeProjectionWindow() async { ... }
  @override
  Stream<WindowEvent> get onWindowEvent => _eventController.stream;
}
```

**IMPORTANTE**: Verificar que los imports `dart:convert` y `dart:io` existan.

---

## TAREA-DEV-602 [P0 — CRÍTICO] ProjectionApp escucha stdin

### Archivo
`lib/presentation/views_projection/display/projection_app.dart`

### Qué hacer
1. Refactorizar de `ConsumerWidget` a `ConsumerStatefulWidget`
2. En `initState()`, comenzar a escuchar `stdin` usando `stdin.transform(utf8.decoder).transform(const LineSplitter()).listen(...)`
3. Implementar `_handleMessage(Map<String, dynamic> message)` con switch que maneje:
   - `LOAD_HYMN` → extraer himno y estrofas, llamar `notifier.loadHymn()`
   - `NEXT_STANZA` → `notifier.nextStanza()`
   - `PREV_STANZA` → `notifier.prevStanza()`
   - `GO_TO_STANZA` → `notifier.goToStanza(message['index'])`
   - `BLACKOUT` → `notifier.blackout()` o `toggleBlackout()` según `enabled`
   - `SET_CONFIG` → (opcional) actualizar configuración
4. En `dispose()`, cancelar la subscripción a stdin

### Manejo de LOAD_HYMN
Como `Himno` y `Estrofa` no tienen `toJson()`/`fromJson()` (Freezed sin json_serializable), pasar los campos inline:

```dart
case 'LOAD_HYMN':
  final hymn = Himno(
    id: message['himno_id'] as int,
    titulo: message['titulo'] as String,
    numero: message['numero'] as int?,
    tipo: HimnoTipo.values.firstWhere(
      (e) => e.name == (message['tipo'] as String?) ?? 'oficial',
    ),
  );
  final estrofasJson = message['estrofas'] as List<dynamic>;
  final estrofas = estrofasJson.map((e) {
    final m = e as Map<String, dynamic>;
    return Estrofa(
      id: m['id'] as int,
      versionPaisId: m['version_pais_id'] as int,
      tipo: EstrofaTipo.values.firstWhere(
        (t) => t.name == (m['tipo'] as String?) ?? 'verso',
      ),
      orden: m['orden'] as int,
      contenido: m['contenido'] as String,
    );
  }).toList();
  notifier.loadHymn(hymn, estrofas);
  break;
```

**IMPORTANTE**: Agregar imports: `dart:io` (stdin), `dart:convert` (jsonDecode, utf8), `dart:async` (StreamSubscription)

---

## TAREA-DEV-603 [P0 — CRÍTICO] Conectar HomeScreen a sendMessage()

### Archivo
`lib/presentation/views_personal/dashboard/home_screen.dart`

### Qué hacer
Modificar `_selectHymnForProjection()` para que después de cargar el himno en `liveControlProvider`, también lo envíe a la 2da ventana:

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

    // 1. Cargar en liveControlProvider local
    ref.read(liveControlProvider.notifier).loadHymn(
          himnoCompleto,
          estrofas,
          versionPaisId: versionPaisId,
        );

    // 2. Enviar a la 2da ventana
    final windowService = ref.read(windowServiceProvider);
    await windowService.sendMessage({
      'type': 'LOAD_HYMN',
      'himno_id': himnoCompleto.id,
      'titulo': himnoCompleto.titulo,
      'numero': himnoCompleto.numero,
      'tipo': himnoCompleto.tipo.name,
      'estrofas': estrofas.map((e) => {
        'id': e.id,
        'version_pais_id': e.versionPaisId,
        'tipo': e.tipo.name,
        'orden': e.orden,
        'contenido': e.contenido,
      }).toList(),
      'currentIndex': 0,
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

---

## TAREA-DEV-604 [P0 — CRÍTICO] Conectar PresentControlBar a sendMessage()

### Archivo
`lib/presentation/views_projection/controller/present_control_bar.dart`

### Qué hacer
En los métodos de navegación y blackout, enviar el comando a la 2da ventana después de actualizar el provider local:

```dart
// En prevStanza (línea ~159):
ref.read(liveControlProvider.notifier).prevStanza();
ref.read(windowServiceProvider).sendMessage({'type': 'PREV_STANZA'});

// En nextStanza (línea ~185):
ref.read(liveControlProvider.notifier).nextStanza();
ref.read(windowServiceProvider).sendMessage({'type': 'NEXT_STANZA'});
```

Agregar import de `window_providers.dart` si no existe:
```dart
import '../../../core/window_manager/window_providers.dart';
```

---

## TAREA-DEV-605 [P1 — ALTO] Tests para SimpleProjectionView

### Archivo a crear
`test/widget/simple_projection_view_test.dart`

### Qué hacer
Escribir tests widget para `SimpleProjectionView`:

```dart
void main() {
  group('SimpleProjectionView', () {
    testWidgets('Renderiza título del himno', (tester) async { ... });
    testWidgets('Muestra loading mientras carga estrofas', (tester) async { ... });
    testWidgets('Muestra "sin versiones" cuando versionId < 0', (tester) async { ... });
    testWidgets('Muestra navegación prev/next cuando hay estrofas', (tester) async { ... });
    testWidgets('Botón siguiente avanza a siguiente estrofa', (tester) async { ... });
    testWidgets('Botón anterior retrocede', (tester) async { ... });
    testWidgets('Muestra error cuando provider falla', (tester) async { ... });
  });
}
```

Usar provider overrides para mockear `stanzasProvider`.

---

## TAREA-DEV-606 [P1 — ALTO] Fix context.mounted en discover_display_sheet.dart

### Archivo
`lib/presentation/views_projection/controller/widgets/discover_display_sheet.dart`
**Línea 88**

### Qué hacer
```dart
// ❌ ANTES:
Navigator.pop(context);

// ✅ DESPUÉS:
if (context.mounted) Navigator.pop(context);
```

---

## TAREA-DEV-607 [P1 — ALTO] Fix ref.listenManual en minimal_control_screen.dart

### Archivo
`lib/presentation/views_projection/controller/minimal_control_screen.dart`
**Línea 29**

### Qué hacer
```dart
// ❌ ANTES (listenManual en build — anti-pattern):
ref.listenManual(hymnDetailProvider(hymnId), (prev, next) { ... });

// ✅ DESPUÉS (ref.listen es seguro en build según docs de Riverpod):
ref.listen(hymnDetailProvider(hymnId), (prev, next) { ... });
```

**Fundamentación**: La documentación oficial de Riverpod dice: *"It is safe to use WidgetRef.listen inside the build method of a widget. This is how the method is designed to be used."*

---

## TAREA-DEV-608 [P1 — ALTO] dart fix --apply

### Qué hacer
```bash
cd /home/melquisedec/Escritorio/Projects/Personales/HimnarioID_2.0

# Ver qué cambios se harán
dart fix --dry-run

# Aplicar cambios automáticos
dart fix --apply

# Verificar resultado
dart analyze lib/
```

Si hay cambios que rompen algo, revisar manualmente y ajustar.

---

## VERIFICACIÓN FINAL

```bash
cd /home/melquisedec/Escritorio/Projects/Personales/HimnarioID_2.0
dart analyze lib/    # 0 errors, 0 warnings, 0 info
flutter test         # todos los tests pasan
```

---

## ORDEN DE IMPLEMENTACIÓN RECOMENDADO

1. **DEV-608**: `dart fix --apply` primero (cambios automáticos, evita conflictos después)
2. **DEV-601**: `sendMessage()` en WindowService
3. **DEV-602**: ProjectionApp escucha stdin
4. **DEV-603**: HomeScreen conectada a sendMessage()
5. **DEV-604**: PresentControlBar conectada a sendMessage()
6. **DEV-606**: Fix context.mounted
7. **DEV-607**: Fix ref.listenManual
8. **DEV-605**: Tests para SimpleProjectionView (al final, cuando todo funciona)

---

*Fin de TASKS_DEV_SPRINT5.md — 14 de mayo de 2026*
