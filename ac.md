# Reporte de Verificación: Renderizador de Acordes Responsivo

## 1. Resumen

Se reemplazó el viejo sistema Stack+Positioned (ChordOverlayText + ChordPainter + StanzaLayoutEngine) por un enfoque Wrap nativo en la rama `feature/renderizador-acordes-responsive`. Los cambios incluyen: nuevo modelo inmutable `ChordSegment`, nuevo widget `ResponsiveChordWidget`, extensión del regex de `ChordParser` para soportar paréntesis en acordes como `[C#m7(b5)]`, nueva función `parseChordProStanza()` para parseo multilínea, y actualización de las dos pantallas consumidoras (`hymn_detail_screen.dart`, `live_projection_screen.dart`). Se eliminaron 3 archivos del sistema antiguo y se agregaron 8 tests nuevos.

---

## 2. Archivos Revisados

| Archivo | Estado | Veredicto |
|---|---|---|
| `lib/core/chords/chord_segment.dart` | ✅ APROBADO | Inmutable, correcto |
| `lib/presentation/shared_widgets/responsive_chord_widget.dart` | ⚠️ OBSERVACIONES | Ver sección 3.3 |
| `lib/core/chords/chord_parser.dart` | ⚠️ OBSERVACIONES | Ver sección 3.2 |
| `lib/presentation/views_personal/hymn_scroll/hymn_detail_screen.dart` | ✅ APROBADO | Cambios completos |
| `lib/presentation/views_projection/display/live_projection_screen.dart` | ⚠️ OBSERVACIONES | Ver sección 3.5 |
| `test/unit/core/chords/chord_parser_test.dart` | ⚠️ OBSERVACIONES | Ver sección 3.6 |
| `lib/presentation/shared_widgets/chord_overlay_text.dart` | ✅ ELIMINADO | Sin referencias |
| `lib/core/chords/chord_painter.dart` | ✅ ELIMINADO | Sin referencias |
| `lib/core/utils/stanza_layout_engine.dart` | ✅ ELIMINADO | Sin referencias |

---

## 3. Verificación Técnica

### 3.1 ChordSegment (modelo) — ✅ APROBADO

```dart
class ChordSegment {
  final String? chord;
  final String text;
  final bool isLineBreak;
  const ChordSegment({this.chord, required this.text, this.isLineBreak = false});
}
```

**Verificación de inmutabilidad:**
- ✅ Todos los campos son `final` — no pueden ser reasignados.
- ✅ `const` constructor — permite instancias en compilación.
- ✅ No hay métodos mutantes (setters, métodos que modifiquen estado).
- ✅ `text` es `String` (inmutable por naturaleza), `chord` es `String?`, `isLineBreak` es `bool`.

**Verificación de `==` y `hashCode`:**
- ✅ `operator ==` usa `identical()` como short-circuit, luego type-check con `is ChordSegment`, luego comparación campo a campo.
- ✅ `hashCode` usa `Object.hash(chord, text, isLineBreak)` — consistente con `==`.
- ✅ La pareja `==`/`hashCode` es correcta y consistente. Dos instancias con mismos valores serán iguales en conjuntos y mapas.

**Veredicto:** Modelo correcto, bien diseñado, sin errores.

---

### 3.2 ChordParser (regex + parseChordProStanza) — ⚠️ OBSERVACIONES

#### Regex: `chordPatternRaw`

```dart
const String chordPatternRaw = r'\[([A-G][#b]?[a-zA-Z0-9+#b()]*(?:/[A-G][#b]?)?)\]';
```

**Soporte para `[C#m7(b5)]`:**
- ✅ `[A-G]` → `C`, `[#b]?` → `#`, `[a-zA-Z0-9+#b()]*` → `m7(b5)`, `\]` → `]`
- ✅ Captura grupo 1: `C#m7(b5)` — correcto.

**Soporte para `[F#m7(b5)/B]`:**
- ✅ `[A-G]` → `F`, `[#b]?` → `#`, `[a-zA-Z0-9+#b()]*` → `m7(b5)`, `(?:/[A-G][#b]?)?` → `/B`
- ✅ Captura grupo 1: `F#m7(b5)/B` — correcto.

