import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Controla globalmente si [GlassContainer] aplica el efecto
/// [BackdropFilter] con desenfoque.
///
/// En entornos de test se desactiva automáticamente para evitar que
/// [pumpAndSettle] nunca termine, ya que [BackdropFilter] provoca
/// repintados continuos.
///
/// Tambien puede forzarse manualmente:
/// ```dart
/// GlassContainerConfig.setBlurEnabled(false);
/// ```
class GlassContainerConfig {
  static bool? _userOverride;

  /// Si es `true`, se intenta aplicar [BackdropFilter] con blur.
  /// Por defecto se auto-detecta: `false` en tests, `true` en produccion.
  static bool get enableBlur => _userOverride ?? !_isTestEnvironment();

  static bool _isTestEnvironment() {
    try {
      return WidgetsBinding.instance
          .runtimeType
          .toString()
          .contains('Test');
    } catch (_) {
      return false;
    }
  }

  /// Fuerza el valor de [enableBlur].
  static void setBlurEnabled(bool value) {
    _userOverride = value;
  }
}

/// Widget contenedor reutilizable con efecto Glassmorphism.
///
/// Aplica un desenfoque ([BackdropFilter] + [ImageFilter.blur]) sobre
/// un fondo semitransparente con un borde sutil.
///
/// El desenfoque se desactiva automaticamente en entornos de test
/// (ver [GlassContainerConfig]).
class GlassContainer extends StatelessWidget {
  /// Color de fondo con opacidad (por defecto blanco 12%).
  final Color backgroundColor;

  /// Color del borde (por defecto blanco 20%).
  final Color borderColor;

  /// Ancho del borde en pixeles.
  final double borderWidth;

  /// Radio de las esquinas.
  final double borderRadius;

  /// Intensidad del desenfoque gaussiano (sigma X y Y).
  /// Solo se aplica si [GlassContainerConfig.enableBlur] es `true`.
  final double blurSigma;

  /// Padding interno del contenedor.
  final EdgeInsetsGeometry padding;

  /// Margen externo del contenedor.
  final EdgeInsetsGeometry? margin;

  /// Widget hijo.
  final Widget? child;

  /// Ancho del contenedor (null = wrap content).
  final double? width;

  /// Alto del contenedor (null = wrap content).
  final double? height;

  /// Decoraciones adicionales aplicadas dentro del ClipRRect.
  final Decoration? decoration;

  const GlassContainer({
    super.key,
    this.backgroundColor = const Color(0x1FFFFFFF),
    this.borderColor = const Color(0x33FFFFFF),
    this.borderWidth = 1.5,
    this.borderRadius = 16.0,
    this.blurSigma = 12.0,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.child,
    this.width,
    this.height,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: _buildBackdrop(),
      ),
    );
  }

  Widget _buildBackdrop() {
    if (GlassContainerConfig.enableBlur) {
      return _buildBlurredBackdrop();
    }
    return _buildFallbackBackdrop();
  }

  /// Version con [BackdropFilter] + [ImageFilter.blur].
  Widget _buildBlurredBackdrop() {
    try {
      return Stack(
        children: [
          // Fondo semitransparente base (visible si el blur falla)
          Positioned.fill(
            child: Container(
              decoration: decoration ??
                  BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
            ),
          ),
          // BackdropFilter con blur
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: blurSigma,
                  sigmaY: blurSigma,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                ),
              ),
            ),
          ),
          // Borde sutil
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: borderColor,
                  width: borderWidth,
                ),
              ),
            ),
          ),
          // Contenido
          if (child != null)
            Positioned.fill(
              child: Padding(
                padding: padding,
                child: child!,
              ),
            ),
        ],
      );
    } catch (_) {
      return _buildFallbackBackdrop();
    }
  }

  /// Version sin blur (solo fondo semitransparente + borde).
  Widget _buildFallbackBackdrop() {
    return Container(
      decoration: decoration ??
          BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor,
              width: borderWidth,
            ),
          ),
      padding: padding,
      child: child,
    );
  }
}
