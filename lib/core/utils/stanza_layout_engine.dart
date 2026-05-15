import 'package:flutter/material.dart';

/// Utilidad que procesa el contenido de una estrofa midiendo cada línea
/// con [TextPainter] para decidir si mantener el salto de línea o refluir.
///
/// Si una línea cabe en el ancho disponible → se mantiene el `\n` original.
/// Si una línea NO cabe → se reemplaza su `\n` por espacio para que fluya
/// como párrafo natural, evitando word-wraps forzados que se ven desordenados.
class StanzaLayoutEngine {

  /// Procesa [contenido] midiendo cada línea contra [maxWidth].
  ///
  /// [contenido] — texto con saltos de línea literales (`\n`)
  /// [maxWidth] — ancho máximo disponible en píxeles
  /// [style] — [TextStyle] usado para medir el ancho de cada línea (nullable)
  ///
  /// Retorna el texto transformado.
  static String processStanza(
    String contenido, {
    required double maxWidth,
    TextStyle? style,
  }) {
    if (contenido.isEmpty || maxWidth <= 0) return contenido;

    final effectiveStyle = style ?? const TextStyle();

    final lines = contenido.split('\n');
    if (lines.length <= 1) return contenido;

    final buffer = StringBuffer();

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      buffer.write(line);

      if (i < lines.length - 1) {
        final textPainter = TextPainter(
          text: TextSpan(text: line, style: effectiveStyle),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(maxWidth: maxWidth);

        if (!textPainter.didExceedMaxLines) {
          buffer.write('\n'); // Cabe en 1 línea → mantener salto original
        } else {
          buffer.write(' '); // NO cabe → fluir como párrafo
        }
      }
    }

    return buffer.toString();
  }
}
