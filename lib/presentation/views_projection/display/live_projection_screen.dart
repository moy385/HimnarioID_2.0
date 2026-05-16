import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/live_control_providers.dart';
import '../providers/projection_providers.dart';
import 'receptor_binding.dart';
import '../../shared_widgets/providers/appearance_provider.dart';
import '../../../core/utils/stanza_layout_engine.dart';

/// Pantalla de Proyección en Vivo (Live Projection).
///
/// Muestra el himno actual en una pantalla grande (TV/proyector) con
/// transiciones suaves entre estrofas usando [AnimatedSwitcher],
/// indicador de progreso minimalista y diseño de alto contraste.
///
/// Lee el estado de [liveControlProvider], la apariencia visual de
/// [hymnAppearanceProvider] (fuente única de verdad para colores y
/// tipografía), y la velocidad de transición de [projectionConfigProvider].
class LiveProjectionScreen extends ConsumerWidget {
  const LiveProjectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final liveState = ref.watch(liveControlProvider);
    final config = ref.watch(projectionConfigProvider);
    final serverInfo = ref.watch(receptorInfoProvider);
    final appearance = ref.watch(hymnAppearanceProvider);

    final bgColor = liveState.isBlackout
        ? Colors.black
        : appearance.bgColor;

    final baseFontSize =
        (textTheme.bodyLarge?.fontSize ?? 36) * appearance.projectionFontScale;

    // ── Blackout: pantalla completamente negra ──
    if (liveState.isBlackout || liveState.hymn == null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const SizedBox.expand(),
      );
    }

    // Procesar contenido con StanzaLayoutEngine
    final double projectionWidth =
        MediaQuery.of(context).size.width - 160; // 80px padding each side
    final processedContent = StanzaLayoutEngine.processStanza(
      liveState.currentStanza?.contenido ?? '',
      maxWidth: projectionWidth,
      style: textTheme.bodyLarge?.copyWith(
        fontFamily: appearance.fontFamily,
        fontSize: baseFontSize * 3.0,
        height: 1.8,
        fontWeight: appearance.isBold ? FontWeight.bold : FontWeight.normal,
      ),
    );

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ── Contenido principal ──
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 80,
                vertical: 60,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Número del himno ──
                  Text(
                    '#${liveState.hymn!.numero ?? liveState.hymn!.id}',
                    style: textTheme.displayLarge?.copyWith(
                      fontFamily: appearance.fontFamily,
                      color: appearance.textColor.withValues(alpha: 0.3),
                      fontWeight: FontWeight.bold,
                      fontSize: baseFontSize * 0.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Título del himno ──
                  Text(
                    liveState.hymn!.titulo,
                    style: textTheme.displayLarge?.copyWith(
                      fontFamily: appearance.fontFamily,
                      color: appearance.textColor,
                      fontSize: baseFontSize * 0.6,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 48),

                  // ── Divisor decorativo ──
                  _buildDivider(colors),
                  const SizedBox(height: 48),

                  // ── Contenido de la estrofa con transición ──
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: Duration(
                        milliseconds: config.transitionDurationMs,
                      ),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      child: SingleChildScrollView(
                        key: ValueKey(
                          '${liveState.currentIndex}_${liveState.currentStanza?.contenido ?? ''}',
                        ),
                        child: Text(
                          processedContent,
                          style: textTheme.bodyLarge?.copyWith(
                            fontFamily: appearance.fontFamily,
                            color: appearance.textColor,
                            fontSize: baseFontSize * 3.0,
                            height: 1.8,
                            fontWeight: appearance.isBold ? FontWeight.bold : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),

                  // ── Indicador de progreso (dots) ──
                  if (liveState.estrofas.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    _buildProgressIndicator(
                      colors,
                      current: liveState.currentIndex,
                      total: liveState.estrofas.length,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Indicador de conexión (esquina inferior derecha) ──
          Positioned(
            right: 24,
            bottom: 24,
            child: _buildConnectionChip(colors, textTheme, serverInfo),
          ),
        ],
      ),
    );
  }

  /// Chip minimalista que indica el estado del servidor gRPC.
  Widget _buildConnectionChip(
    ColorScheme colors,
    TextTheme textTheme,
    ReceptorInfo serverInfo,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: serverInfo.isRunning
                  ? const Color(0xFF4CAF50)
                  : colors.error,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            serverInfo.isRunning
                ? 'Puerto ${serverInfo.port}'
                : 'Servidor detenido',
            style: textTheme.labelSmall?.copyWith(
              color: colors.primary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// Divisor con gradiente horizontal.
  Widget _buildDivider(ColorScheme colors) {
    return SizedBox(
      width: 200,
      height: 2,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              colors.primary.withValues(alpha: 0.5),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  /// Indicador de progreso tipo "puntos" (dots).
  ///
  /// El punto activo es más ancho y usa el color primario.
  /// Los puntos inactivos son pequeños y semitransparentes.
  Widget _buildProgressIndicator(
    ColorScheme colors, {
    required int current,
    required int total,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = i == current;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? colors.primary
                : colors.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
