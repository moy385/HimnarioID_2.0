# 🚨 ALERTA CRÍTICA DE UI Y ARQUITECTURA: Gaps en Palabras y Responsive "Brick"

---

## ✅ Resolución — 25 de mayo de 2026

### Bugs corregidos

| Bug | Causa raíz | Fix |
|---|---|---|
| **Caja Ancha (Gaps)** | Column se estiraba al ancho del acorde (ej: `D/F#` sobre `a`) | `Stack` + `Positioned(left:0)` + dummy `Text(' ')` transparente — el acorde flota sin estirar la columna |
| **Efecto Ladrillo (Responsive bloqueado)** | `parseChordProLine` agrupaba texto sin acordes en un solo `ChordSegment` gigante → Wrap no podía dividirlo | Nueva función `expandToWordSegments` que divide texto palabra por palabra |

### 👥 Flujo de trabajo

1. **@curie** evaluó la propuesta de `correcciones.md` — encontró bug crítico en split directo sobre `parseChordProLine` (perdía segmentos vacíos)
2. **@arqui** creó plan: NO tocar `parseChordProLine`, crear `expandToWordSegments`
3. **@dev** implementó `expandToWordSegments` + modificó `parseChordProStanza`
4. **@design** implementó Stack+Positioned en `responsive_chord_widget.dart`
5. **@arqui** verificó post-implementación: **✅ APROBADO**

### 🔧 Cambios realizados

#### `lib/core/chords/chord_parser.dart`
| # | Cambio | Líneas |
|---|--------|--------|
| 1 | Nueva función `expandToWordSegments(List<ChordLine>)` — divide cada línea en palabras individuales | 95-116 |
| 2 | `parseChordProStanza` ahora usa `expandToWordSegments` en vez de mapeo directo | 156-157 |

#### `lib/presentation/shared_widgets/responsive_chord_widget.dart`
| # | Cambio | Líneas |
|---|--------|--------|
| 1 | Stack con `clipBehavior: Clip.none` como contenedor del acorde | 68-86 |
| 2 | Dummy `Text(' ')` transparente para reservar altura de línea | 71-75 |
| 3 | `Positioned(left: 0, top: 0)` para que el acorde flote sin estirar | 77-84 |

### 🧪 Tests

- **39 existentes**: intactos (no se modificó `parseChordProLine`)
- **6 nuevos** para `expandToWordSegments`: línea simple, acorde sin texto, acordes adyacentes, texto pre-acorde, línea sin acordes, línea vacía
- **Total: 45/45 tests pasan** ✅

### 📊 Verificación

| Verificación | Resultado |
|---|---|
| `flutter analyze lib/` | ✅ **0 issues** |
| `flutter test` (45 tests) | ✅ **All tests passed** |
| Consumidores sin cambios | ✅ `hymn_detail_screen`, `live_projection_screen` intactos |

### 🏛️ Veredicto de @arqui

> ✅ **APROBADO.** El fix es arquitecturalmente sólido. `expandToWordSegments` sigue el patrón functional-style (pura, inmutable, componible) y se integra limpiamente en el pipeline existente. Stack+Positioned + dummy transparente es la solución canónica para acordes que estiran contenedores.
>
> — @arqui, 2026-05-25

## 📌 Diagnóstico de los Bugs Visuales
Las pruebas de laboratorio revelaron dos comportamientos anómalos en el motor de renderizado `Wrap`:

1. **El Síndrome de la Caja Ancha (Gaps en palabras):** Cuando un acorde es más ancho que su sílaba correspondiente (Ej. el acorde `D/F#` sobre la letra `a`), la `Column` del widget adapta su ancho al acorde. Esto empuja el resto de las palabras hacia la derecha y genera enormes espacios en blanco a mitad de la palabra.
2. **El Efecto "Ladrillo" (Responsive bloqueado):** El `ChordParser` está agrupando todo el texto que no tiene acordes en un solo `ChordSegment` gigante (Ej. `segment.text = "rno amor, quiero gozar;"`). Como el `Wrap` trabaja con bloques atómicos, no puede dividir este "ladrillo" en líneas nuevas, rompiendo el diseño responsivo en pantallas pequeñas.

## 🛠️ Instrucciones Estrictas de Refactorización

Para solucionar esto de forma definitiva, debes implementar estos dos cambios vitales en la arquitectura:

### PASO 1: Refactor UI - Liberar el ancho del acorde con `Stack`
En el archivo `lib/presentation/shared_widgets/responsive_chord_widget.dart`, el acorde **no debe dictar el ancho de la columna**. Debes usar un `Stack` con `clipBehavior: Clip.none` para que el acorde flote independientemente hacia la derecha sin desplazar la letra.

Sustituye la estructura interna de tu `Column` por esto:

```dart
Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start, 
  children: [
    // 🔴 CRÍTICO: Stack permite que el acorde flote sin estirar el ancho del widget
    Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. Dummy invisible para reservar la altura vertical del acorde (pero con ancho cero/mínimo)
        Text(' ', style: _effectiveChordStyle.copyWith(height: 1.1, color: Colors.transparent)),
        
        // 2. El Acorde real, flotando libremente aunque sobrepase la letra
        if (segment.chord != null)
          Positioned(
            left: 0,
            top: 0,
            child: Text(
              segment.chord!,
              style: _effectiveChordStyle.copyWith(height: 1.1),
            ),
          ),
      ],
    ),
    // La Letra (Esta es la que dicta el ancho real del bloque para el Wrap)
    Text(
      segment.text,
      style: _effectiveTextStyle.copyWith(height: 1.1),
    ),
  ],
);
```

### PASO 2: Refactor Lógica - Parseo "Palabra por Palabra"
Abre `lib/core/chords/chord_parser.dart`. Para eliminar el "efecto ladrillo", debes modificar el bucle de parseo `parseChordProLine`. Después de extraer la sección de texto que le sigue a un acorde, **debes dividir esa sección por espacios** antes de crear los `ChordSegment`.

Aplica esta lógica de segmentación exacta al extraer fragmentos:

```dart
// Donde extraes el texto subsecuente a un acorde (dentro de tu iteración/Regex):
String chunkText = /* texto extraído, ej: "rno amor, quiero " */;

// 🔴 CRÍTICO: Separar por espacios para que el Wrap pueda hacer saltos de línea fluidos
List<String> words = chunkText.split(' ');

for (int i = 0; i < words.length; i++) {
  // Reconstruir la palabra con su espacio a la derecha (si no es la última del array)
  String wordWithSpace = words[i] + (i < words.length - 1 ? ' ' : '');
  
  if (wordWithSpace.isEmpty) continue;

  // Solo el primer fragmento de la primera palabra se lleva el acorde.
  if (i == 0) {
    segments.add(ChordSegment(chord: currentChord, text: wordWithSpace));
  } else {
    segments.add(ChordSegment(chord: null, text: wordWithSpace));
  }
}
```

**✅ Validación de Criterios de Éxito:** 1. La palabra `[D]Cerc[D/F#]a` debe renderizarse junta ("Cerca") sin importar qué tan ancho sea el acorde superior.
2. Al aumentar el tamaño de fuente, el texto sin acordes debe saltar a la siguiente línea palabra por palabra, nunca cortándose a la mitad ni desbordando la pantalla.