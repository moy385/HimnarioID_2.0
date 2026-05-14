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
  final String presentationFontFamily;

  const HymnAppearanceState({
    this.bgColor = Colors.transparent,
    this.textColor = const Color(0xFF1C1B1F),
    this.chordColor = const Color(0xFF6750A4),
    this.fontScale = 1.0,
    this.fontFamily = 'Merriweather',
    this.presentationFontFamily = 'Playfair Display',
  });

  HymnAppearanceState copyWith({
    Color? bgColor,
    Color? textColor,
    Color? chordColor,
    double? fontScale,
    String? fontFamily,
    String? presentationFontFamily,
  }) {
    return HymnAppearanceState(
      bgColor: bgColor ?? this.bgColor,
      textColor: textColor ?? this.textColor,
      chordColor: chordColor ?? this.chordColor,
      fontScale: fontScale ?? this.fontScale,
      fontFamily: fontFamily ?? this.fontFamily,
      presentationFontFamily: presentationFontFamily ?? this.presentationFontFamily,
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
  void setPresentationFontFamily(String family) =>
      state = state.copyWith(presentationFontFamily: family);
  void reset() => state = const HymnAppearanceState();
}

final hymnAppearanceProvider =
    StateNotifierProvider<HymnAppearanceNotifier, HymnAppearanceState>((ref) {
  return HymnAppearanceNotifier();
});
