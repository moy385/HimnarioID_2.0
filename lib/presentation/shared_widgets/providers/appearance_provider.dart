import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado global de apariencia para el modo personal.
/// Controla fondo, colores de texto/acordes y tamaño de fuente.
class HymnAppearanceState {
  final Color bgColor;
  final Color textColor;
  final Color chordColor;
  final double fontScale;
  final String fontFamily;
  final bool isBold;

  const HymnAppearanceState({
    this.bgColor = Colors.transparent,
    this.textColor = const Color(0xFF1C1B1F),
    this.chordColor = const Color(0xFF6750A4),
    this.fontScale = 1.0,
    this.fontFamily = 'Merriweather',
    this.isBold = false,
  });

  HymnAppearanceState copyWith({
    Color? bgColor,
    Color? textColor,
    Color? chordColor,
    double? fontScale,
    String? fontFamily,
    bool? isBold,
  }) {
    return HymnAppearanceState(
      bgColor: bgColor ?? this.bgColor,
      textColor: textColor ?? this.textColor,
      chordColor: chordColor ?? this.chordColor,
      fontScale: fontScale ?? this.fontScale,
      fontFamily: fontFamily ?? this.fontFamily,
      isBold: isBold ?? this.isBold,
    );
  }
}

class HymnAppearanceNotifier extends StateNotifier<HymnAppearanceState> {
  HymnAppearanceNotifier() : super(const HymnAppearanceState());

  void setBgColor(Color color) => state = state.copyWith(bgColor: color);
  void setTextColor(Color color) => state = state.copyWith(textColor: color);
  void setChordColor(Color color) => state = state.copyWith(chordColor: color);
  void setFontScale(double scale) => state = state.copyWith(fontScale: scale);
  void setFontFamily(String family) => state = state.copyWith(fontFamily: family);
  void setIsBold(bool value) => state = state.copyWith(isBold: value);
  void toggleBold() => state = state.copyWith(isBold: !state.isBold);
  void reset() => state = const HymnAppearanceState();
}

final hymnAppearanceProvider =
    StateNotifierProvider<HymnAppearanceNotifier, HymnAppearanceState>((ref) {
  return HymnAppearanceNotifier();
});
