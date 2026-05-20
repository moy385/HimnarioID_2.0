import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/flag_utils.dart';
import '../../../core/window_manager/window_providers.dart';
import '../../../core/enums/fondo_pantalla_tipo.dart';
import '../../../domain/entities/fondo_pantalla.dart';
import '../../../domain/entities/himno.dart';
import '../../../domain/entities/pista_audio.dart';
import '../dual_mode_wrapper/dual_mode_providers.dart';
import '../views_personal/providers/audio_providers.dart';
import '../views_personal/providers/hymn_providers.dart';
import '../views_personal/providers/transpose_providers.dart';
import 'providers/appearance_provider.dart';
import 'providers/fondo_options_provider.dart';

// =============================================================================
// 1. Brush (Brocha) — Visual configuration sheet
// =============================================================================

/// Colores predefinidos para el texto de la letra.
const List<Color> _textColors = [
  Color(0xFF1C1B1F), // casi negro
  Color(0xFFFFFFFF), // blanco
  Color(0xFFB3261E), // rojo
  Color(0xFF1D6F42), // verde
  Color(0xFF1A6B8A), // azul
  Color(0xFF6750A4), // púrpura
];

/// Colores predefinidos para los acordes musicales.
const List<Color> _chordColors = [
  Color(0xFF6750A4), // púrpura (default)
  Color(0xFFB3261E), // rojo
  Color(0xFF1A6B8A), // azul
  Color(0xFF1D6F42), // verde
  Color(0xFFFF8F00), // naranja
  Color(0xFF1C1B1F), // negro
];

/// Convierte un string hexadecimal (con o sin `#`) a [Color].
/// Retorna `null` si el string no es válido.
Color? _parseHexColor(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  final normalized = hex.replaceFirst('#', '');
  if (normalized.length == 6) {
    return Color(int.parse('FF$normalized', radix: 16));
  }
  if (normalized.length == 8) {
    return Color(int.parse(normalized, radix: 16));
  }
  return null;
}

/// Widget reutilizable para un selector de color circular.
class _ColorCircle extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorCircle({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: isSelected
            ? Icon(Icons.check, size: 20, color: colorScheme.primary)
            : null,
      ),
    );
  }
}

/// Convierte [Color] a string hexadecimal con prefijo `#`.
String _colorToHex(Color color) {
  return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
}

/// Mapea [fontScale] al nombre del enum [ProjectionFontSize] legacy.
String _fontScaleToFontSizeName(double scale) {
  if (scale <= 0.8) return 'small';
  if (scale <= 1.2) return 'medium';
  if (scale <= 1.5) return 'large';
  return 'extraLarge';
}

/// Envía el estado actual de [hymnAppearanceProvider] a la ventana
/// de proyección vía [WindowService.sendMessage] (silencioso).
void _syncAppearanceToProjection(WidgetRef ref) {
  final appearance = ref.read(hymnAppearanceProvider);
  final isTransparent = appearance.bgColor.a == 0.0;
  final message = <String, dynamic>{
    'type': 'SET_CONFIG',
    // Nuevos campos de apariencia
    'textColor': _colorToHex(appearance.textColor),
    'chordColor': _colorToHex(appearance.chordColor),
    'fontFamily': appearance.fontFamily,
    'isBold': appearance.isBold,
    'fontScale': appearance.fontScale,
    'projectionFontScale': appearance.projectionFontScale,
    'bgColor': _colorToHex(appearance.bgColor),
    'showChords': appearance.showChords,
    'cardOpacity': appearance.cardOpacity,
    'bgFondoId': appearance.selectedFondo?.id,
    'bgTipo': appearance.selectedFondo?.tipo.value,
    'bgRuta': appearance.selectedFondo?.rutaArchivo,
    'colorHex': appearance.selectedFondo?.colorHex,
    // Campos legacy (retrocompatibilidad)
    'backgroundColor': _colorToHex(appearance.bgColor),
    'fontSize': _fontScaleToFontSizeName(appearance.fontScale),
    'transitionSpeed': 0.5,
    'background': isTransparent ? 'black' : 'color',
  };
  // Fire-and-forget silencioso
  ref.read(windowServiceProvider).sendMessage(message);
}

