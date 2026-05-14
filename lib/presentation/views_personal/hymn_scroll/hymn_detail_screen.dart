import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/utils/chord_transposer.dart';
import '../../../domain/entities/estrofa.dart';
import '../../../domain/entities/himno.dart';
import '../../shared_widgets/control_sheets.dart';
import '../providers/audio_providers.dart';
import '../../views_projection/providers/connection_providers.dart';
import '../providers/hymn_providers.dart';
import '../providers/transpose_providers.dart';
import 'arrangement_editor_screen.dart';
import 'fab_menu.dart';

/// Pantalla de detalle del himno (Formato Scroll para móvil).
/// Muestra letra completa con acordes y controles de transposición
/// conectados a Riverpod.
class HymnDetailScreen extends ConsumerStatefulWidget {
  static final _log = Logger('HymnDetailScreen');

  final Himno himno;

  const HymnDetailScreen({
    super.key,
    required this.himno,
  });

  @override
  ConsumerState<HymnDetailScreen> createState() => _HymnDetailScreenState();
}

class _HymnDetailScreenState extends ConsumerState<HymnDetailScreen> {
  bool _isPlaying = false;
  double _fontScale = 1.0;
  int _bgColorIndex = 0;
  bool _showChords = true;

  static const List<Color> _bgColors = [
    Colors.transparent,
    Color(0xFFF5F0E8),
    Color(0xFFE8F0F5),
    Color(0xFFF0F5E8),
    Color(0xFFF5E8F0),
  ];

  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    if (_isPlaying) {
      _playAudio();
    } else {
      _stopAudio();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final transposeValue = ref.watch(transposeValueProvider);
    final transposedKey = ref.watch(transposedKeyProvider);
    final stanzasAsync = ref.watch(stanzasProvider(widget.himno.primaryVersionPaisId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Himno ${widget.himno.numero ?? ''}'),
        actions: [
          // Menú de opciones
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'arreglo') {
                Navigator.pushNamed(
                  context,
                  '/arrangement-editor',
                  arguments: widget.himno,
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'arreglo',
                child: Row(
                  children: [
                    Icon(Icons.edit_note),
                    SizedBox(width: 12),
                    Text('Crear Arreglo'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Contenido scrollable
          Expanded(
            child: Container(
              color: _bgColors[_bgColorIndex],
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabecera del himno
                    _buildHeader(context, widget.himno, colorScheme, textTheme),
                    const SizedBox(height: 24),

                    // Renderizado de letra desde provider
                    stanzasAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, stack) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: colorScheme.error,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error al cargar la letra',
                                style: textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      data: (estrofas) {
                        if (estrofas.isEmpty) {
                          return Center(
                            child: Text(
                              'No hay estrofas disponibles',
                              style: textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: estrofas.map((estrofa) {
                            return _buildStanza(
                              context,
                              estrofa,
                              transposeValue,
                              colorScheme,
                              textTheme,
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Barra inferior sticky con controles
          _buildBottomBar(context, transposeValue, transposedKey),
        ],
      ),
      floatingActionButton: FabMenu(
        onBrushTap: _showBrochaSheet,
        onNoteTap: _showNotaSheet,
        onSolfaTap: _showSolfaSheet,
        onSearchTap: _showLupaDialog,
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Himno himno,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        Text(
          himno.titulo,
          style: textTheme.headlineSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // Etiquetas
        Wrap(
          spacing: 8,
          children: [
            Chip(
              label: Text(himno.categoria),
              backgroundColor: colorScheme.tertiaryContainer,
              labelStyle: textTheme.labelSmall?.copyWith(
                color: colorScheme.onTertiaryContainer,
              ),
              side: BorderSide.none,
            ),
            if (!himno.esOficial)
              Chip(
                label: const Text('Personal'),
                backgroundColor: colorScheme.secondaryContainer,
                labelStyle: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                ),
                side: BorderSide.none,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStanza(
    BuildContext context,
    Estrofa estrofa,
    int transposeValue,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final isChorus = estrofa.isChorus;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isChorus
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: isChorus
            ? Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
                width: 1,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Etiqueta de tipo de estrofa
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isChorus
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              estrofa.tipo.value.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                color: isChorus
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Letra con acordes transpuestos
          _buildLyricWithChords(
            context,
            estrofa.contenido,
            transposeValue,
            colorScheme,
            textTheme,
          ),
        ],
      ),
    );
  }

  Widget _buildLyricWithChords(
    BuildContext context,
    String lyric,
    int transposeValue,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final chordRegex =
        RegExp(r'\[([A-G][#b]?m?\d*(?:sus|dim|aug|Maj|maj)?[0-9]*)\]');

    // Transponer usando el utility ChordTransposer
    final transposedLyric = transposeChordPro(lyric, transposeValue);
    final parts = transposedLyric.split('\n');

    // Escala base para el texto de la letra
    final double baseFontSize =
        (textTheme.bodyLarge?.fontSize ?? 16) * _fontScale;
    final double chordFontSize = 14 * _fontScale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts.map((line) {
        if (!_showChords) {
          // Sin acordes: mostrar solo texto plano
          final plainLine = line.replaceAll(chordRegex, '');
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              plainLine,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
                fontSize: baseFontSize,
                height: 1.6,
              ),
            ),
          );
        }

        // Buscar acordes en formato [Acorde]Texto
        final matches = chordRegex.allMatches(line);

        if (matches.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              line,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
                fontSize: baseFontSize,
                height: 1.6,
              ),
            ),
          );
        }

        // Renderizar línea con acordes
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: RichText(
            text: TextSpan(
              children: _parseChordsInLine(
                line,
                chordRegex,
                colorScheme,
                textTheme,
                baseFontSize,
                chordFontSize,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<TextSpan> _parseChordsInLine(
    String line,
    RegExp chordRegex,
    ColorScheme colorScheme,
    TextTheme textTheme, [
    double baseFontSize = 16,
    double chordFontSize = 14,
  ]) {
    final segments = <TextSpan>[];
    int lastEnd = 0;

    for (final match in chordRegex.allMatches(line)) {
      // Texto antes del acorde
      if (match.start > lastEnd) {
        segments.add(
          TextSpan(
            text: line.substring(lastEnd, match.start),
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
              fontSize: baseFontSize,
            ),
          ),
        );
      }

      // El acorde (sin los corchetes)
      final chord = match.group(1) ?? '';
      segments.add(
        TextSpan(
          text: chord,
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.tertiary,
            fontWeight: FontWeight.bold,
            fontSize: chordFontSize,
          ),
        ),
      );

      lastEnd = match.end;
    }

    // Texto restante después del último acorde
    if (lastEnd < line.length) {
      segments.add(
        TextSpan(
          text: line.substring(lastEnd),
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
            fontSize: baseFontSize,
          ),
        ),
      );
    }

    return segments;
  }

  Widget _buildBottomBar(
    BuildContext context,
    int transposeValue,
    String transposedKey,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Controles de transposición
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      ref.read(transposeValueProvider.notifier).state =
                          (transposeValue - 1).clamp(-6, 6);
                    },
                    icon: const Icon(Icons.remove),
                    tooltip: 'Bajar tono',
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tono',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          transposedKey,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ref.read(transposeValueProvider.notifier).state =
                          (transposeValue + 1).clamp(-6, 6);
                    },
                    icon: const Icon(Icons.add),
                    tooltip: 'Subir tono',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Botón de reproducir audio — cambia visualmente entre estados
            IconButton.filled(
              onPressed: _togglePlayback,
              icon: Icon(
                _isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
              ),
              style: IconButton.styleFrom(
                backgroundColor: _isPlaying
                    ? colorScheme.errorContainer
                    : colorScheme.secondaryContainer,
                foregroundColor: _isPlaying
                    ? colorScheme.onErrorContainer
                    : colorScheme.onSecondaryContainer,
              ),
              tooltip: _isPlaying ? 'Detener audio' : 'Reproducir audio',
            ),
            const Spacer(),
            // Botón PROYECTAR con icono cast consistente
            FilledButton.icon(
              onPressed: () {
                _projectHymn(context);
              },
              icon: const Icon(Icons.cast_rounded),
              label: const Text('PROYECTAR'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Envía el himno al display remoto (si hay conexión) y navega
  /// a la pantalla de control en vivo.
  Future<void> _projectHymn(BuildContext context) async {
    final isConnected = ref.read(isConnectedProvider);
    if (isConnected) {
      try {
        await ref
            .read(controlRepositoryProvider)
            .sendShowHimno(widget.himno.id);
      } catch (e) {
        HymnDetailScreen._log.warning('Error al enviar himno al display: $e');
        // Fallback offline: continuar con navegación local
      }
    } else {
      HymnDetailScreen._log.info('Sin conexión al display — modo local');
    }

    if (!context.mounted) return;
    await Navigator.pushNamed(
      context,
      '/live-control',
      arguments: widget.himno,
    );
  }

  @override
  void dispose() {
    if (_isPlaying) {
      // Disparar stop sin await — el widget se está destruyendo
      ref.read(audioRepositoryProvider).stop();
      _isPlaying = false;
    }
    super.dispose();
  }

  void _playAudio() {
    final audioRepo = ref.read(audioRepositoryProvider);
    audioRepo.play(widget.himno.id).then((_) {
      if (!mounted) return;
      setState(() => _isPlaying = true);
      ref.read(isAudioPlayingProvider.notifier).state = true;
      HymnDetailScreen._log.info(
        'Reproduciendo audio para himno ${widget.himno.id}',
      );
    }).catchError((error) {
      if (!mounted) return;
      setState(() => _isPlaying = false);
      ref.read(isAudioPlayingProvider.notifier).state = false;
      HymnDetailScreen._log.warning('Error al reproducir audio: $error');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo reproducir el audio'),
          duration: Duration(seconds: 3),
        ),
      );
    });
  }

  void _stopAudio() {
    final audioRepo = ref.read(audioRepositoryProvider);
    audioRepo.stop().then((_) {
      if (!mounted) return;
      setState(() => _isPlaying = false);
      ref.read(isAudioPlayingProvider.notifier).state = false;
      HymnDetailScreen._log.info('Audio detenido');
    }).catchError((error) {
      if (!mounted) return;
      setState(() => _isPlaying = false);
      ref.read(isAudioPlayingProvider.notifier).state = false;
      HymnDetailScreen._log.warning('Error al detener audio: $error');
    });
  }

  // ---------------------------------------------------------------------------
  // FAB — Brocha: Configuración visual (tamaño fuente, color fondo)
  // ---------------------------------------------------------------------------
  void _showBrochaSheet() {
    showBrushSheet(
      context,
      fontScale: _fontScale,
      onFontScaleChanged: (double value) {
        setState(() {
          _fontScale = value;
        });
      },
      bgColorIndex: _bgColorIndex,
      onBgColorIndexChanged: (int value) {
        setState(() {
          _bgColorIndex = value;
        });
      },
      bgColors: _bgColors,
    );
  }

  // ---------------------------------------------------------------------------
  // FAB — Nota: Panel de pistas de audio
  // ---------------------------------------------------------------------------
  void _showNotaSheet() {
    showNoteSheet(
      context,
      ref: ref,
      himnoId: widget.himno.id,
      isPlaying: _isPlaying,
      onPlay: _playAudio,
      onStop: _stopAudio,
    );
  }

  // ---------------------------------------------------------------------------
  // FAB — Solfa: Panel de músico (transposición, acordes)
  // ---------------------------------------------------------------------------
  void _showSolfaSheet() {
    showSolfaSheet(
      context,
      ref: ref,
      showChords: _showChords,
      onShowChordsChanged: (bool value) {
        setState(() {
          _showChords = value;
        });
      },
      onCreateArrangement: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArrangementEditorScreen(himno: widget.himno),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // FAB — Lupa: Diálogo de búsqueda de himnos
  // ---------------------------------------------------------------------------
  Future<void> _showLupaDialog() async {
    final result = await showSearchSheet(
      context,
      ref: ref,
      currentHimnoId: widget.himno.id,
    );

    // Si se seleccionó un himno (distinto del actual), navegar a su detalle
    if (result != null && result > 0 && result != widget.himno.id) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/hymn-detail',
        arguments: result,
      );
    }
  }
}
