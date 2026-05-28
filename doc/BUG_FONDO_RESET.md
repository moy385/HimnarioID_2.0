# Bug: Fondo de proyección se resetea al cambiar apariencia

> :warning: **Este bug ha ocurrido DOS VECES.** Documentamos aquí la causa raíz,
> la solución incorrecta que aplicamos primero, y la solución definitiva.
> Si vuelve a aparecer, leer esto antes de tocar código.

## Historial

| Ocurrencia | Síntoma | "Fix" aplicado | Resultado |
|------------|---------|----------------|-----------|
| **#1 (v2.0.1)** | Fondo se vuelve BLANCO al cambiar tamaño de letra | Agregar `bgColor: _colorToHex(appearance.bgColor)` a `sendSetAppearance()` | ❌ Ahora se vuelve NEGRO |
| **#2 (v2.0.2)** | Fondo se vuelve NEGRO al cambiar tamaño de letra | El "fix" anterior | ❌ El fondo sigue cambiando |

## Causa Raíz (verdadera)

**El error arquitectónico es: `SET_APPEARANCE` / `SET_CONFIG` NO debería transportar `bgColor`.**

Hay dos conceptos distintos en el sistema:

1. **Apariencia**: tamaño de letra, color de texto, color de acordes, familia de fuente, negrita, mostrar acordes, opacidad de tarjeta.
2. **Fondo**: imagen de fondo o color sólido que se muestra detrás de la letra.

Estos dos conceptos se cambian desde UI distintas (el fondo se selecciona en un selector dedicado, la apariencia se cambia con sliders y botones). Sin embargo, el código los mezclaba: cada vez que se cambiaba cualquier cosa de apariencia, se enviaba TAMBIÉN el `bgColor`.

### Mecanismo del bug

```
Usuario cambia tamaño de letra
  → _syncAppearanceToProjection()
    → sendSetAppearance(bgColor: appearance.bgColor)  ← envía el color actual
    → (también) sendSetBackground()                     ← envía el fondo actual
```

En el receptor:

1. `SET_APPEARANCE` llega → `notifier.setBgColor(color)` → **borra `selectedFondo = null`** (efecto secundario de `setBgColor()`)
2. El fondo de imagen se pierde momentáneamente
3. `SET_BACKGROUND` llega → `notifier.setFondo(fondo)` → restaura el fondo
4. Pero si `SET_BACKGROUND` se retrasa o falla → el fondo se pierde permanentemente

Además, en la ventana de proyección (desktop), hay un agravante:

```dart
// projection_app.dart línea 234
final color = Color(int.parse(hex.substring(1), radix: 16) | 0xFF000000);
```

El `| 0xFF000000` **fuerza el alpha a opaco**. Si `bgColor` es `Colors.transparent` (hex `#00000000`), se convierte en `#FF000000` = **negro opaco**. Y `setBgColor(negro)` borra el fondo seleccionado.

### ¿Por qué el primer fix empeoró las cosas?

El bug #1 era: "fondo se vuelve blanco". La causa era que `sendSetAppearance()` NO enviaba `bgColor`, y el receptor lo inicializaba como `Colors.transparent`, que sobre fondo claro se ve blanco.

El fix fue: agregar `bgColor` a `sendSetAppearance()`. Pero esto introdujo el bug #2 porque:

- `bgColor` se envía con CADA cambio de apariencia
- En la ventana de proyección, `| 0xFF000000` lo convierte en negro opaco
- `setBgColor()` borra `selectedFondo`
- El fondo de imagen se pierde hasta que llega `SET_BACKGROUND`

## Solución Definitiva

### Principio

> `SET_APPEARANCE` debe significar "aplica estos campos de apariencia, SIN TOCAR el fondo".
> El fondo solo debe cambiarse mediante llamadas dedicadas: `SET_BACKGROUND` (gRPC)
> o `bgFondoId` en `SET_CONFIG` (ventana de proyección).

### Cambios necesarios

#### Lado EMISOR (quién envía apariencia)

| Archivo | Cambio |
|---------|--------|
| `control_sheets.dart` `_syncAppearanceToProjection` | Eliminar `bgColor` del mensaje SET_CONFIG y de `sendSetAppearance()` gRPC |
| `minimal_control_screen.dart` `_sendHymnToDisplay` | Eliminar `bgColor` de `sendSetAppearance()` |
| `connected_dashboard.dart` `_sendHymnToDisplay` | Eliminar `bgColor` de `sendSetAppearance()` |
| `projection_actions.dart` `_buildSetConfigMessage` | Eliminar `bgColor`, `backgroundColor`, `background` del mapa |

#### Lado RECEPTOR (quien procesa apariencia)

| Archivo | Cambio |
|---------|--------|
| `projection_app.dart` `_handleSetConfig` | Eliminar el bloque `if (message.containsKey('bgColor'))` |
| `grpc_display_server.dart` `sendCommand` SET_APPEARANCE | Eliminar `if (request.hasBgColor()) notifier.setBgColor(...)` |

#### Capa de transporte

| Archivo | Cambio |
|---------|--------|
| `grpc_control_datasource.dart` `sendSetAppearance` | Eliminar parámetro `bgColor` |
| `proto/hymn_control.proto` | (Opcional) Marcar `bg_color` como reservado |

### Lo que NO se debe hacer

- ❌ No agregar `bgColor` a `sendSetAppearance()` NUNCA MÁS
- ❌ No usar `| 0xFF000000` al parsear colores hex (destruye el alpha)
- ❌ No mezclar fondo con apariencia en ningún mensaje

### Archivo de referencia para entender el flujo completo

- `lib/presentation/shared_widgets/control_sheets.dart` → `_syncAppearanceToProjection` (línea ~112)
- `lib/presentation/views_projection/providers/projection_actions.dart` → `_buildSetConfigMessage` (línea ~84)
- `lib/presentation/views_projection/display/projection_app.dart` → `_handleSetConfig` (línea ~153)
- `lib/presentation/views_projection/providers/presentation_providers.dart` → `projectionConfigProvider`
- `lib/presentation/shared_widgets/providers/appearance_provider.dart` → `HymnAppearanceState`, `setBgColor()`

### Verificación

Después del fix:

1. Cambiar tamaño de letra → el fondo NO cambia
2. Cambiar color de texto → el fondo NO cambia
3. Cambiar fuente → el fondo NO cambia
4. Alternar acordes → el fondo NO cambia
5. Seleccionar un fondo nuevo → el fondo CAMBIA (correcto)
6. Proyectar un himno nuevo → el fondo se mantiene