/// Muestra el sheet de configuración visual (fondo, tamaño fuente,
/// color de letra, color de acordes).
void showBrushSheet(
  BuildContext context, {
  required WidgetRef ref,
}) {
  final isDesktop = ref.read(isDesktopModeProvider);

  if (isDesktop) {
    // ── Desktop: Dialog sin drag handle ──
    showDialog<void>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final colorScheme = Theme.of(context).colorScheme;
            final textTheme = Theme.of(context).textTheme;
            final appearance = ref.watch(hymnAppearanceProvider);
            final fondosAsync = ref.watch(fondosActivosProvider);

            return Dialog(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 700, maxWidth: 500),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  children: _brushSheetChildren(
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    appearance: appearance,
                    fondosAsync: fondosAsync,
                    ref: ref,
                    setSheetState: setSheetState,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  } else {
    // ── Móvil: ModalBottomSheet + DraggableScrollableSheet ──
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final colorScheme = Theme.of(context).colorScheme;
            final textTheme = Theme.of(context).textTheme;
            final appearance = ref.watch(hymnAppearanceProvider);
            final fondosAsync = ref.watch(fondosActivosProvider);

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  child: ListView(
                    controller: scrollController,
                    children: <Widget>[
                      // ---- Handle (solo móvil) ----
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      ..._brushSheetChildren(
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                        appearance: appearance,
                        fondosAsync: fondosAsync,
                        ref: ref,
                        setSheetState: setSheetState,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Contenido compartido del sheet Brocha (sin handle, sin wrapper).
List<Widget> _brushSheetChildren({
  required ColorScheme colorScheme,
  required TextTheme textTheme,
  required HymnAppearanceState appearance,
  required AsyncValue<List<FondoPantalla>> fondosAsync,
  required WidgetRef ref,
  required void Function(void Function()) setSheetState,
}) {
  return [
    // ---- Title ----
    Row(
      children: <Widget>[
        Icon(
          Icons.brush,
          color: colorScheme.tertiary,
        ),
        const SizedBox(width: 8),
        Text(
          'Configuración visual',
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (ref.watch(isDesktopModeProvider)) ...[
          const SizedBox(width: 8),
          Chip(
            label: const Text('Personal + Proyección'),
            visualDensity: VisualDensity.compact,
            labelStyle: textTheme.labelSmall?.copyWith(
              color: colorScheme.tertiary,
            ),
            backgroundColor: colorScheme.tertiaryContainer,
            side: BorderSide.none,
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ],
    ),
    const SizedBox(height: 20),

    // ==========================================
    // 1. Fondos guardados (desde BD)
    // ==========================================
    Text(
      'Fondos guardados',
      style: textTheme.labelLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    ),
    const SizedBox(height: 8),
    fondosAsync.when(
      loading: () => const SizedBox(
        height: 60,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Error al cargar fondos',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.error,
          ),
        ),
      ),
      data: (fondos) {
        if (fondos.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No hay fondos guardados',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return Wrap(
          spacing: 16,
          runSpacing: 12,
          children: fondos.map((FondoPantalla fondo) {
            final isSelected = appearance.selectedFondo?.id == fondo.id;
            return _FondoItem(
              fondo: fondo,
              isSelected: isSelected,
              onTap: () {
                ref.read(hymnAppearanceProvider.notifier).setFondo(fondo);
                _syncAppearanceToProjection(ref);
                setSheetState(() {});
              },
            );
          }).toList(),
        );
      },
    ),
    const SizedBox(height: 20),

    // ==========================================
    // 2. Opacidad de tarjetas de estrofa
    // ==========================================
    Text(
      'Opacidad de tarjetas',
      style: textTheme.labelLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    ),
    const SizedBox(height: 4),
    Text(
      'Ajusta la transparencia de las tarjetas que contienen las estrofas',
      style: textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    ),
    const SizedBox(height: 4),
    Row(
      children: <Widget>[
        const Icon(Icons.opacity, size: 18),
        Expanded(
          child: Slider(
            value: appearance.cardOpacity,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            label: '${(appearance.cardOpacity * 100).round()}%',
            onChanged: (value) {
              ref
                  .read(hymnAppearanceProvider.notifier)
                  .setCardOpacity(value);
              _syncAppearanceToProjection(ref);
              setSheetState(() {});
            },
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '${(appearance.cardOpacity * 100).round()}%',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    ),
    const SizedBox(height: 8),

    const SizedBox(height: 20),

    // ==========================================
    // 3. Tamaño de letra
    // ==========================================
    Text(
      'Tamaño de letra',
      style: textTheme.labelLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    ),
    const SizedBox(height: 4),
    Row(
      children: <Widget>[
        const Icon(Icons.text_fields, size: 18),
        Expanded(
          child: Slider(
            value: appearance.fontScale,
            min: 0.7,
            max: 1.8,
            divisions: 11,
            label:
                '${(appearance.fontScale * 100).round()}%',
            onChanged: (value) {
              ref
                  .read(hymnAppearanceProvider.notifier)
                  .setFontScale(value);
              _syncAppearanceToProjection(ref);
              setSheetState(() {});
            },
          ),
        ),
        const Icon(Icons.text_fields, size: 26),
      ],
    ),
    const SizedBox(height: 20),

    // ==========================================
    // 3b. Tamaño de letra — Proyección (solo desktop)
    // ==========================================
    if (ref.watch(isDesktopModeProvider)) ...[
      const SizedBox(height: 16),
      Text(
        'Tamaño de letra — Proyección',
        style: textTheme.labelLarge?.copyWith(
          color: colorScheme.tertiary,
        ),
      ),
      const SizedBox(height: 4),
      Row(
        children: <Widget>[
          const Icon(Icons.tv, size: 18),
          Expanded(
            child: Slider(
              value: appearance.projectionFontScale,
              min: 0.5,
              max: 3.0,
              divisions: 10,
              label:
                  '${(appearance.projectionFontScale * 100).round()}%',
              onChanged: (value) {
                ref
                    .read(hymnAppearanceProvider.notifier)
                    .setProjectionFontScale(value);
                _syncAppearanceToProjection(ref);
                setSheetState(() {});
              },
            ),
          ),
          const Icon(Icons.tv, size: 26),
        ],
      ),
      Text(
        'Escala independiente para la ventana de proyección',
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    ],
    const SizedBox(height: 20),

    // ==========================================
    // 4. Color de letra
    // ==========================================
    Text(
      'Color de letra',
      style: textTheme.labelLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    ),
    const SizedBox(height: 8),
    Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _textColors.map((Color color) {
        final isSelected =
            appearance.textColor.toARGB32() == color.toARGB32();
        return _ColorCircle(
          color: color,
          isSelected: isSelected,
          onTap: () {
            ref
                .read(hymnAppearanceProvider.notifier)
                .setTextColor(color);
            _syncAppearanceToProjection(ref);
            setSheetState(() {});
          },
        );
      }).toList(),
    ),
    const SizedBox(height: 20),

    // ==========================================
    // 5. Color de acordes
    // ==========================================
    Text(
      'Color de acordes',
      style: textTheme.labelLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    ),
    const SizedBox(height: 8),
    Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _chordColors.map((Color color) {
        final isSelected =
            appearance.chordColor.toARGB32() == color.toARGB32();
        return _ColorCircle(
          color: color,
          isSelected: isSelected,
          onTap: () {
            ref
                .read(hymnAppearanceProvider.notifier)
                .setChordColor(color);
            _syncAppearanceToProjection(ref);
            setSheetState(() {});
          },
        );
      }).toList(),
    ),
    const SizedBox(height: 24),

    // ==========================================
    // 6. Tipo de letra
    // ==========================================
    Text(
      'Tipo de letra',
      style: textTheme.labelLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    ),
    const SizedBox(height: 4),
    Text(
      'Elige la tipografía para el texto de los himnos',
      style: textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    ),
    const SizedBox(height: 12),

    const SizedBox(height: 12),
    Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _FontOption(
          family: 'Merriweather',
          label: 'Merriweather',
          previewText: 'Texto',
          isSelected: appearance.fontFamily == 'Merriweather',
          onTap: () {
            ref.read(hymnAppearanceProvider.notifier).setFontFamily('Merriweather');
            _syncAppearanceToProjection(ref);
            setSheetState(() {});
          },
        ),
        _FontOption(
          family: 'Lora',
          label: 'Lora',
          previewText: 'Texto',
          isSelected: appearance.fontFamily == 'Lora',
          onTap: () {
            ref.read(hymnAppearanceProvider.notifier).setFontFamily('Lora');
            _syncAppearanceToProjection(ref);
            setSheetState(() {});
          },
        ),
        _FontOption(
          family: 'Playfair Display',
          label: 'Playfair Display',
          previewText: 'Texto',
          isSelected: appearance.fontFamily == 'Playfair Display',
          onTap: () {
            ref.read(hymnAppearanceProvider.notifier).setFontFamily('Playfair Display');
            _syncAppearanceToProjection(ref);
            setSheetState(() {});
          },
        ),
        _FontOption(
          family: 'Cinzel',
          label: 'Cinzel',
          previewText: 'Texto',
          isSelected: appearance.fontFamily == 'Cinzel',
          onTap: () {
            ref.read(hymnAppearanceProvider.notifier).setFontFamily('Cinzel');
            _syncAppearanceToProjection(ref);
            setSheetState(() {});
          },
        ),
      ],
    ),
    const SizedBox(height: 16),

    // ── Negritas ──
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        'Negritas',
        style: textTheme.bodyLarge,
      ),
      subtitle: Text(
        'Aplicar negritas al texto del himno',
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      value: appearance.isBold,
      onChanged: (bool value) {
        ref.read(hymnAppearanceProvider.notifier).setIsBold(value);
        _syncAppearanceToProjection(ref);
        setSheetState(() {});
      },
    ),
    const SizedBox(height: 24),

    // ==========================================
    // 7. Restablecer
    // ==========================================
    Center(
      child: TextButton.icon(
        onPressed: () {
          ref
              .read(hymnAppearanceProvider.notifier)
              .reset();
          _syncAppearanceToProjection(ref);
          setSheetState(() {});
        },
        icon: const Icon(Icons.restart_alt),
        label: const Text('Restablecer valores'),
      ),
    ),
  ];
}


// =============================================================================
// 2. Note (Nota) — Audio tracks sheet
// =============================================================================

/// Muestra el sheet de pistas de audio para un himno.
void showNoteSheet(
  BuildContext context, {
  required WidgetRef ref,
  required int himnoId,
  int? currentPistaId,
  required ValueChanged<int> onPlayPista,
  required VoidCallback onStop,
}) {
  final isDesktop = ref.read(isDesktopModeProvider);

  if (isDesktop) {
    // ── Desktop: Dialog sin drag handle ──
    showDialog<void>(
      context: context,
      builder: (_) {
        final colorScheme = Theme.of(_).colorScheme;
        final textTheme = Theme.of(_).textTheme;
        final isPlaying = ref.watch(isAudioPlayingProvider);

        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: _noteSheetContent(
                colorScheme: colorScheme,
                textTheme: textTheme,
                ref: ref,
                himnoId: himnoId,
                currentPistaId: currentPistaId,
                isPlaying: isPlaying,
                onPlayPista: onPlayPista,
                onStop: onStop,
              ),
            ),
          ),
        );
      },
    );
  } else {
    // ── Móvil: ModalBottomSheet ──
    showModalBottomSheet<void>(
      context: context,
      builder: (_) {
        final colorScheme = Theme.of(_).colorScheme;
        final textTheme = Theme.of(_).textTheme;
        final isPlaying = ref.watch(isAudioPlayingProvider);

        return Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Handle (solo móvil)
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              _noteSheetContent(
                colorScheme: colorScheme,
                textTheme: textTheme,
                ref: ref,
                himnoId: himnoId,
                currentPistaId: currentPistaId,
                isPlaying: isPlaying,
                onPlayPista: onPlayPista,
                onStop: onStop,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Contenido compartido del sheet Nota (título + pistas).
Widget _noteSheetContent({
  required ColorScheme colorScheme,
  required TextTheme textTheme,
  required WidgetRef ref,
  required int himnoId,
  int? currentPistaId,
  required bool isPlaying,
  required ValueChanged<int> onPlayPista,
  required VoidCallback onStop,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Row(
        children: <Widget>[
          Icon(
            Icons.audiotrack,
            color: colorScheme.secondary,
          ),
          const SizedBox(width: 8),
          Text(
            'Pistas de audio',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      FutureBuilder<List<PistaAudio>>(
        future: ref.read(audioRepositoryProvider).getByHimno(himnoId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.error_outline,
                    color: colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Error al cargar pistas',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ],
              ),
            );
          }

          final pistas = snapshot.data ?? <PistaAudio>[];

          if (pistas.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: <Widget>[
                    Icon(
                      Icons.audio_file,
                      size: 48,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No hay pistas de audio disponibles para este himno',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: pistas.map((PistaAudio pista) {
              final fileName = pista.rutaArchivo.split('/').last;
              final isThisPistaPlaying = isPlaying && currentPistaId == pista.id;
              return ListTile(
                leading: IconButton(
                  icon: Icon(
                    isThisPistaPlaying
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded,
                    color: isThisPistaPlaying
                        ? colorScheme.error
                        : colorScheme.secondary,
                  ),
                  onPressed: () {
                    if (isThisPistaPlaying) {
                      onStop();
                    } else {
                      onPlayPista(pista.id);
                    }
                  },
                ),
                title: Text(
                  pista.descripcion ?? fileName,
                  style: textTheme.bodyLarge,
                ),
                subtitle: pista.duracionSegundos != null
                    ? Text(
                        _formatDuration(pista.duracionSegundos!),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )
                    : null,
                trailing: const Icon(Icons.music_note),
              );
            }).toList(),
          );
        },
      ),
    ],
  );
}

String _formatDuration(double seconds) {
  final totalSec = seconds.round();
  final min = totalSec ~/ 60;
  final sec = totalSec % 60;
  return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
}

// =============================================================================
// 3. Solfa — Musician panel sheet (transposition, chords toggle)
// =============================================================================

/// Muestra el sheet del panel de músico (transposición y toggle de acordes).
void showSolfaSheet(
  BuildContext context, {
  required WidgetRef ref,
  VoidCallback? onCreateArrangement,
}) {
  final isDesktop = ref.read(isDesktopModeProvider);

  if (isDesktop) {
    // ── Desktop: Dialog sin drag handle ──
    showDialog<void>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final colorScheme = Theme.of(context).colorScheme;
            final textTheme = Theme.of(context).textTheme;
            final currentTranspose = ref.watch(transposeValueProvider);
            final currentKey = ref.watch(transposedKeyProvider);
            final showChords = ref.watch(hymnAppearanceProvider).showChords;

            return Dialog(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  child: _solfaSheetContent(
                    context: context,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    currentTranspose: currentTranspose,
                    currentKey: currentKey,
                    showChords: showChords,
                    onCreateArrangement: onCreateArrangement,
                    ref: ref,
                    setSheetState: setSheetState,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  } else {
    // ── Móvil: ModalBottomSheet ──
    showModalBottomSheet<void>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final colorScheme = Theme.of(context).colorScheme;
            final textTheme = Theme.of(context).textTheme;
            final currentTranspose = ref.watch(transposeValueProvider);
            final currentKey = ref.watch(transposedKeyProvider);
            final showChords = ref.watch(hymnAppearanceProvider).showChords;

            return Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Handle (solo móvil)
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  _solfaSheetContent(
                    context: context,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    currentTranspose: currentTranspose,
                    currentKey: currentKey,
                    showChords: showChords,
                    onCreateArrangement: onCreateArrangement,
                    ref: ref,
                    setSheetState: setSheetState,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Contenido compartido del sheet Solfa (título, acordes toggle, transposición).
Widget _solfaSheetContent({
  required BuildContext context,
  required ColorScheme colorScheme,
  required TextTheme textTheme,
  required int currentTranspose,
  required String currentKey,
  required bool showChords,
  VoidCallback? onCreateArrangement,
  required WidgetRef ref,
  required void Function(void Function()) setSheetState,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Row(
        children: <Widget>[
          Icon(
            Icons.music_note,
            color: colorScheme.tertiary,
          ),
          const SizedBox(width: 8),
          Text(
            'Panel de músico',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      // Toggle de acordes
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          'Mostrar acordes',
          style: textTheme.bodyLarge,
        ),
        subtitle: Text(
          'Muestra u oculta los acordes en la letra',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        value: showChords,
        onChanged: (bool value) {
          setSheetState(() {
            ref.read(hymnAppearanceProvider.notifier).setShowChords(value);
            _syncAppearanceToProjection(ref);
          });
        },
      ),
      const Divider(),
      // Transposición
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          'Transposición',
          style: textTheme.bodyLarge,
        ),
        subtitle: Text(
          'Tono actual: $currentKey',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              onPressed: () {
                ref.read(transposeValueProvider.notifier).state =
                    (currentTranspose - 1).clamp(-6, 6);
              },
              icon: const Icon(Icons.remove_circle_outline),
              tooltip: 'Bajar tono',
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '$currentTranspose',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                ref.read(transposeValueProvider.notifier).state =
                    (currentTranspose + 1).clamp(-6, 6);
              },
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Subir tono',
            ),
          ],
        ),
      ),
      if (onCreateArrangement != null)
        const Divider(),
      if (onCreateArrangement != null)
        ListTile(
          leading: Icon(Icons.edit_note, color: colorScheme.tertiary),
          title: const Text('Crear Arreglo Personalizado'),
          subtitle: const Text('Fork del himno con tus propios acordes'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.pop(context);
            onCreateArrangement();
          },
        ),
    ],
  );
}

// =============================================================================
// 4. Search (Lupa) — Hymn search sheet
// =============================================================================

/// Muestra el diálogo de búsqueda de himnos.
///
/// Retorna el ID del himno seleccionado, o `null` si se cancela la búsqueda.
Future<int?> showSearchSheet(
  BuildContext context, {
  required WidgetRef ref,
  required int currentHimnoId,
}) {
  return showSearch<int>(
    context: context,
    delegate: HymnSearchDelegate(
      ref: ref,
      currentHimnoId: currentHimnoId,
    ),
  );
}

// =============================================================================
// Search delegate used by showSearchSheet
// =============================================================================

/// Delegado de búsqueda para navegar entre himnos.
class HymnSearchDelegate extends SearchDelegate<int> {
  final WidgetRef ref;
  final int currentHimnoId;

  HymnSearchDelegate({
    required this.ref,
    required this.currentHimnoId,
  });

  @override
  String get searchFieldLabel => 'Buscar himno por título o número';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return <Widget>[
      if (query.isNotEmpty)
        IconButton(
          onPressed: () => query = '',
          icon: const Icon(Icons.clear),
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, -1),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchList(context);

  Widget _buildSearchList(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.search,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Escribe para buscar himnos',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<List<Himno>>(
      future: ref.read(hymnRepositoryProvider).searchHymns(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final himnos = snapshot.data ?? <Himno>[];

        if (himnos.isEmpty) {
          return Center(
            child: Text(
              'No se encontraron himnos para "$query"',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: himnos.length,
          itemBuilder: (context, int index) {
            final himno = himnos[index];
            final isCurrent = himno.id == currentHimnoId;

            final paisCodigo = himno.paisCodigo;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isCurrent
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                child: Text(
                  '${himno.numero ?? '?'}',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isCurrent
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      himno.titulo,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (paisCodigo != null && paisCodigo.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FlagUtils.codeToFlag(paisCodigo).isNotEmpty
                          ? Text(
                              FlagUtils.codeToFlag(paisCodigo),
                              style: const TextStyle(fontSize: 24),
                            )
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
              subtitle: (himno.categorias?.isNotEmpty ?? false)
                  ? Text(
                      himno.categorias!.take(4).map((c) => c.nombre).join(', '),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              trailing: isCurrent
                  ? Icon(
                      Icons.check_circle,
                      color: colorScheme.primary,
                      size: 20,
                    )
                  : null,
              onTap: () => close(context, himno.id),
            );
          },
        );
      },
        );
  }
}

// =============================================================================
// 5. _FondoItem — Preview de fondo según su tipo (color, imagen, video)
// =============================================================================

/// Widget que muestra preview de un fondo según su tipo.
class _FondoItem extends StatelessWidget {
  final FondoPantalla fondo;
  final bool isSelected;
  final VoidCallback onTap;

  const _FondoItem({
    required this.fondo,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          switch (fondo.tipo) {
            FondoPantallaTipo.colorSolido => _buildColorPreview(colorScheme),
            FondoPantallaTipo.imagen => _buildImagePreview(colorScheme),
            FondoPantallaTipo.video => _buildVideoPreview(colorScheme),
          },
          const SizedBox(height: 4),
          SizedBox(
            width: 60,
            child: Text(
              fondo.nombre,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPreview(ColorScheme colorScheme) {
    final color = _parseHexColor(fondo.colorHex) ?? colorScheme.surfaceContainerHighest;
    return _previewContainer(
      colorScheme: colorScheme,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: isSelected
            ? Icon(Icons.check, size: 20, color: colorScheme.primary)
            : null,
      ),
    );
  }

  Widget _buildImagePreview(ColorScheme colorScheme) {
    return _previewContainer(
      colorScheme: colorScheme,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          image: fondo.rutaArchivo != null
              ? DecorationImage(
                  image: FileImage(File(fondo.rutaArchivo!)),
                  fit: BoxFit.cover,
                  onError: (_, __) {},
                )
              : null,
        ),
        child: Center(
          child: Icon(
            Icons.image,
            size: 24,
            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPreview(ColorScheme colorScheme) {
    return _previewContainer(
      colorScheme: colorScheme,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(
            Icons.videocam,
            size: 24,
            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _previewContainer({
    required ColorScheme colorScheme,
    required Widget child,
  }) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          width: isSelected ? 2.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: child,
      ),
    );
  }
}

// =============================================================================
// 6. _FontOption — Selector visual de fuente tipográfica
// =============================================================================

/// Widget reutilizable para seleccionar una fuente tipográfica.
/// Muestra una tarjeta con el nombre de la fuente y un preview.
class _FontOption extends StatelessWidget {
  final String family;
  final String label;
  final String previewText;
  final bool isSelected;
  final VoidCallback onTap;

  const _FontOption({
    required this.family,
    required this.label,
    required this.previewText,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 150,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: family,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, size: 18, color: colorScheme.primary),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              previewText,
              style: TextStyle(
                fontFamily: family,
                fontSize: 22,
                fontWeight: FontWeight.w400,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

