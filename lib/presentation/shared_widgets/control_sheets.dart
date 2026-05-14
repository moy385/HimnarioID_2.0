import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/himno.dart';
import '../../../domain/entities/pista_audio.dart';
import '../views_personal/providers/audio_providers.dart';
import '../views_personal/providers/hymn_providers.dart';
import '../views_personal/providers/transpose_providers.dart';

// =============================================================================
// 1. Brush (Brocha) — Visual configuration sheet
// =============================================================================

/// Muestra el sheet de configuración visual (tamaño de fuente, color de fondo).
void showBrushSheet(
  BuildContext context, {
  required double fontScale,
  required ValueChanged<double> onFontScaleChanged,
  required int bgColorIndex,
  required ValueChanged<int> onBgColorIndexChanged,
  List<Color>? bgColors,
}) {
  final effectiveBgColors = bgColors ??
      const <Color>[
        Colors.transparent,
        Color(0xFFF5F0E8),
        Color(0xFFE8F0F5),
        Color(0xFFF0F5E8),
        Color(0xFFF5E8F0),
      ];

  showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final colorScheme = Theme.of(context).colorScheme;
          final textTheme = Theme.of(context).textTheme;

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
                // Title
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
                // Font size slider
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
                        value: fontScale,
                        min: 0.7,
                        max: 1.8,
                        divisions: 11,
                        label: '${(fontScale * 100).round()}%',
                        onChanged: (value) {
                          setSheetState(() {
                            onFontScaleChanged(value);
                          });
                        },
                      ),
                    ),
                    const Icon(Icons.text_fields, size: 26),
                  ],
                ),
                const SizedBox(height: 16),
                // Background color selector
                Text(
                  'Color de fondo',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  children: List<Widget>.generate(
                    effectiveBgColors.length,
                    (int i) {
                      final isSelected = bgColorIndex == i;
                      final color = effectiveBgColors[i];
                      final isTransparent = color == Colors.transparent;

                      return GestureDetector(
                        onTap: () {
                          setSheetState(() {
                            onBgColorIndexChanged(i);
                          });
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isTransparent
                                ? colorScheme.surfaceContainerHighest
                                : color,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant,
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
                    },
                  ),
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
