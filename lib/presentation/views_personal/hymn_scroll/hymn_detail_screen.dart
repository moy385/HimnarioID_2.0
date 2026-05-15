import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/utils/chord_transposer.dart';
import '../../../core/utils/stanza_layout_engine.dart';
import '../../../domain/entities/estrofa.dart';
import '../../../domain/entities/himno.dart';
import '../../../domain/repositories/audio_repository.dart';
import '../../shared_widgets/control_sheets.dart';
import '../../shared_widgets/providers/appearance_provider.dart';
import '../providers/audio_providers.dart';
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
  bool _showChords = true;
  int? _currentPistaId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeKeyFromHymn();
    });
  }

  void _initializeKeyFromHymn() {
    if (!mounted) return;
    final tonalidad = widget.himno.versiones
        .firstOrNull
        ?.tonalidadOriginal ?? 'C';
    ref.read(transposeValueProvider.notifier).state = 0;
    ref.read(currentKeyProvider.notifier).state = tonalidad;
  }

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
    final appearance = ref.watch(hymnAppearanceProvider);
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
              color: appearance.bgColor,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Cabecera del himno
                    _buildHeader(context, widget.himno, colorScheme, textTheme, appearance),
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
                        int estrofaCounter = 0;
                        return Column(
                          children: estrofas.map((estrofa) {
                            if (!estrofa.isChorus) estrofaCounter++;
                            return _buildStanza(
                              context,
                              estrofa,
                              transposeValue,
                              colorScheme,
                              textTheme,
                              appearance,
                              stanzaNumber: estrofa.isChorus ? null : estrofaCounter,
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
    HymnAppearanceState appearance,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Título centrado
        Text(
          himno.titulo,
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            fontFamily: appearance.fontFamily,
            color: appearance.textColor,
            fontWeight: appearance.isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 8),
        // Etiquetas
        Wrap(
          spacing: 8,
          runAlignment: WrapAlignment.center,
          alignment: WrapAlignment.center,
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
    HymnAppearanceState appearance, {
    int? stanzaNumber,
  }) {
    final isChorus = estrofa.isChorus;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isChorus
            ? appearance.bgColor.withValues(alpha: 0.3)
            : appearance.bgColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: isChorus
            ? Border.all(
                color: appearance.chordColor.withValues(alpha: 0.3),
                width: 1,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Etiqueta de tipo de estrofa (gris con texto blanco)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              estrofa.isChorus
                  ? 'CORO'
                  : 'ESTROFA ${stanzaNumber ?? estrofa.orden}',
              style: textTheme.labelSmall?.copyWith(
                color: Colors.white,
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
            appearance,
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
    HymnAppearanceState appearance,
  ) {
    final chordRegex =
        RegExp(r'\[([A-G][#b]?m?\d*(?:sus|dim|aug|Maj|maj)?[0-9]*)\]');

    // Transponer usando el utility ChordTransposer
    final transposedLyric = transposeChordPro(lyric, transposeValue);

    // Medir y refluir líneas largas
    final double availableWidth =
        MediaQuery.of(context).size.width - 32; // 16px padding each side
    final double baseFontSize =
        (textTheme.bodyLarge?.fontSize ?? 16) * appearance.fontScale;

    final processedLyric = StanzaLayoutEngine.processStanza(
      transposedLyric,
      maxWidth: availableWidth,
      style: textTheme.bodyLarge?.copyWith(
        fontFamily: appearance.fontFamily,
        fontSize: baseFontSize,
        fontWeight: appearance.isBold ? FontWeight.bold : FontWeight.normal,
      ),
    );

    final parts = processedLyric.split('\n');

    // Escala base para texto y acordes (ambos escalan proporcionalmente con fontScale)
    final double chordFontSize = baseFontSize - 3;

    // Estilo de línea base para medición y renderizado
    final TextStyle? lyricStyle = textTheme.bodyLarge?.copyWith(
      fontFamily: appearance.fontFamily,
      color: appearance.textColor,
      fontSize: baseFontSize,
      height: 1.6,
      fontWeight: appearance.isBold ? FontWeight.bold : FontWeight.normal,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: parts.map((line) {
        if (!_showChords) {
          // ── Sin acordes: solo texto plano, limpio, sin espacios vacíos ──
          final plainLine = line.replaceAll(chordRegex, '');
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              plainLine,
              textAlign: TextAlign.justify,
              style: lyricStyle,
            ),
          );
        }

        final matches = chordRegex.allMatches(line).toList();

        if (matches.isEmpty) {
          // ── Línea sin acordes ──
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              line,
              textAlign: TextAlign.justify,
              style: lyricStyle,
            ),
          );
        }

        // ── Línea CON acordes → Stack: acordes arriba, texto abajo ──
        return _buildChordLineStacked(
          line: line,
          matches: matches,
          chordRegex: chordRegex,
          lyricStyle: lyricStyle,
          chordFontSize: chordFontSize,
          chordColor: appearance.chordColor,
          fontFamily: appearance.fontFamily,
        );
      }).toList(),
    );
  }

  /// Renderiza una línea con acordes usando [Stack] + [Positioned]:
  /// los acordes aparecen SOBRE el texto, en la posición horizontal exacta
  /// donde corresponde cada sílaba. Usa [TextPainter] para medir el texto
  /// previo a cada acorde y así calcular su posición horizontal.
  ///
  /// Garantiza un espaciado mínimo entre acordes consecutivos para evitar
  /// solapamiento visual (ej: `[G]A[Am]le`).
  Widget _buildChordLineStacked({
    required String line,
    required List<RegExpMatch> matches,
    required RegExp chordRegex,
    required TextStyle? lyricStyle,
    required double chordFontSize,
    required Color chordColor,
    required String fontFamily,
  }) {
    // Texto plano (sin marcadores [Acorde])
    final String plainText = line.replaceAll(chordRegex, '');

    // Espacio vertical reservado arriba para los acordes
    // (altura del acorde + gap de 6px antes del texto)
    final double chordAreaHeight = chordFontSize + 6;

    // Construir los Positioned hijos para cada acorde
    final List<Widget> chordWidgets = [];
    double lastChordRight = double.negativeInfinity;
    const double minChordGap = 6.0; // px mínimos entre acordes

    for (final match in matches) {
      // Texto antes de este acorde en la línea original, sin marcadores
      final String textBefore = line.substring(0, match.start);
      final String textBeforePlain = textBefore.replaceAll(chordRegex, '');

      // Medir el ancho del texto previo para saber dónde colocar el acorde
      final TextPainter tp = TextPainter(
        text: TextSpan(text: textBeforePlain, style: lyricStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      final String chord = match.group(1) ?? '';
      double left = tp.width;

      // Medir el ancho del acorde para control de solapamiento
      final TextPainter chordTp = TextPainter(
        text: TextSpan(
          text: chord,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: chordFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Si este acorde caería muy cerca del anterior → desplazar a la derecha
      if (left < lastChordRight + minChordGap) {
        left = lastChordRight + minChordGap;
      }

      lastChordRight = left + chordTp.width;

      chordWidgets.add(
        Positioned(
          top: 0,
          left: left,
          child: Text(
            chord,
            style: TextStyle(
              fontFamily: fontFamily,
              color: chordColor,
              fontWeight: FontWeight.bold,
              fontSize: chordFontSize,
              height: 1.0,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Child NO positionado → define el tamaño del Stack
          Padding(
            padding: EdgeInsets.only(top: chordAreaHeight),
            child: Text(
              plainText,
              textAlign: TextAlign.justify,
              style: lyricStyle,
              softWrap: true,
            ),
          ),
          // Acordes positionados arriba
          ...chordWidgets,
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    int transposeValue,
    String transposedKey,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: MediaQuery.of(context).viewInsets.bottom + 8),
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
        child: _isPlaying ? _buildPlayerBar(context, colorScheme, textTheme) : _buildTransposeBar(context, transposeValue, transposedKey, colorScheme, textTheme),
      ),
    );
  }

  Widget _buildTransposeBar(BuildContext context, int transposeValue, String transposedKey, ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => ref.read(transposeValueProvider.notifier).state = (transposeValue - 1).clamp(-6, 6),
                icon: const Icon(Icons.remove),
                tooltip: 'Bajar tono',
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Tono', style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                    Text(transposedKey, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => ref.read(transposeValueProvider.notifier).state = (transposeValue + 1).clamp(-6, 6),
                icon: const Icon(Icons.add),
                tooltip: 'Subir tono',
              ),
            ],
          ),
        ),
        const Spacer(),
        IconButton.filled(
          onPressed: _togglePlayback,
          icon: const Icon(Icons.play_arrow_rounded),
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.secondaryContainer,
            foregroundColor: colorScheme.onSecondaryContainer,
          ),
          tooltip: 'Reproducir audio',
        ),
      ],
    );
  }

  Widget _buildPlayerBar(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    return _AudioPlayerBar(
      key: const ValueKey('player_bar'),
      repo: ref.read(audioRepositoryProvider),
      onStop: _togglePlayback,
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

  Future<void> _playAudio([int? pistaId]) async {
    final audioRepo = ref.read(audioRepositoryProvider);
    final himnoId = widget.himno.id;

    // Si no se especificó pista, buscar la primera disponible
    int targetPistaId = pistaId ?? _currentPistaId ?? himnoId;
    if (pistaId == null && _currentPistaId == null) {
      try {
        final pistas = await audioRepo.getByHimno(himnoId);
        if (pistas.isNotEmpty) {
          targetPistaId = pistas.first.id;
        }
      } catch (_) {}
    }

    _currentPistaId = targetPistaId;
    // Activar estado ANTES de reproducir para feedback instantáneo
    if (mounted) setState(() => _isPlaying = true);
    ref.read(isAudioPlayingProvider.notifier).state = true;

    audioRepo.play(targetPistaId).then((_) {
      HymnDetailScreen._log.info(
        'Reproduciendo pista $targetPistaId para himno $himnoId',
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
      ref: ref,
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
      currentPistaId: _currentPistaId,
      onPlayPista: (pistaId) {
        _currentPistaId = pistaId;
        _playAudio(pistaId);
      },
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
      // Buscar el objeto Himno completo desde el repositorio
      try {
        final himno = await ref.read(hymnRepositoryProvider).getHymnById(result);
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/hymn-detail',
            arguments: himno,
          );
        }
      } catch (e) {
        HymnDetailScreen._log.warning('Error al cargar himno desde lupa: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al abrir el himno')),
          );
        }
      }
    }
  }
}

