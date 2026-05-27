import 'package:flutter/material.dart';

import '../../core/theme/glassmorphism.dart';

/// Tarjeta con efecto Glassmorphism que emula una [Card] de Material.
///
/// Usa [GlassContainer] internamente con valores predeterminados
/// optimizados para tarjetas de lista (HymnCard) y decoraciones.
///
/// Sigue la paleta corporativa Negro/Dorado/Blanco ajustando colores
/// según el [ColorScheme] del tema activo.
class GlassCard extends StatelessWidget {
  /// Widget hijo de la tarjeta.
  final Widget child;

  /// Callback al presionar la tarjeta.
  final VoidCallback? onTap;

  /// Radio de las esquinas.
  final double borderRadius;

  /// Padding interno.
  final EdgeInsetsGeometry padding;

  /// Margen externo.
  final EdgeInsetsGeometry? margin;

  /// Si es `true`, usa el borde dorado en lugar del blanco sutil.
  final bool goldBorder;

  /// Color de fondo con opacidad. Por defecto usa el valor del tema.
  final Color? backgroundColor;

  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.goldBorder = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    final bgColor = backgroundColor ??
        (isDark
            ? const Color(0x1FFFFFFF)
            : const Color(0x0F000000));
    final border = goldBorder
        ? colorScheme.primary.withValues(alpha: 0.25)
        : (isDark
            ? const Color(0x33FFFFFF)
            : const Color(0x1A000000));

    final card = GlassContainer(
      backgroundColor: bgColor,
      borderColor: border,
      borderWidth: 1.2,
      borderRadius: borderRadius,
      blurSigma: 14.0,
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: card,
        ),
      );
    }

    return card;
  }
}
