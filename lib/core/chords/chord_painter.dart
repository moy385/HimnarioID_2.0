import 'dart:ui' show FontWeight, Rect, TextDirection, TextPosition;

import 'package:flutter/material.dart' show TextPainter, TextStyle, TextSpan;

import 'chord_line.dart';

/// Clave para el caché de posiciones de acordes.
///
/// Combina todos los factores que afectan la medición tipográfica:
/// texto plano, fontSize, fontFamily, fontWeight, maxWidth y altura de línea.
final class _PositionCacheKey {
  final String plainText;
  final double fontSize;
  final String fontFamily;
  final FontWeight fontWeight;
  final double maxWidth;
  final double height;

  const _PositionCacheKey({
    required this.plainText,
    required this.fontSize,
    required this.fontFamily,
    required this.fontWeight,
    required this.maxWidth,
    required this.height,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _PositionCacheKey &&
          plainText == other.plainText &&
          fontSize == other.fontSize &&
          fontFamily == other.fontFamily &&
          fontWeight == other.fontWeight &&
          maxWidth == other.maxWidth &&
          height == other.height;

  @override
  int get hashCode =>
      Object.hash(plainText, fontSize, fontFamily, fontWeight, maxWidth, height);
}

/// Datos de posición de un acorde dentro del texto completo.
class _ChordPosition {
  final int textStartIndex;
  final String chord;

  const _ChordPosition({
    required this.textStartIndex,
    required this.chord,
  });
}

/// Utilidad para medir posiciones de acordes sobre texto usando [TextPainter].
///
/// Mantiene un caché LRU para evitar relayouts innecesarios cuando el mismo
/// texto plano se mide repetidamente con los mismos parámetros tipográficos.
///
/// Uso:
/// ```dart
/// final positions = ChordPainter.measurePositions(
///   lines: chordLines,
///   style: TextStyle(fontSize: 16, fontFamily: 'Merriweather'),
///   maxWidth: 400,
/// );
/// ```
class ChordPainter {
  ChordPainter._();

  /// Caché LRU: clave = [_PositionCacheKey], valor = lista de posiciones X
  /// para cada acorde en el orden de [lines] (una entrada por acorde).
  static final _cache = <_PositionCacheKey, List<double>>{};

  /// Tamaño máximo del caché para evitar crecimiento infinito.
  static const int _maxCacheSize = 64;

  /// Mide la posición horizontal (offset X) de cada acorde en [lines]
  /// usando [TextPainter].
  ///
  /// Retorna una lista plana de posiciones X en el mismo orden que los acordes
  /// aparecen al recorrer [lines] secuencialmente. Para cada acorde, se calcula
  /// la posición del texto previo a ese acorde dentro de la línea.
  ///
  /// [style] define la apariencia del texto (se usa fontSize, fontFamily,
  /// fontWeight para la clave de caché).
  ///
  /// [maxWidth] es el ancho máximo disponible para el layout del texto.
  ///
  /// El resultado se cachea por clave compuesta de (plainText, fontSize,
  /// fontFamily, fontWeight, maxWidth, height).
  static List<double> measurePositions({
    required List<ChordLine> lines,
    required TextStyle style,
    required double maxWidth,
  }) {
    if (lines.isEmpty) return [];

    // Construir texto plano y recopilar acordes con sus posiciones
    final buffer = StringBuffer();
    final chordPositions = <_ChordPosition>[];

    for (final line in lines) {
      if (line.chord != null) {
        chordPositions.add(_ChordPosition(
          textStartIndex: buffer.length,
          chord: line.chord!,
        ),);
      }
      buffer.write(line.text);
    }

    if (chordPositions.isEmpty) return [];

    final plainText = buffer.toString();

    // Clave de caché
    final cacheKey = _PositionCacheKey(
      plainText: plainText,
      fontSize: style.fontSize ?? 14,
      fontFamily: style.fontFamily ?? '',
      fontWeight: style.fontWeight ?? FontWeight.normal,
      maxWidth: maxWidth,
      height: style.height ?? 1.0,
    );

    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    // Medir con un solo TextPainter sobre todo el texto plano
    final tp = TextPainter(
      text: TextSpan(text: plainText, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    final result = <double>[];
    for (final cp in chordPositions) {
      final offset = tp.getOffsetForCaret(
        TextPosition(offset: cp.textStartIndex),
        Rect.zero,
      );
      result.add(offset.dx);
    }

    // Almacenar en caché con control de tamaño LRU
    _cache[cacheKey] = result;
    if (_cache.length > _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }

    return result;
  }

  /// Limpia el caché de posiciones. Útil cuando cambian parámetros globales
  /// de apariencia (tema, escala de fuente, etc.).
  static void clearCache() {
    _cache.clear();
  }
}
