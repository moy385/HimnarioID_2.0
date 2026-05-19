import 'package:flutter/material.dart';

import '../../core/chords/chord_painter.dart';
import '../../core/chords/chord_parser.dart';

/// Widget que renderiza una línea de texto con acordes en formato ChordPro
/// superpuestos sobre el texto, en las posiciones horizontales exactas.
///
/// Ejemplo:
/// ```
///   C         G
/// Santo  Dios
/// ```
///
/// Usa [ChordPainter] (caché LRU) para medir posiciones con un solo
/// [TextPainter.layout()] y [Stack] + [Positioned] para el renderizado.
class ChordOverlayText extends StatelessWidget {
  /// Línea en formato ChordPro (ej: "[C]Santo [G]Dios").
  final String chordProLine;

  /// Estilo tipográfico del texto de la letra.
  final TextStyle textStyle;

  /// Estilo tipográfico de los acordes (fontFamily, fontSize, color).
  final TextStyle chordStyle;

  /// Ancho máximo disponible para el layout del texto.
  final double maxWidth;

  /// Factor de escala aplicado al espacio vertical de los acordes.
  final double chordScale;

  /// Espaciado vertical mínimo entre acordes consecutivos para evitar
  /// solapamiento visual.
  final double minChordGap;

  /// Alineación del texto. Por defecto [TextAlign.justify].
  final TextAlign textAlign;

  const ChordOverlayText({
    super.key,
    required this.chordProLine,
    required this.textStyle,
    required this.chordStyle,
    required this.maxWidth,
    this.chordScale = 1.0,
    this.minChordGap = 6.0,
    this.textAlign = TextAlign.justify,
  });

  @override
  Widget build(BuildContext context) {
    if (chordProLine.isEmpty) return const SizedBox.shrink();

    // 1. Parsear línea ChordPro
    final segments = parseChordProLine(chordProLine);

    // 2. Verificar si hay acordes
    final hasChords = segments.any((s) => s.chord != null);
    if (!hasChords) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          chordProLine,
          style: textStyle,
          textAlign: textAlign,
        ),
      );
    }

    // 3. Medir posiciones con caché LRU
    final positions = ChordPainter.measurePositions(
      lines: segments,
      style: textStyle,
      maxWidth: maxWidth,
    );

    // 4. Extraer acordes y sus posiciones
    final chordEntries = <_ChordEntry>[];
    int chordIndex = 0;
    for (final segment in segments) {
      if (segment.chord != null && chordIndex < positions.length) {
        chordEntries.add(_ChordEntry(
          chord: segment.chord!,
          position: positions[chordIndex],
        ),);
        chordIndex++;
      }
    }

    // 5. Construir Stack con acordes superpuestos
    final chordFontSize = chordStyle.fontSize ?? 12;
    final chordAreaHeight = chordFontSize * chordScale + 6;

    // Renderizar acordes con anti-solapamiento
    double lastChordRight = double.negativeInfinity;
    final chordWidgets = <Widget>[];

    for (final entry in chordEntries) {
      // Medir ancho del acorde para anti-solapamiento
      final chordWidth = _measureTextWidth(
        entry.chord,
        chordStyle,
        maxWidth,
      );

      double left = entry.position;
      if (left < lastChordRight + minChordGap) {
        left = lastChordRight + minChordGap;
      }
      left = left.clamp(0.0, maxWidth - chordWidth);
      lastChordRight = left + chordWidth;

      chordWidgets.add(Positioned(
        top: 0,
        left: left,
        child: Text(
          entry.chord,
          style: chordStyle.copyWith(height: 1.0),
          textAlign: TextAlign.left,
        ),),);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Texto base (define el tamaño del Stack)
          Padding(
            padding: EdgeInsets.only(top: chordAreaHeight),
          child: Text(
            stripChords(chordProLine),
            style: textStyle,
            textAlign: textAlign,
            softWrap: true,
          ),
          ),
          ...chordWidgets,
        ],
      ),
    );
  }

  /// Mide el ancho de un texto con [TextPainter] usando [chordStyle].
  double _measureTextWidth(String text, TextStyle style, double maxWidth) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: maxWidth);
    return tp.width;
  }
}

/// Datos internos de un acorde con su posición X calculada.
class _ChordEntry {
  final String chord;
  final double position;

  const _ChordEntry({required this.chord, required this.position});
}