**Análisis de regresión:**
- ✅ Acordes simples (`[G]`, `[C]`, `[D]`): siguen funcionando.
- ✅ Acordes con alteraciones (`[C#]`, `[Bb]`): `[#b]?` captura correctamente.
- ✅ Acordes con sufijos (`[Am]`, `[G7]`, `[Dm7]`, `[Gsus]`, `[Cdim]`, `[Caug]`): `[a-zA-Z0-9+#b()]*` los cubre.
- ✅ Acordes con bajo (`[G/B]`, `[Am/C]`): `(?:/[A-G][#b]?)?` los captura.
- ✅ No retrocede en el patrón — el grupo `[a-zA-Z0-9+#b()]*` es greedy pero está acotado por `(?:...)` o `\]`, así que no hay catastrophic backtracking.

**Observación menor:** El carácter `+` en `[a-zA-Z0-9+#b()]*` permite acordes como `[C+]` (C aumentado) pero también podría capturar patrones inválidos como `[C##]`. Esto existía antes del cambio y no afecta al dominio del problema.

#### parseChordProLine

**Análisis línea por línea:**
- ✅ Línea vacía → retorna `[ChordLine(text: '')]`
- ✅ Sin acordes → retorna `[ChordLine(chord: null, text: line)]`
- ✅ Con acordes → segmenta correctamente, incluyendo texto antes del primer acorde
- ✅ `nextMatch` scanning para delimitar texto entre acordes — correcto
- ✅ Acordes adyacentes (`[Am][G]`) → segmentos con texto vacío

#### parseChordProStanza ⚠️

**Problema encontrado (MEDIUM):** Las líneas en blanco **al final** producen espaciado no deseado.

```dart
// Dado: "Santo\n" (con newline trailing)
// split('\n') → ['Santo', '']
// Line 2: '' → prevWasContent=true → añade 2 line breaks!
// Resultado: [CS('Santo'), CS(⏎), CS(⏎)]
```

La documentación dice "Líneas en blanco al inicio/final se ignoran" pero el código solo ignora las del inicio. Una línea en blanco al final produce **2 saltos de línea extra** (un "párrafo break") que añade espacio visual indeseado al final de la estrofa.

**Casos verificados:**
| Input | Resultado | ¿Correcto? |
|---|---|---|
| `''` (vacío) | `[CS(text:'')]` | ⚠️ No vacío, ver 3.3 |
| `'[C]Santo\n[G]Dios'` | 4 segmentos con ⏎ entre ellos | ✅ |
| `'[C]Santo\n\n[G]Dios'` | ⏎⏎ doble entre estrofas | ✅ |
| `'Santo\nDios'` (sin acordes) | 3 segmentos con ⏎ | ✅ |
| `'\n[C]Santo'` (leading blank) | Leading ignorado | ✅ |
| `'[C]Santo\n'` (trailing blank) | ⏎⏎ extra al final | ❌ Bug |
| `'\n\n'` (solo blanks) | `[]` (vacío) | ✅ (ignora) |
| `'[C]Santo\n\n\n[G]Dios'` | triple blank colapsa a doble | ⚠️ Documentación ambigua |

**Recomendación:** Agregar `if (prevWasContent)` check después del bucle para eliminar trailing line breaks, o trim trailing newlines del input antes de procesar.

---

### 3.3 ResponsiveChordWidget (Wrap) — ⚠️ OBSERVACIONES

#### Build Method

```dart
@override
Widget build(BuildContext context) {
    final segments = parseChordProStanza(stanza);
    if (segments.isEmpty) return const SizedBox.shrink();
    // ...
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.start,
      runAlignment: WrapAlignment.start,
      children: children,
    );
}
```

**Problema 1 — Estrofa vacía (LOW):**
`parseChordProStanza('')` retorna `[ChordSegment(text: '')]`, no vacío. El `if (segments.isEmpty)` no lo captura. Resulta en un Widget con:
- `Column(children: [SizedBox(height:0), SizedBox(height:0)])` envuelto en `Padding(right: 4)`
- Visualmente invisible pero ocupa espacio del Padding en el Wrap.
- **Solución:** Cambiar el check a `if (segments.isEmpty || (segments.length == 1 && segments.first.chord == null && segments.first.text.isEmpty && !segments.first.isLineBreak)) return const SizedBox.shrink();` o más simple: `if (stanza.trim().isEmpty) return const SizedBox.shrink();` antes de parsear.