/// Barra de reproducción reactiva: progreso, tiempo y controles.
class _AudioPlayerBar extends StatefulWidget {
  final AudioRepository repo;
  final VoidCallback onStop;

  const _AudioPlayerBar({super.key, required this.repo, required this.onStop});

  @override
  State<_AudioPlayerBar> createState() => _AudioPlayerBarState();
}

class _AudioPlayerBarState extends State<_AudioPlayerBar> {
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isSliding = false;

  @override
  void initState() {
    super.initState();
    widget.repo.onDurationChanged.listen((d) {
      if (d != null && mounted) setState(() => _duration = d);
    });
    widget.repo.onPositionChanged.listen((p) {
      if (!_isSliding && mounted) setState(() => _position = p);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final durationSec = _duration.inSeconds.toDouble();
    final positionSec = _position.inSeconds.toDouble();
    final progress = durationSec > 0 ? positionSec / durationSec : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(_fmt(positionSec),
                style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant, fontSize: 11)),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 5),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 10),
                ),
                child: Slider(
                  value: progress.clamp(0.0, 1.0),
                  onChanged: (v) {
                    setState(() {
                      _isSliding = true;
                    });
                  },
                  onChangeEnd: (v) {
                    widget.repo.seek(
                        Duration(milliseconds: (v * durationSec * 1000).round()));
                    setState(() => _isSliding = false);
                  },
                ),
              ),
            ),
            Text(_fmt(durationSec),
                style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.stop_rounded, size: 28),
              color: colorScheme.error,
              onPressed: widget.onStop,
              tooltip: 'Detener',
            ),
          ],
        ),
      ],
    );
  }

  String _fmt(double sec) {
    final t = sec.round();
    return '${(t ~/ 60).toString().padLeft(2, '0')}:${(t % 60).toString().padLeft(2, '0')}';
  }
}