# 🐛 Reporte de Bug UI y Refactorización: Desalineación y Fractura de Acordes

---

## 📌 Resolución — 25 de mayo de 2026

### ✅ Bugs corregidos

| Bug | Causa raíz | Fix |
|---|---|---|
| **Pérdida de anclaje** | `Column.crossAxisAlignment` default = `center` | `CrossAxisAlignment.start` para anclar acorde a primera letra |
| **Fractura de palabras** | `Padding(right: 4)` en cada segmento inyectaba 4px de espacio horizontal | `spacing: 0.0` + eliminar Padding individual |

### 👥 Flujo de trabajo

1. **@arqui** + **@curie** evaluaron el bug y el código propuesto en `obs.md`
2. **@arqui** identificó **5 regresiones** en el código propuesto que debían evitarse
3. **@curie** confirmó las 3 reglas de corrección y las 5 regresiones
4. **@dev** implementó los cambios en `responsive_chord_widget.dart` siguiendo el plan corregido
5. **@arqui** verificó post-implementación: **✅ APROBADO**

### 🔧 Cambios realizados

**Archivo modificado**: `lib/presentation/shared_widgets/responsive_chord_widget.dart`

| # | Cambio | Línea | Propósito |
|---|--------|-------|-----------|
| 1 | `if (stanza.trim().isEmpty)` en vez de `if (segments.isEmpty)` | 55 | Early return más robusto |
| 2 | Eliminar `Padding(right: 4)` de cada segmento | — | Elimina espacio horizontal que fracturaba palabras |
| 3 | `crossAxisAlignment: CrossAxisAlignment.start` en Column | 64 | Ancla el acorde a la primera letra |
| 4 | `_effectiveChordStyle.copyWith(height: 1.1)` | 67 | Acerca acorde a letra con fallback seguro |
| 5 | `_effectiveTextStyle.copyWith(height: 1.1)` | 70 | Altura consistente en texto |
| 6 | `spacing: 0.0` en Wrap | 77 | Cero espacio horizontal entre segmentos |
| 7 | `runSpacing: lineSpacing` | 78 | Espaciado vertical dinámico (no hardcodeado) |
| 8 | `alignment` condicional (center/right/left) | 79-83 | Respeta alineación horizontal de cada pantalla |
| 9 | `crossAxisAlignment: WrapCrossAlignment.end` | 84 | Alinea vertical por la parte inferior |

### 🚫 Regresiones de `obs.md` que NO se copiaron

| Regresión | Peligro | Corrección aplicada |
|-----------|---------|---------------------|
| `const _LineBreakPlaceholder(lineSpacing: 10.0)` | Ignora `lineSpacing` del widget | Usa `lineSpacing` (variable del constructor) |
| `chordStyle?.copyWith(height: 1.1)` | Null si `chordStyle` es null | `_effectiveChordStyle.copyWith(height: 1.1)` con fallback |
| `lyricStyle?.copyWith(height: 1.1)` | Variable no existe + null si `null` | `_effectiveTextStyle.copyWith(height: 1.1)` |
| `runSpacing: 10.0` | Ignora `lineSpacing` del widget | `runSpacing: lineSpacing` (dinámico) |
| Falta `TextAlign.right` | Proyección con alineación derecha se rompía | `textAlign == TextAlign.right → WrapAlignment.end` |

### 📊 Resultados de verificación

| Verificación | Resultado |
|---|---|
| `flutter analyze` | ✅ **0 issues found** |
| `flutter test` (39 tests) | ✅ **All tests passed** |
| Sin referencias a código eliminado | ✅ **0 referencias** |
| `hymn_detail_screen.dart` usa `textAlign: TextAlign.justify` | ✅ Correcto |
| `live_projection_screen.dart` usa `textAlign: TextAlign.center` | ✅ Correcto |

### 🏛️ Veredicto de @arqui

> ✅ **APROBADO para merge a `main`.**
> La implementación es correcta y completa. No se encontraron regresiones, bugs ni desviaciones del plan arquitectural.
>
> — @arqui, 2026-05-25

## 📌 Contexto de la Situación y Diagnóstico
Actualmente, el `ResponsiveChordWidget` resuelve el diseño responsivo usando `Wrap`, pero presenta dos anomalías visuales críticas al compararlo con las fotografías del himnario físico original:

1. **Pérdida de Anclaje (Offset erróneo):** El acorde no nace sobre la primera letra de la sílaba correspondiente. Por ejemplo, en el parseo de `[D]Cerc[D/F#]a`, el acorde **D** flota hacia el centro/derecha sobre las letras "rc" en lugar de anclarse de forma precisa en la "C".
2. **Fractura de Palabras (Spacing inducido):** Se están inyectando espacios en blanco artificiales a mitad de las palabras cuando un acorde corta una sílaba. Esto provoca que visualmente se lea "Cerc a" separado, lo cual es ortográficamente incorrecto.

## 🛠️ Instrucciones Estrictas de Refactorización

Para corregir esto, debes modificar el archivo `lib/presentation/shared_widgets/responsive_chord_widget.dart`. El problema radica en los márgenes y alineaciones automáticas de `Column` y `Wrap`. 

Aplica estas tres reglas de UI:
1. **Anclaje a la Izquierda:** La `Column` individual de cada fragmento no debe estar centrada. Debe usar `CrossAxisAlignment.start` para que el acorde se clave en la primera letra.
2. **Spacing = 0:** El `Wrap` no debe inyectar espacios horizontales. Usa `spacing: 0.0`.
3. **Line Height:** Acercar visualmente el acorde a la letra usando la propiedad `height` en el `TextStyle`.

## 💻 Código de Implementación Esperado

Reemplaza la lógica del método `build` dentro de tu `ResponsiveChordWidget` para que coincida con esta estructura exacta:

```dart
@override
Widget build(BuildContext context) {
  final segments = parseChordProStanza(stanza);
  
  // Evitar renderizar espacios basura si la estrofa viene vacía
  if (stanza.trim().isEmpty) return const SizedBox.shrink();

  final children = segments.map((segment) {
    if (segment.isLineBreak) {
      return const _LineBreakPlaceholder(lineSpacing: 10.0);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      // 🔴 REGLA 1: Forzar anclaje estricto a la primera letra del fragmento
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        if (segment.chord != null)
          Text(
            segment.chord!,
            // 🔴 REGLA 3: Ajustar altura para pegar el acorde al texto base
            style: chordStyle?.copyWith(height: 1.1), 
          )
        else
          // Espaciador invisible para mantener consistencia de altura
          Text('', style: chordStyle?.copyWith(height: 1.1)), 
        
        Text(
          segment.text,
          style: lyricStyle?.copyWith(height: 1.1),
        ),
      ],
    );
  }).toList();

  return Wrap(
    // 🔴 REGLA 2: Destructor de espacios artificiales a mitad de palabra
    spacing: 0.0, 
    runSpacing: 10.0, // Mantenemos el espaciado vertical entre líneas
    
    // Respetamos la alineación global que pide la pantalla (ej. Proyección = Center)
    alignment: textAlign == TextAlign.center ? WrapAlignment.center : WrapAlignment.start,
    crossAxisAlignment: WrapCrossAlignment.end,
    
    children: children,
  );
}