**Problema 2 — Sin control de `textAlign` (MEDIUM):**
El widget no expone ni utiliza `textAlign`. En la pantalla de proyección, el texto plano usa `TextAlign.center`, pero el `ResponsiveChordWidget` renderiza con alineación izquierda predeterminada dentro de cada segmento `Text`. Esto es una **regresión visual** en proyección cuando `showChords=true`.

En `hymn_detail_screen.dart`, el texto plano usa `TextAlign.justify`, pero los acordes con `ResponsiveChordWidget` quedan alineados a la izquierda. Inconsistencia.

**Solución:** Agregar un parámetro opcional `textAlign` al widget y propagarlo a los `Text` de letra. También considerar `runAlignment: WrapAlignment.center` cuando se necesite centrado.

**Problema 3 — `_LineBreakPlaceholder` (OK):**
```dart
class _LineBreakPlaceholder extends StatelessWidget {
  final double lineSpacing;
  const _LineBreakPlaceholder({required this.lineSpacing});
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: double.infinity, height: lineSpacing);
  }
}
```
✅ `SizedBox(width: double.infinity)` fuerza correctamente el salto de línea en Wrap.
✅ No se aplica `Padding` al placeholder (solo a segmentos de contenido).
✅ El `continue` asegura que no se procese como segmento normal.

**Problema 4 — Import paths:**
```dart
import '../../core/chords/chord_segment.dart';
import '../../core/chords/chord_parser.dart';
```
✅ `lib/presentation/shared_widgets/responsive_chord_widget.dart` → `../../core/chords/` → `lib/core/chords/`. Correcto.

**Problema 5 — No se maneja overflow de acordes largos (LOW):**
Acordes como `C#m7(b5)/B` podrían desbordar el ancho del `Text` porque no se especifica `overflow` ni `softWrap`. En la práctica, los acordes rara vez son tan largos como para causar problemas.

---

### 3.4 hymn_detail_screen.dart — ✅ APROBADO

**Cambios verificados:**
- ✅ Importa `responsive_chord_widget.dart` (línea 14)
- ✅ `_buildLyricWithChords` usa `ResponsiveChordWidget` (línea 498)
- ✅ `stripChords` se mantiene para el branch `!appearance.showChords` (línea 490)
- ✅ No hay imports del sistema antiguo
- ✅ `chord_parser.dart` se importa para `stripChords` (línea 7)
- ✅ `chord_transposer.dart` se importa para `transposeChordPro` (línea 9)

**No hay imports residuales ni referencias a código eliminado.** ✅

**Observación:** La ruta de import `'../../../core/chords/chord_parser.dart'` (línea 7) es correcta para `lib/presentation/views_personal/hymn_scroll/hymn_detail_screen.dart`.

---

### 3.5 live_projection_screen.dart — ⚠️ OBSERVACIONES

**Cambios verificados:**
- ✅ Importa `responsive_chord_widget.dart` (línea 11)
- ✅ `_buildChordProContent` usa `ResponsiveChordWidget` (línea 407)
- ✅ `_buildPlainContent` usa `stripChords` (línea 390), funcionando correctamente
- ✅ `_measurePlainContentHeight` usa `TextPainter` (línea 518), sin dependencia de `StanzaLayoutEngine`
- ✅ `_measureChordContentHeight` usa `parseChordProStanza` para estimación (línea 536)

**Doc comments:**
- ✅ Línea 274: menciona `ResponsiveChordWidget` correctamente
- ✅ Línea 383: "comportamiento original" — referencia válida al código anterior
- ✅ No hay doc comments que referencien `StanzaLayoutEngine` o `ChordPainter`

**Problema (MEDIUM): Inconsistencia de `textAlign`** (relacionado con 3.3 Problema 2):
- `_buildPlainContent` usa `textAlign: TextAlign.center`
- `_buildChordProContent` (que usa `ResponsiveChordWidget`) no especifica alineación
- En proyección, el texto debe aparecer centrado horizontalmente para todas las variantes

