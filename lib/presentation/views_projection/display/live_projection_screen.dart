import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/estrofa_tipo.dart';
import '../../../domain/entities/estrofa.dart';
import '../../../domain/entities/projection_slide.dart';
import '../providers/live_control_providers.dart';
import '../providers/projection_providers.dart';
import 'receptor_binding.dart';
import '../../shared_widgets/providers/appearance_provider.dart';
import '../../../core/utils/stanza_layout_engine.dart';

/// Pantalla de Proyección en Vivo (Live Projection).
///
/// Renderiza el slide actual según su tipo:
/// - [TitleSlide]  → portada con título + número
/// - [LyricsSlide] → letra de estrofa con transición
/// - [AmenSlide]   → "Amén" de cierre
///
/// Lee el estado de [liveControlProvider], la apariencia visual de
/// [hymnAppearanceProvider] y la velocidad de transición de
/// [projectionConfigProvider].
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

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ── Contenido del slide según su tipo ──
          _buildSlideContent(
            context,
            ref,
            liveState,
            baseFontSize,
            config,
            appearance,
            textTheme,
            colors,
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

  /// Delega la renderización al widget especializado según el tipo de slide.
  Widget _buildSlideContent(
    BuildContext context,
    WidgetRef ref,
    LiveControlState liveState,
    double baseFontSize,
    ProjectionConfig config,
    HymnAppearanceState appearance,
    TextTheme textTheme,
    ColorScheme colors,
  ) {
    final slide = liveState.currentSlide;
    if (slide == null) return const SizedBox.shrink();

    return switch (slide) {
      TitleSlide(:final himno) => _TitleSlide(
          titulo: himno.titulo,
          numero: himno.numero,
          baseFontSize: baseFontSize,
          appearance: appearance,
          textTheme: textTheme,
        ),
      LyricsSlide(:final estrofa) => _LyricsSlide(
          key: ValueKey('lyrics_${liveState.currentSlideIndex}'),
          estrofa: estrofa,
          contenido: estrofa.contenido,
          baseFontSize: baseFontSize,
          transitionDuration: config.transitionDurationMs,
          totalSlides: liveState.slides.length,
          currentSlideIndex: liveState.currentSlideIndex,
          appearance: appearance,
          textTheme: textTheme,
        ),
      AmenSlide() => _AmenSlide(
          baseFontSize: baseFontSize,
          appearance: appearance,
        ),
    };
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

}

// ═══════════════════════════════════════════════════════════════
// Slide widgets
// ═══════════════════════════════════════════════════════════════

/// Slide de portada: título enorme + número semitransparente.
///
/// Ocupa todo el espacio disponible centrado vertical y horizontalmente.
/// Sin [AnimatedSwitcher], sin scroll, sin progress indicator.
class _TitleSlide extends StatelessWidget {
  final String titulo;
  final int? numero;
  final double baseFontSize;
  final HymnAppearanceState appearance;
  final TextTheme textTheme;

  const _TitleSlide({
    required this.titulo,
    required this.numero,
    required this.baseFontSize,
    required this.appearance,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Título enorme
            Text(
              titulo,
              style: textTheme.displayLarge?.copyWith(
                fontFamily: appearance.fontFamily,
                color: appearance.textColor,
                fontSize: baseFontSize * 4.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            // Número semitransparente
            if (numero != null)
              Text(
                '#$numero',
                style: textTheme.displayLarge?.copyWith(
                  fontFamily: appearance.fontFamily,
                  color: appearance.textColor.withValues(alpha: 0.3),
                  fontWeight: FontWeight.bold,
                  fontSize: baseFontSize * 0.4,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Slide de letra: solo el contenido de la estrofa, texto enormizado.
///
/// Mantiene [AnimatedSwitcher] para transiciones suaves,
/// [StanzaLayoutEngine.processStanza] para el formateo inteligente,
/// y progress indicator (dots) que refleja el total de slides.
///
/// Sin scroll, sin título ni número arriba.
class _LyricsSlide extends StatelessWidget {
  final Estrofa estrofa;
  final String contenido;
  final double baseFontSize;
  final int transitionDuration;
  final int totalSlides;
  final int currentSlideIndex;
  final HymnAppearanceState appearance;
  final TextTheme textTheme;

  const _LyricsSlide({
    super.key,
    required this.estrofa,
    required this.contenido,
    required this.baseFontSize,
    required this.transitionDuration,
    required this.totalSlides,
    required this.currentSlideIndex,
    required this.appearance,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final double projectionWidth =
        MediaQuery.of(context).size.width - 160; // 80px padding each side

    final processedContent = StanzaLayoutEngine.processStanza(
      contenido,
      maxWidth: projectionWidth,
      style: textTheme.bodyLarge?.copyWith(
        fontFamily: appearance.fontFamily,
        fontSize: baseFontSize * 3.5,
        height: 1.8,
        fontWeight: appearance.isBold ? FontWeight.bold : FontWeight.normal,
      ),
    );

    return Stack(
      children: [
        // ── Texto de la estrofa: ocupa todo el espacio disponible ──
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 24),
            child: Text(
              processedContent,
              key: ValueKey(contenido),
              style: textTheme.bodyLarge?.copyWith(
                fontFamily: appearance.fontFamily,
                color: appearance.textColor,
                fontSize: baseFontSize * 3.5,
                height: 1.8,
                fontWeight:
                    appearance.isBold ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),

        // ── Etiqueta de estrofa superpuesta arriba ──
        Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: _buildEstrofaLabel(),
        ),

        // ── Indicador de progreso superpuesto abajo ──
        if (totalSlides > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child:
                _buildProgressIndicatorDots(totalSlides, currentSlideIndex),
          ),
      ],
    );
  }

  /// Etiqueta sutil del tipo de estrofa: "Estrofa 1", "Coro", "Puente 2", etc.
  Widget _buildEstrofaLabel() {
    final label = estrofa.tipo == EstrofaTipo.coro
        ? 'Coro'
        : '${estrofa.tipo.value} ${estrofa.orden + 1}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: textTheme.bodyMedium?.copyWith(
          fontFamily: appearance.fontFamily,
          color: appearance.textColor.withValues(alpha: 0.6),
          fontSize: baseFontSize * 1.0,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Indicador de progreso tipo "puntos" reutilizable.
  Widget _buildProgressIndicatorDots(int total, int current) {
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
                ? appearance.textColor
                : appearance.textColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

/// Slide de cierre: "Amén" centrado, full screen, fuente enorme.
///
/// Sin [AnimatedSwitcher], sin progress indicator, sin scroll.
class _AmenSlide extends StatelessWidget {
  final double baseFontSize;
  final HymnAppearanceState appearance;

  const _AmenSlide({
    required this.baseFontSize,
    required this.appearance,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Amén',
        style: TextStyle(
          fontFamily: appearance.fontFamily,
          color: appearance.textColor,
          fontSize: baseFontSize * 5.0,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
