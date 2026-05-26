import 'package:flutter/material.dart';

import '../../core/chords/chord_segment.dart';
import '../../core/chords/chord_parser.dart';

/// Renderiza texto ChordPro con acordes sobre la letra usando Wrap.
///
/// [stanza] es el texto ChordPro (multilínea) de la estrofa.
/// [textStyle] estilo base para la letra (tamaño, color, etc.).
/// [chordStyle] estilo para los acordes (tamaño, color, negrita).
/// [lineSpacing] espacio extra entre líneas de la estrofa.
/// [textAlign] alineación horizontal de la letra (null → left).
/// [runAlignment] alineación vertical de las líneas en el Wrap.
/// [debug] si true, pinta bordes de cada segmento (útil para depuración).
///
/// Diseño:
/// - Cada [ChordSegment] se renderiza con acorde arriba y texto abajo.
/// - [ChordSegment.isLineBreak] fuerza salto de línea real con [lineSpacing].
/// - Usa [Wrap] nativo → reflow automático en cualquier ancho.
/// - No usa Stack, no usa Positioned, no usa CustomPainter.
class ResponsiveChordWidget extends StatelessWidget {
  final String stanza;
  final TextStyle? textStyle;
  final TextStyle? chordStyle;
  final double lineSpacing;
  final TextAlign? textAlign;
  final WrapAlignment runAlignment;
  final bool debug;

  const ResponsiveChordWidget({
    super.key,
    required this.stanza,
    this.textStyle,
    this.chordStyle,
    this.lineSpacing = 8.0,
    this.textAlign,
    this.runAlignment = WrapAlignment.start,
    this.debug = false,
  });

  TextStyle get _effectiveTextStyle =>
      textStyle ?? const TextStyle(fontSize: 16, color: Colors.black87);

  TextStyle get _effectiveChordStyle =>
      chordStyle ??
      const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      );

  @override
  Widget build(BuildContext context) {
    final segments = parseChordProStanza(stanza);
    if (segments.isEmpty) return const SizedBox.shrink();

    final children = <Widget>[];

    for (final seg in segments) {
      if (seg.isLineBreak) {
        children.add(_LineBreakPlaceholder(lineSpacing: lineSpacing));
        continue;
      }

      children.add(
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fila del acorde: texto vacío o acorde
              seg.chord != null
                  ? Text(seg.chord!, style: _effectiveChordStyle)
                  : const SizedBox(height: 0),
              // Fila de la letra
              seg.text.isNotEmpty
                  ? Text(seg.text, style: _effectiveTextStyle, textAlign: textAlign)
                  : const SizedBox(height: 0),
            ],
          ),
        ),
      );
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.start,
      runAlignment: runAlignment,
      children: children,
    );
  }
}

/// Marcador invisible que fuerza un salto de línea real en Wrap.
///
/// Usa una [SizedBox] con ancho infinito para romper la línea actual.
class _LineBreakPlaceholder extends StatelessWidget {
  final double lineSpacing;
  const _LineBreakPlaceholder({required this.lineSpacing});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: lineSpacing,
    );
  }
}