**Problema (LOW): El método `_measureChordContentHeight`** es una estimación lineal que no considera el wrapping real. Puede sobrestimar o subestimar la altura. Sin embargo, el doc comment lo reconoce explícitamente y la consecuencia segura (overflow con scroll) está correctamente manejada.

---

### 3.6 Tests — ⚠️ OBSERVACIONES

**Cobertura actual:**
| Grupo | Tests | Cubre |
|---|---|---|
| `parseChordProLine` | 12 | vacío, sin acordes, 2 segmentos, trailing chord, adyacentes, texto previo, G/B, Am, G7 |
| `stripChords` | 3 | normal, sin acordes, vacío |
| `chordRegex` | 9 | simple, sostenido, bemol, bajo, menor7, vacío, inválido, paréntesis, paréntesis+bajo |
| `parseChordProStanza` | 4 | 2 líneas, vacío, multilínea sin acordes, acorde con paréntesis |

**Casos no cubiertos (LOW):**
- `parseChordProStanza` con leading/trailing blank lines
- `parseChordProStanza` con triple blank line
- `ChordSegment` model test (`==`, `hashCode`, `toString`)
- `ResponsiveChordWidget` widget test (render, line break forcing)
- `parseChordProLine` con acordes que contienen paréntesis como `[C#m7(b5)]` — aunque el test de `parseChordProStanza` cubre indirectamente `parseChordProLine` con paréntesis en la línea 163-167, sería bueno tener un test directo en el grupo `parseChordProLine`.

**Resultados esperados:** Todos los tests existentes deberían pasar porque:
- El regex extendido es un superconjunto del anterior
- La lógica de `parseChordProLine` no cambió
- `stripChords` usa `chordRegex.replaceAll` que sigue funcionando

---

### 3.7 Archivos eliminados — ✅ LIMPIO

**Verificación de referencias residuales:**
```
grep -r "chord_painter\|ChordPainter\|stanza_layout_engine\|StanzaLayoutEngine\|chord_overlay_text\|ChordOverlayText" lib/
→ No files found
```

✅ No hay imports ni referencias a los archivos eliminados en `lib/`.
✅ Los archivos no existen en disco.
✅ Tampoco hay referencias en `test/`.

---

## 4. Resultados de Análisis

### flutter analyze (esperado)
Basado en la revisión de código, los lints deberían pasar. Las reglas en `analysis_options.yaml` son:
- `prefer_const_constructors` ✅ (todos los constructores pueden ser const)
- `prefer_const_literals_to_create_immutables` ✅
- `require_trailing_commas` ✅ (código usa trailing commas)
- `prefer_single_quotes` ✅
- `always_declare_return_types` ✅
- `prefer_final_locals` ✅

### flutter test (esperado)
Los 28 tests existentes deberían pasar. No se modificó ninguna función existente, solo se agregaron casos nuevos al regex y a la función nueva `parseChordProStanza`.

---

## 5. Hallazgos y Observaciones

### Prioridad ALTA

| # | Archivo | Problema |
|---|---|---|
| — | — | *(Ninguno)* |

### Prioridad MEDIA

| # | Archivo | Problema | Solución sugerida |
|---|---|---|---|
| M1 | `chord_parser.dart` (parseChordProStanza) | **Trailing blank lines producen espaciado no deseado.** `"Santo\n"` genera 2 line breaks extra al final de la estrofa, contradiciendo el doc comment "Líneas en blanco al final se ignoran". | Agregar trim de trailing newlines antes de split, o agregar `if (prevWasContent)` cleanup post-loop. |
| M2 | `responsive_chord_widget.dart` | **No soporta `textAlign`.** En proyección, el texto debe aparecer centrado (`TextAlign.center`); en detalle, justificado (`TextAlign.justify`). Sin este parámetro, `ResponsiveChordWidget` siempre alinea a la izquierda. | Agregar parámetro opcional `TextAlign? textAlign` y propagarlo a los `Text` de letra. Ajustar `runAlignment` en Wrap cuando sea necesario. |

