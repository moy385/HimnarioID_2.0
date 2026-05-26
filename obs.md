# 🐛 Reporte de Bug UI y Refactorización: Desalineación y Fractura de Acordes

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