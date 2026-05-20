import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/chords/chord_parser.dart';
import '../../../core/enums/estrofa_tipo.dart';
import '../../../core/enums/fondo_pantalla_tipo.dart';
import '../../../core/utils/stanza_layout_engine.dart';
import '../../../domain/entities/estrofa.dart';
import '../../../domain/entities/projection_slide.dart';
import '../../shared_widgets/chord_overlay_text.dart';
import '../../shared_widgets/providers/appearance_provider.dart';
import '../providers/live_control_providers.dart';
import '../providers/projection_providers.dart';
import 'receptor_binding.dart';

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

    final slideContent = _buildSlideContent(
      context,
      ref,
      liveState,
      baseFontSize,
      config,
      appearance,
      textTheme,
      colors,
    );

    return Scaffold(
      backgroundColor: bgColor,
      body: _buildFondo(appearance, Stack(
        children: [
          slideContent,
          // ── Indicador de conexión (esquina inferior derecha) ──
          Positioned(
            right: 24,
            bottom: 24,
            child: _buildConnectionChip(colors, textTheme, serverInfo),
          ),
        ],
      )),
    );
  }

  /// Envuelve el contenido con el fondo apropiado (imagen, video o color sólido).
  Widget _buildFondo(HymnAppearanceState appearance, Widget slideContent) {
    final fondo = appearance.selectedFondo;
    if (fondo == null) {
      return slideContent;
    }
    return switch (fondo.tipo) {
      FondoPantallaTipo.colorSolido => slideContent,
      FondoPantallaTipo.imagen => Stack(
          children: [
            if (fondo.rutaArchivo != null)
              Positioned.fill(
                child: Image.file(
                  File(fondo.rutaArchivo!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            slideContent,
          ],
        ),
      FondoPantallaTipo.video => Stack(
          children: [
            Container(color: Colors.black87),
            Container(color: Colors.black26),
            slideContent,
          ],
        ),
    };
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
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
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

/// Slide de letra: contenido de la estrofa con fontSize fijo.
///
/// El fontSize es siempre `baseFontSize * 3.5`. Si el contenido no cabe
/// verticalmente, se envuelve en [SingleChildScrollView] para scroll.
///
/// Mantiene [AnimatedSwitcher] para transiciones suaves,
/// [StanzaLayoutEngine.processStanza] para el formateo inteligente,
/// y progress indicator (dots) que refleja el total de slides.
///
/// Cuando [appearance.showChords] es `true`, renderiza cada línea con
/// [ChordOverlayText] para superponer acordes sobre el texto.
/// Cuando es `false`, usa el comportamiento original (texto limpio sin acordes).
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
        MediaQuery.of(context).size.width - 80; // 40px padding each side
    final double screenHeight = MediaQuery.of(context).size.height;
    final double estrofaLabelHeight = 40.0;
    final double progressDotsHeight = totalSlides > 1 ? 32.0 : 0.0;
    final double availableHeight =
        screenHeight - 48 - estrofaLabelHeight - progressDotsHeight;
    final showChords = appearance.showChords;

    // Estilo base del texto de la letra (proyección)
    final TextStyle lyricStyle =
        (textTheme.bodyLarge ?? const TextStyle()).copyWith(
      fontFamily: appearance.fontFamily,
      color: appearance.textColor,
      fontSize: baseFontSize * 3.5,
      height: 1.8,
      fontWeight: appearance.isBold ? FontWeight.bold : FontWeight.normal,
    );

    // Estilo de acordes para proyección (50% del fontSize de la letra)
    final TextStyle chordStyle = TextStyle(
      fontFamily: appearance.fontFamily,
      color: appearance.chordColor,
      fontWeight: FontWeight.bold,
      fontSize: (baseFontSize * 3.5 * 0.5).clamp(24.0, 80.0),
    );

    // ── Detección de desbordamiento vertical ──
    final double contentHeight = _measureContentHeight(
      contenido: contenido,
      projectionWidth: projectionWidth,
      lyricStyle: lyricStyle,
      chordStyle: chordStyle,
      showChords: showChords,
    );
    final bool needsScroll = contentHeight > availableHeight;

    return Stack(
      children: [
        // ── Texto de la estrofa: ocupa todo el espacio disponible ──
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: _buildScrollableContent(
                projectionWidth: projectionWidth,
                lyricStyle: lyricStyle,
                chordStyle: chordStyle,
                showChords: showChords,
                needsScroll: needsScroll,
              ),
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

  /// Renderiza el contenido procesado sin acordes (comportamiento original).
  Widget _buildPlainContent(
    String content,
    double width,
    TextStyle style,
  ) {
    final processed = StanzaLayoutEngine.processStanza(
      stripChords(content),
      maxWidth: width,
      style: style,
    );

    return Text(
      processed,
      key: const ValueKey('plain'),
      style: style,
      textAlign: TextAlign.center,
    );
  }

  /// Aplica [StanzaLayoutEngine.processStanza] al contenido ChordPro:
  /// mide con el texto limpio (sin acordes) para decidir saltos de línea,
  /// pero preserva los marcadores originales en el resultado.
  String _reflowChordContent(
    String content,
    double width,
    TextStyle style,
  ) {
    if (content.isEmpty || width <= 0) return content;

    final stripped = stripChords(content);

    // Paso 1: obtener el texto plano con saltos optimizados
    final processed = StanzaLayoutEngine.processStanza(
      stripped,
      maxWidth: width,
      style: style,
    );

    // Paso 2: reconstruir contenido ChordPro aplicando las mismas uniones
    final originalLines = content.split('\n');
    final processedLines = processed.split('\n');

    final result = <String>[];
    int origIdx = 0;

    for (final targetLine in processedLines) {
      final buffer = StringBuffer(originalLines[origIdx]);
      origIdx++;

      while (origIdx < originalLines.length) {
        if (stripChords(buffer.toString()) == targetLine) break;
        buffer.write(' ');
        buffer.write(originalLines[origIdx]);
        origIdx++;
      }

      result.add(buffer.toString());
    }

    return result.join('\n');
  }

  /// Renderiza el contenido ChordPro línea por línea con [ChordOverlayText].
  ///
  /// Cada línea se renderiza con alineación izquierda para que los acordes
  /// se posicionen correctamente. El [Column] se centra como bloque gracias
  /// al [Center] + [MainAxisAlignment.center] del padre.
  Widget _buildChordProContent(
    String content,
    double width,
    TextStyle lyricStyle,
    TextStyle chordStyle,
  ) {
    // Aplicar reflow inteligente para unir líneas que caben en un mismo
    // renglón, igual que se hace en _buildPlainContent con processStanza
    final reflowed = _reflowChordContent(content, width, lyricStyle);
    final lines = reflowed.split('\n');

    return Column(
      key: const ValueKey('chords'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: lines.map((line) {
        if (line.trim().isEmpty) {
          return SizedBox(height: lyricStyle.fontSize! * 0.8);
        }
        // Verificar si la línea tiene acordes
        final hasChords = chordRegex.hasMatch(line);
        if (!hasChords) {
          // Línea sin acordes → texto plano (alineación izquierda para
          // consistencia visual con las líneas que SÍ tienen acordes)
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              line,
              style: lyricStyle,
              textAlign: TextAlign.left,
            ),
          );
        }
        return ChordOverlayText(
          chordProLine: line,
          textStyle: lyricStyle,
          chordStyle: chordStyle,
          maxWidth: width,
          textAlign: TextAlign.left,
          minChordGap: 12.0,
        );
      }).toList(),
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

  /// Construye el contenido del slide, con scroll si desborda verticalmente.
  Widget _buildScrollableContent({
    required double projectionWidth,
    required TextStyle lyricStyle,
    required TextStyle chordStyle,
    required bool showChords,
    required bool needsScroll,
  }) {
    final content = showChords
        ? _buildChordProContent(
            contenido,
            projectionWidth,
            lyricStyle,
            chordStyle,
          )
        : _buildPlainContent(
            contenido,
            projectionWidth,
            lyricStyle,
          );

    if (needsScroll) {
      return SingleChildScrollView(
        key: const ValueKey('scroll'),
        child: content,
      );
    }
    return content;
  }

  /// Mide la altura total del contenido para detectar desbordamiento.
  double _measureContentHeight({
    required String contenido,
    required double projectionWidth,
    required TextStyle lyricStyle,
    required TextStyle chordStyle,
    required bool showChords,
  }) {
    if (showChords) {
      return _measureChordContentHeight(
        text: contenido,
        style: lyricStyle,
        chordStyle: chordStyle,
        maxWidth: projectionWidth,
      );
    }
    return _measurePlainContentHeight(
      text: contenido,
      style: lyricStyle,
      maxWidth: projectionWidth,
    );
  }

  double _measurePlainContentHeight({
    required String text,
    required TextStyle style,
    required double maxWidth,
  }) {
    final stripped = stripChords(text);
    final processed = StanzaLayoutEngine.processStanza(
      stripped,
      maxWidth: maxWidth,
      style: style,
    );
    final tp = TextPainter(
      text: TextSpan(text: processed, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return tp.height;
  }

  double _measureChordContentHeight({
    required String text,
    required TextStyle style,
    required TextStyle chordStyle,
    required double maxWidth,
  }) {
    final reflowed = _reflowChordContent(text, maxWidth, style);
    final lines = reflowed.split('\n');
    final fontSize = style.fontSize ?? 14;
    final effectiveLineHeight = (style.height ?? 1.0) * fontSize;
    double totalHeight = 0;

    for (final line in lines) {
      if (line.trim().isEmpty) {
        totalHeight += fontSize * 0.8;
        continue;
      }
      final hasChordsInLine = chordRegex.hasMatch(line);
      final plainText = stripChords(line);
      final tp = TextPainter(
        text: TextSpan(text: plainText, style: style),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxWidth);

      final numVisualLines =
          (tp.height / effectiveLineHeight).ceil().clamp(1, 100);
      final textHeight = numVisualLines * effectiveLineHeight;

      if (!hasChordsInLine) {
        totalHeight += textHeight + 4;
      } else {
        final chordAreaHeight = (chordStyle.fontSize ?? 14) * 1.0 + 6;
        totalHeight += chordAreaHeight + textHeight + 8;
      }
    }
    return totalHeight;
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
