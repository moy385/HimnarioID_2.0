import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/fondo_pantalla.dart';
import '../../../domain/entities/himno.dart';
import '../../../domain/entities/pista_audio.dart';
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
  final bool isTransparent;
  final String? label;
  final VoidCallback onTap;

  const _ColorCircle({
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.isTransparent = false,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final circle = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isTransparent ? colorScheme.surfaceContainerHighest : color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: isTransparent
            ? Icon(
                Icons.block,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              )
            : (isSelected
                ? Icon(
                    Icons.check,
                    size: 20,
                    color: colorScheme.primary,
                  )
                : null),
      ),
    );

    if (label != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          circle,
          const SizedBox(height: 4),
          Text(
            label!,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    return circle;
  }
}

/// Muestra el sheet de configuración visual (fondo, tamaño fuente,
/// color de letra, color de acordes).
void showBrushSheet(
  BuildContext context, {
  required WidgetRef ref,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final colorScheme = Theme.of(context).colorScheme;
          final textTheme = Theme.of(context).textTheme;
          final appearance = ref.watch(hymnAppearanceProvider);
          final fondosAsync = ref.watch(fondosColorSolidoProvider);

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
                    // ---- Handle ----
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
                            final color = _parseHexColor(fondo.colorHex) ??
                                colorScheme.surfaceContainerHighest;
                            final isSelected =
                                appearance.bgColor.toARGB32() == color.toARGB32();
                            return _ColorCircle(
                              color: color,
                              isSelected: isSelected,
                              isTransparent: false,
                              label: fondo.nombre,
                              onTap: () {
                                ref
                                    .read(hymnAppearanceProvider.notifier)
                                    .setBgColor(color);
                                setSheetState(() {});
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // ==========================================
                    // 2. Tamaño de letra
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
                              setSheetState(() {});
                            },
                          ),
                        ),
                        const Icon(Icons.text_fields, size: 26),
                      ],
                    ),
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
                          onTap: () => ref.read(hymnAppearanceProvider.notifier).setFontFamily('Merriweather'),
                        ),
                        _FontOption(
                          family: 'Lora',
                          label: 'Lora',
                          previewText: 'Texto',
                          isSelected: appearance.fontFamily == 'Lora',
                          onTap: () => ref.read(hymnAppearanceProvider.notifier).setFontFamily('Lora'),
                        ),
                        _FontOption(
                          family: 'Playfair Display',
                          label: 'Playfair Display',
                          previewText: 'Texto',
                          isSelected: appearance.fontFamily == 'Playfair Display',
                          onTap: () => ref.read(hymnAppearanceProvider.notifier).setFontFamily('Playfair Display'),
                        ),
                        _FontOption(
                          family: 'Cinzel',
                          label: 'Cinzel',
                          previewText: 'Texto',
                          isSelected: appearance.fontFamily == 'Cinzel',
                          onTap: () => ref.read(hymnAppearanceProvider.notifier).setFontFamily('Cinzel'),
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
                          setSheetState(() {});
                        },
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Restablecer valores'),
                      ),
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


// =============================================================================
// 2. Note (Nota) — Audio tracks sheet
// =============================================================================

/// Muestra el sheet de pistas de audio para un himno.
void showNoteSheet(
  BuildContext context, {
  required WidgetRef ref,
  required int himnoId,
  required bool isPlaying,
  required VoidCallback onPlay,
  required VoidCallback onStop,
}) {
  showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      final colorScheme = Theme.of(sheetContext).colorScheme;
      final textTheme = Theme.of(sheetContext).textTheme;

      return Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Handle
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
            // Pistas del himno mediante FutureBuilder
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
                    return ListTile(
                      leading: IconButton(
                        icon: Icon(
                          isPlaying
                              ? Icons.stop_rounded
                              : Icons.play_arrow_rounded,
                          color: isPlaying
                              ? colorScheme.error
                              : colorScheme.secondary,
                        ),
                        onPressed: () {
                          if (isPlaying) {
                            onStop();
                          } else {
                            onPlay();
                          }
                        },
                      ),
                      title: Text(
                        pista.descripcion ?? 'Pista ${pista.id}',
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
        ),
      );
    },
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
  required bool showChords,
  required ValueChanged<bool> onShowChordsChanged,
  VoidCallback? onCreateArrangement,
}) {
  showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final colorScheme = Theme.of(context).colorScheme;
          final textTheme = Theme.of(context).textTheme;
          final currentTranspose = ref.watch(transposeValueProvider);
          final currentKey = ref.watch(transposedKeyProvider);

          return Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Handle
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
                      onShowChordsChanged(value);
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
            ),
          );
        },
      );
    },
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

    if (query.length < 2) {
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
              'Escribe al menos 2 caracteres para buscar',
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
              title: Text(
                himno.titulo,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: himno.categoria.isNotEmpty
                  ? Text(
                      himno.categoria,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
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
// 5. _FontOption — Selector visual de fuente tipográfica
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

