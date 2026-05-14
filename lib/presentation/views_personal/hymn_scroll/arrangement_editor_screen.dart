import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/chord_transposer.dart';
import '../../../domain/entities/estrofa.dart';
import '../../../domain/entities/himno.dart';
import '../providers/hymn_providers.dart';
import '../providers/transpose_providers.dart';

/// Pantalla 4: Editor de Arreglos.
///
/// Permite al usuario modificar los acordes de un himno y guardar
/// el arreglo como una versión personalizada (fork) en la tabla
/// `Estrofa_Arreglo`, vinculada al `Usuario` actual.
///
/// Basado en Interfaz.md §3-4:
/// - Lienzo de Letra: cada palabra es "tocable" para insertar acordes
/// - Selector Musical: teclado/rueda para elegir acordes
/// - Botón Guardar: persiste el arreglo
class ArrangementEditorScreen extends ConsumerStatefulWidget {
  final Himno himno;

  const ArrangementEditorScreen({
    super.key,
    required this.himno,
  });

  @override
  ConsumerState<ArrangementEditorScreen> createState() =>
      _ArrangementEditorScreenState();
}

class _ArrangementEditorScreenState
    extends ConsumerState<ArrangementEditorScreen> {
  /// Mapa de estrofas editadas: key = "estrofaId:linea", value = texto editado
  final Map<String, String> _editedStanzas = {};

  /// Índice de la estrofa que se está editando actualmente
  int _editingStanzaIndex = -1;

  /// Índice de la línea dentro de la estrofa que se está editando
  int _editingLineIndex = -1;

  /// Acorde seleccionado en el selector musical
  String _selectedChord = '';

  /// Nombre del arreglo
  final TextEditingController _nameController =
      TextEditingController(text: 'Mi Arreglo');

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final stanzasAsync = ref.watch(stanzasProvider(widget.himno.primaryVersionPaisId));
    final transposeValue = ref.watch(transposeValueProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Editor: ${widget.himno.titulo}'),
        actions: [
          // Botón Guardar
          IconButton(
            onPressed:
                _editingStanzaIndex >= 0 ? () => _saveArrangement() : null,
            icon: const Icon(Icons.save_rounded),
            tooltip: 'Guardar Arreglo',
          ),
        ],
      ),
      body: Column(
        children: [
          // Nombre del arreglo
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Arreglo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.music_note),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Lienzo de letra editable
          Expanded(
            child: stanzasAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (estrofas) {
                if (estrofas.isEmpty) {
                  return const Center(
                    child: Text('No hay estrofas disponibles'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: estrofas.length,
                  itemBuilder: (context, index) {
                    return _buildEditableStanza(
                      context,
                      estrofas[index],
                      index,
                      transposeValue,
                      colorScheme,
                      textTheme,
                    );
                  },
                );
              },
            ),
          ),

          // Selector Musical (rueda/teclado de acordes)
          if (_editingStanzaIndex >= 0) _buildChordSelector(colorScheme),
        ],
      ),
    );
  }

  Widget _buildEditableStanza(
    BuildContext context,
    Estrofa estrofa,
    int index,
    int transposeValue,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final isChorus = estrofa.isChorus;
    final isSelected = _editingStanzaIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.2)
            : isChorus
                ? colorScheme.primaryContainer.withValues(alpha: 0.1)
                : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: colorScheme.primary, width: 2)
            : isChorus
                ? Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  )
                : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera de la estrofa + botón editar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  estrofa.tipo.value.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              if (!isSelected)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _editingStanzaIndex = index;
                    });
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Editar'),
                ),
              if (isSelected)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _editingStanzaIndex = -1;
                      _editingLineIndex = -1;
                    });
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Listo'),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Líneas de la estrofa (cada línea es "tocable")
          ..._buildEditableLines(
            estrofa,
            index,
            transposeValue,
            colorScheme,
            textTheme,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEditableLines(
    Estrofa estrofa,
    int stanzaIndex,
    int transposeValue,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    // Obtener el contenido (posiblemente editado)
    final content =
        _editedStanzas['${estrofa.id}_content'] ?? estrofa.contenido;
    final transposedContent = transposeChordPro(content, transposeValue);
    final lines = transposedContent.split('\n');

    return List.generate(lines.length, (lineIndex) {
      final line = lines[lineIndex];
      final isLineEditing =
          _editingStanzaIndex == stanzaIndex && _editingLineIndex == lineIndex;

      return GestureDetector(
        onTap: _editingStanzaIndex == stanzaIndex
            ? () {
                setState(() {
                  _editingLineIndex = lineIndex;
                  // Extraer acorde actual si existe
                  final chordMatch =
                      RegExp(r'\[([A-G][#b]?[a-zA-Z0-9+#b]*(?:/[A-G][#b]?)?)\]')
                          .firstMatch(line);
                  _selectedChord = chordMatch?.group(1) ?? _selectedChord;
                });
              }
            : null,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isLineEditing
                ? colorScheme.primaryContainer.withValues(alpha: 0.4)
                : null,
            borderRadius: BorderRadius.circular(4),
            border:
                isLineEditing ? Border.all(color: colorScheme.primary) : null,
          ),
          child: _buildChordProLine(
            line,
            isLineEditing,
            colorScheme,
            textTheme,
          ),
        ),
      );
    });
  }

  /// Renderiza una línea con acordes ChordPro en formato RichText.
  Widget _buildChordProLine(
    String line,
    bool isEditing,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final chordRegex =
        RegExp(r'\[([A-G][#b]?[a-zA-Z0-9+#b]*(?:/[A-G][#b]?)?)\]');
    final matches = chordRegex.allMatches(line);

    if (matches.isEmpty) {
      return Text(
        line,
        style: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
          height: 1.6,
        ),
      );
    }

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      // Texto antes del acorde
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: line.substring(lastEnd, match.start),
          ),
        );
      }

      // Acorde renderizado destacado
      final chord = match.group(1) ?? '';
      spans.add(
        WidgetSpan(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: isEditing
                  ? colorScheme.primary.withValues(alpha: 0.15)
                  : colorScheme.tertiaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              chord,
              style: textTheme.bodyMedium?.copyWith(
                color: isEditing ? colorScheme.primary : colorScheme.tertiary,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      );

      lastEnd = match.end;
    }

    // Texto restante
    if (lastEnd < line.length) {
      spans.add(TextSpan(text: line.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(
        style: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurface,
          height: 1.6,
        ),
        children: spans,
      ),
    );
  }

  /// Selector musical: teclado de acordes que aparece al editar una línea.
  Widget _buildChordSelector(ColorScheme colorScheme) {
    // Notas base
    const notas = [
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B',
    ];

    // Sufijos de acorde
    const sufijos = ['', 'm', '7', 'm7', 'dim', 'aug', 'sus4', 'maj7'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fila de notas base
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: notas.length,
              itemBuilder: (context, index) {
                final nota = notas[index];
                final isSelected = _selectedChord.startsWith(nota);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(nota),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        // Mantener el sufijo actual si existe
                        final currentChord = _selectedChord;
                        final suffix = currentChord.length > 1
                            ? currentChord.substring(
                                currentChord.startsWith(RegExp(r'[A-G][#b]'))
                                    ? (currentChord[1] == '#' ||
                                            currentChord[1] == 'b'
                                        ? 2
                                        : 1)
                                    : 1,
                              )
                            : '';
                        _selectedChord = '$nota$suffix';
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Fila de sufijos
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: sufijos.length,
              itemBuilder: (context, index) {
                final sufijo = sufijos[index];
                final displayLabel = sufijo.isEmpty ? 'Mayor' : sufijo;
                // Determinar cuál es la raíz de _selectedChord
                final root = _selectedChord.length >= 2 &&
                        (_selectedChord[1] == '#' || _selectedChord[1] == 'b')
                    ? _selectedChord.substring(0, 2)
                    : _selectedChord.isNotEmpty
                        ? _selectedChord[0]
                        : 'C';
                final fullChord = root + sufijo;
                final isSelected = _selectedChord == fullChord;

                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      displayLabel,
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedChord = fullChord;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Botón para insertar acorde en la línea seleccionada
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _editingLineIndex >= 0 ? _insertChordAtLine : null,
                  icon: const Icon(Icons.add),
                  label: Text('Insertar [$_selectedChord]'),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _editingLineIndex >= 0 ? _removeChordAtLine : null,
                child: const Text('Quitar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Inserta el acorde seleccionado al inicio de la línea en edición.
  void _insertChordAtLine() {
    if (_editingStanzaIndex < 0 || _editingLineIndex < 0) return;

    final stanzasAsync = ref.read(stanzasProvider(widget.himno.primaryVersionPaisId));
    stanzasAsync.whenData((estrofas) {
      if (_editingStanzaIndex >= estrofas.length) return;
      final estrofa = estrofas[_editingStanzaIndex];
      // Usar contenido editado si existe, si no el original
      final key = '${estrofa.id}_content';
      final content = _editedStanzas[key] ?? estrofa.contenido;
      final lines = content.split('\n');
      if (_editingLineIndex >= lines.length) return;

      final line = lines[_editingLineIndex];
      final newLine = '[$_selectedChord]$line';

      lines[_editingLineIndex] = newLine;
      final newContent = lines.join('\n');

      setState(() {
        _editedStanzas[key] = newContent;
      });
    });
  }

  /// Elimina el primer acorde de la línea en edición.
  void _removeChordAtLine() {
    if (_editingStanzaIndex < 0 || _editingLineIndex < 0) return;

    final stanzasAsync = ref.read(stanzasProvider(widget.himno.primaryVersionPaisId));
    stanzasAsync.whenData((estrofas) {
      if (_editingStanzaIndex >= estrofas.length) return;
      final estrofa = estrofas[_editingStanzaIndex];
      // Usar contenido editado si existe, si no el original
      final key = '${estrofa.id}_content';
      final content = _editedStanzas[key] ?? estrofa.contenido;
      final lines = content.split('\n');
      if (_editingLineIndex >= lines.length) return;

      final line = lines[_editingLineIndex];
      // Eliminar el primer marcador [Acorde] al inicio de la línea
      final newLine = line.replaceFirst(
        RegExp(r'^\[[A-G][#b]?[a-zA-Z0-9+#b]*(?:/[A-G][#b]?)?\]'),
        '',
      );

      if (newLine == line) {
        // No había acorde al inicio
        return;
      }

      lines[_editingLineIndex] = newLine;
      final newContent = lines.join('\n');

      setState(() {
        _editedStanzas[key] = newContent;
      });
    });
  }

  /// Guarda el arreglo en la base de datos.
  Future<void> _saveArrangement() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un nombre para el arreglo')),
      );
      return;
    }

    // Validar que el himno tenga al menos una versión de país
    final version = widget.himno.versiones.firstOrNull;
    if (version == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este himno no tiene versiones de país'),
        ),
      );
      return;
    }

    // Mostrar indicador de carga
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Guardando arreglo...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      // Obtener las estrofas originales desde el provider
      final stanzasAsync = ref.read(stanzasProvider(widget.himno.primaryVersionPaisId));
      final estrofas = stanzasAsync.when(
        loading: () => <Estrofa>[],
        error: (_, __) => <Estrofa>[],
        data: (list) => list,
      );

      if (estrofas.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay estrofas para guardar'),
          ),
        );
        return;
      }

      // Construir lista de estrofas con ediciones mergeadas
      final estrofasData = estrofas.map((e) {
        // Usar contenido editado si existe, si no el original
        final key = '${e.id}_content';
        final contenido = _editedStanzas[key] ?? e.contenido;
        return (
          tipo: e.tipo.value,
          orden: e.orden,
          contenido: contenido,
        );
      }).toList();

      // Guardar el arreglo
      final repo = ref.read(hymnRepositoryProvider);
      final arrangementId = await repo.createArrangement(
        versionPaisId: version.id,
        usuarioId: 1, // Usuario por defecto (Admin) hasta implementar auth
        nombreArreglo: name,
        tonalidadBase: version.tonalidadOriginal,
        estrofas: estrofasData,
      );

      // Éxito
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Arreglo "$name" guardado (ID #$arrangementId)'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      // Error
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