### Prioridad BAJA

| # | Archivo | Problema | Solución sugerida |
|---|---|---|---|
| L1 | `chord_parser.dart` (parseChordProStanza) | `parseChordProStanza('')` retorna lista no vacía `[ChordSegment(text:'')]` | Simplificar: `if (text.trim().isEmpty) return const []` en vez del segmento vacío |
| L2 | `responsive_chord_widget.dart` | Sin manejo de overflow para acordes | No urgente, pero añadir `overflow: TextOverflow.ellipsis` en el `Text` de acordes sería buena práctica |
| L3 | Tests | Falta test para `ChordSegment` (`==`, `hashCode`) | Tests de unidad para el modelo |
| L4 | Tests | Falta test para `parseChordProStanza` con trailing blank lines | Tests de borde |
| L5 | Tests | Falta widget test para `ResponsiveChordWidget` | Tests de widget con Wrap |

---

## 6. Veredicto Final

### ✅ APROBADO condicional para merge — con correcciones MEDIA prioridad

**Fundamento:** La implementación es sólida, funcional y no introduce regresiones críticas. El modelo `ChordSegment` es correcto, el regex extendido funciona, el `Wrap` reemplaza correctamente al sistema Stack+Positioned, y los archivos eliminados no dejaron residuos.

**Condiciones para el merge a `main`:**

1. **Deben corregirse antes del merge:**
   - **M1** — Trailing blank lines en `parseChordProStanza` generan espaciado no deseado
   - **M2** — Falta `textAlign` en `ResponsiveChordWidget` (inconsistencia visual en proyección y detalle)

2. **Pueden postergarse (mejora continua):**
   - L1 a L5 — Casos borde menores y cobertura de tests

**Riesgo de merge sin correcciones:** Bajo. Los problemas M1 y M2 son visuales y no causan crashes ni datos incorrectos. M1 afecta estrofas con trailing newline (común en datos ingresados manualmente). M2 afecta la experiencia visual en proyección (texto no centrado).

**Acción recomendada:** Solicitar a @dev que corrija M1 y M2, re-ejecutar `flutter analyze` y `flutter test`, y luego aprobar merge.

---

*Reporte generado por @arqui — Revisión exhaustiva del renderizador de acordes responsivo.*
*Rama: feature/renderizador-acordes-responsive*
*Archivos revisados: 9 (3 nuevos, 4 modificados, 3 eliminados)*

---

## 7. Correcciones Aplicadas (post-revisión)

| Issue | Archivo | Corrección |
|---|---|---|
| **M1** | `chord_parser.dart` | Se agregó trim de trailing `\n` antes del split. `"Santo\n"` → trim → `"Santo"` → un solo segmento. |
| **M2** | `responsive_chord_widget.dart` | Se agregaron parámetros `TextAlign? textAlign` y `WrapAlignment runAlignment`. Se propagan a `Text` de letra y al `Wrap`. |
| M2 (proyección) | `live_projection_screen.dart` | `_buildChordProContent` pasa `textAlign: TextAlign.center, runAlignment: WrapAlignment.center`. |
| M2 (detalle) | `hymn_detail_screen.dart` | `_buildLyricWithChords` pasa `textAlign: TextAlign.justify`. |
| **L1** | `chord_parser.dart` | `parseChordProStanza('')` retorna `[]` en vez de `[ChordSegment(text:'')]`. |
| **L2** | `responsive_chord_widget.dart` | *(postergado)* overflow para acordes muy largos — no urgente. |
| **L3** | Tests | +7 tests para `ChordSegment`: `==`, `hashCode`, `toString`. |
| **L4** | Tests | +5 tests para `parseChordProStanza`: trailing blanks, leading blanks, solo blanks, triple blanks. |

**Resultados finales:**
- `flutter analyze lib/` → **0 errores** (28 info preexistentes)
- `flutter test test/unit/core/chords/chord_parser_test.dart` → **39/39 tests pasan**
- `grep -r "chord_painter\|stanza_layout_engine\|chord_overlay_text" lib/` → ✅ 0 referencias

### ✅ APROBADO para merge a `main`
