import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../../../core/chords/chord_parser.dart';
import '../../../core/enums/fondo_pantalla_tipo.dart';
import '../../../core/utils/chord_transposer.dart';
import '../../../core/utils/stanza_layout_engine.dart';
import '../../../domain/entities/fondo_pantalla.dart';
import '../../../domain/entities/estrofa.dart';
import '../../../domain/entities/himno.dart';
import '../../../domain/repositories/audio_repository.dart';
import '../../shared_widgets/chord_overlay_text.dart';
import '../../../core/window_manager/window_providers.dart';
import '../../dual_mode_wrapper/dual_mode_providers.dart';
import '../../shared_widgets/control_sheets.dart';
import '../../shared_widgets/providers/appearance_provider.dart';
import '../../views_projection/providers/presentation_providers.dart';
import '../../views_projection/providers/projection_actions.dart'
    show projectHymn;
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
  int? _currentPistaId;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeKeyFromHymn();
    });
  }

  void _initializeKeyFromHymn() {
    if (!mounted) return;
    // 1. Usar tonalidad de la BD si está disponible y no es 'C' (default)
    var tonalidad = widget.himno.versiones
        .firstOrNull
        ?.tonalidadOriginal ?? '';
    if (tonalidad.isEmpty || tonalidad == 'C') {
      // 2. Si no hay tonalidad explícita, detectar del primer acorde del himno
      final primeraEstrofa = widget.himno.versiones
          .firstOrNull?.estrofas.firstOrNull?.contenido ?? '';
      if (primeraEstrofa.isNotEmpty) {
        final chordRegex = RegExp(r'\[([A-G][#b]?m?)\]');
        final match = chordRegex.firstMatch(primeraEstrofa);
        if (match != null) {
          tonalidad = match.group(1) ?? 'C';
        }
      }
      if (tonalidad.isEmpty) tonalidad = 'C';
    }
    ref.read(transposeValueProvider.notifier).state = 0;
    ref.read(currentKeyProvider.notifier).state = tonalidad;
  }

  /// Presenta el himno actual en la ventana de proyección.
  /// Abre la ventana, carga himno+estrofas, y envía mensaje LOAD_HYMN.
  Future<void> _presentCurrentHymn() async {
    final windowService = ref.read(windowServiceProvider);
    final isPresenting = ref.read(isPresentingProvider);
    try {
      if (!isPresenting) {
        await windowService.openProjectionWindow({
          'mode': 'local',
          'source': 'hymn-detail',
        });
        ref.read(isPresentingProvider.notifier).state = true;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al presentar: $e')),
        );
      }
      return;
    }

    final error = await projectHymn(ref, widget.himno);
    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al presentar: $error')),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Presentando: ${widget.himno.titulo}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
    final isDesktop = ref.watch(isDesktopModeProvider);
    final isPresenting = ref.watch(isPresentingProvider);

    // ── Contenido scrollable (extraído para reusar entre desktop y móvil) ──
    final scrollContent = Column(
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
    );

    // ── SingleChildScrollView base (con controller en desktop) ──
    final scrollView = SingleChildScrollView(
      controller: isDesktop ? _scrollController : null,
      padding: const EdgeInsets.all(16),
      child: scrollContent,
    );

    // ── En desktop: centrar con ancho máximo de 800px + scrollbar visible ──
    Widget bodyContent;
    if (isDesktop) {
      bodyContent = Center(
        child: SizedBox(
          width: 800,
          child: scrollView,
        ),
      );
    } else {
      bodyContent = scrollView;
    }

    if (isDesktop) {
      bodyContent = Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: bodyContent,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Himno ${widget.himno.numero ?? ''}'),
        actions: [
          // ── Botón Presentar (solo desktop) ──
          if (isDesktop)
            IconButton(
              icon: Icon(isPresenting ? Icons.stop_screen_share : Icons.screen_share),
              tooltip: isPresenting ? 'Detener presentación' : 'Presentar',
              onPressed: _presentCurrentHymn,
            ),
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
            child: _FondoBackground(
              fondo: appearance.selectedFondo,
              bgColor: appearance.bgColor,
              child: bodyContent,
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
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.9)
            : colorScheme.surfaceContainerLow.withValues(alpha: 0.7),
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
    // Transponer usando el utility ChordTransposer
    final transposedLyric = transposeChordPro(lyric, transposeValue);

    final double baseFontSize =
        (textTheme.bodyLarge?.fontSize ?? 16) * appearance.fontScale;

    // Escala base para texto y acordes
    final double chordFontSize = (baseFontSize * 0.6).clamp(8.0, 13.0);

    // Estilo base de la letra
    final TextStyle lyricStyle = (textTheme.bodyLarge ?? const TextStyle()).copyWith(
      fontFamily: appearance.fontFamily,
      color: appearance.textColor,
      fontSize: baseFontSize,
      height: 1.6,
      fontWeight: appearance.isBold ? FontWeight.bold : FontWeight.normal,
    );

    // Estilo de los acordes
    final TextStyle chordStyle = TextStyle(
      fontFamily: appearance.fontFamily,
      color: appearance.chordColor,
      fontWeight: FontWeight.bold,
      fontSize: chordFontSize,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;

        final processedLyric = StanzaLayoutEngine.processStanza(
          transposedLyric,
          maxWidth: availableWidth,
          style: lyricStyle,
        );

        final parts = processedLyric.split('\n');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: parts.map((line) {
            if (!appearance.showChords) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  stripChords(line),
                  textAlign: TextAlign.justify,
                  style: lyricStyle,
                ),
              );
            }

            return ChordOverlayText(
              chordProLine: line,
              textStyle: lyricStyle,
              chordStyle: chordStyle,
              maxWidth: availableWidth,
            );
          }).toList(),
        );
      },
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
        Flexible(
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => ref.read(transposeValueProvider.notifier).state = (transposeValue - 1).clamp(-6, 6),
                  icon: const Icon(Icons.remove),
                  tooltip: 'Bajar tono',
                ),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Tono', style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                        Text(transposedKey, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                      ],
                    ),
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
        ),
        const SizedBox(width: 8),
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
    _scrollController.dispose();
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
        SnackBar(
          content: Text(
            '$error'.contains('Archivo no encontrado')
                ? 'Archivo no encontrado. Agregue la pista desde Admin > Catálogos > Pistas.'
                : 'No se pudo reproducir el audio',
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Cerrar',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
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

/// Renderiza el fondo según el tipo seleccionado (color, imagen o video).
class _FondoBackground extends StatelessWidget {
  final FondoPantalla? fondo;
  final Color bgColor;
  final Widget child;

  const _FondoBackground({
    required this.fondo,
    required this.bgColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (fondo == null) {
      return Container(color: bgColor, child: child);
    }
    return switch (fondo!.tipo) {
      FondoPantallaTipo.colorSolido => Container(color: bgColor, child: child),
      FondoPantallaTipo.imagen => Stack(
          children: [
            if (fondo!.rutaArchivo != null)
              Positioned.fill(
                child: Image.file(
                  File(fondo!.rutaArchivo!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: bgColor),
                ),
              ),
            child,
          ],
        ),
      FondoPantallaTipo.video => Stack(
          children: [
            Container(color: Colors.black87),
            Container(color: Colors.black26),
            child,
          ],
        ),
    };
  }
}