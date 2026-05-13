import 'package:flutter/material.dart';
import '../../shared_widgets/hymn_card.dart';

/// Pantalla de detalle del himno (Formato Scroll para móvil)
/// Muestra letra completa con acordes y controles de transposición
class HymnDetailScreen extends StatefulWidget {
  final HymnModel himno;

  const HymnDetailScreen({
    super.key,
    required this.himno,
  });

  @override
  State<HymnDetailScreen> createState() => _HymnDetailScreenState();
}

class _HymnDetailScreenState extends State<HymnDetailScreen> {
  int _transposeValue = 0;
  final String _currentKey = 'G'; // Tono original

  // Letra de ejemplo del himno (formato simple con estrofas)
  final List<Map<String, String>> _estrofas = const [
    {
      'tipo': 'estrofa',
      'contenido':
          'Santo, Santo, Santo\n'
          'Dios de cielos y tierra\n'
          'Lleno está el cielo de tu gloria\n'
          'Santo, Santo, Santo',
    },
    {
      'tipo': 'estrofa',
      'contenido':
          'Bendito Salvador mío\n'
          'Tan dulce y amoroso\n'
          'Divino Salvador\n'
          'Tú me has redimido',
    },
    {
      'tipo': 'coro',
      'contenido':
          'Gloria, gloria, gloria\n'
          'Al Dios tres veces santo\n'
          'Alabemos todos juntos\n'
          'Al Rey de los reyes',
    },
  ];

  // Lista de notas musicales para transposición
  static const List<String> _notas = [
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

  void _transposeUp() {
    setState(() {
      _transposeValue = (_transposeValue + 1) % 12;
    });
  }

  void _transposeDown() {
    setState(() {
      _transposeValue = (_transposeValue - 1 + 12) % 12;
    });
  }

  String _getTransposedKey() {
    final originalIndex = _notas.indexOf(_currentKey);
    final transposedIndex = (originalIndex + _transposeValue) % 12;
    return _notas[transposedIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Himno ${widget.himno.numero}'),
        actions: [
          // Menú de opciones
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'arreglo') {
                // TODO: Navegar al editor de arreglos
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Editor de arreglos (próximamente)'),
                  ),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabecera del himno
                  _buildHeader(context),
                  const SizedBox(height: 24),

                  // Renderizado de letra
                  ..._estrofas.map(
                    (estrofa) => _buildStanza(
                      context,
                      estrofa['tipo']!,
                      estrofa['contenido']!,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Barra inferior sticky
          _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        Text(
          widget.himno.titulo,
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
              label: Text(widget.himno.categoria),
              backgroundColor: colorScheme.tertiaryContainer,
              labelStyle: TextStyle(
                color: colorScheme.onTertiaryContainer,
              ),
              side: BorderSide.none,
            ),
            if (!widget.himno.esOficial)
              Chip(
                label: const Text('Personal'),
                backgroundColor: colorScheme.secondaryContainer,
                labelStyle: TextStyle(
                  color: colorScheme.onSecondaryContainer,
                ),
                side: BorderSide.none,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStanza(BuildContext context, String tipo, String contenido) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isChorus = tipo == 'coro';

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
              isChorus ? 'CORO' : 'ESTROFA',
              style: textTheme.labelSmall?.copyWith(
                color: isChorus
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Letra con parseo básico de acordes
          _buildLyricWithChords(context, contenido),
        ],
      ),
    );
  }

  Widget _buildLyricWithChords(BuildContext context, String lyric) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Parser básico: detecta [Acorde] en el texto
    // En implementación real, usaríamos un parser de ChordPro
    final parts = lyric.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts.map((line) {
        // Buscar acordes en formato [Acorde]Texto
        final chordRegex = RegExp(r'\[([A-G][#b]?m?)\]');
        final matches = chordRegex.allMatches(line);

        if (matches.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              line,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
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
              children: _parseChordsInLine(line, colorScheme, textTheme),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<TextSpan> _parseChordsInLine(
    String line,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final chordRegex = RegExp(r'(\[.*?\])|(.*?)(?=\[|$)');
    final matches = chordRegex.allMatches(line);

    return matches.map((match) {
      final matchText = match.group(0);
      if (matchText == null) return const TextSpan();

      if (matchText.startsWith('[')) {
        // Es un acorde
        return TextSpan(
          text: '$matchText ',
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.tertiary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        );
      } else {
        // Es texto normal
        return TextSpan(
          text: matchText,
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
        );
      }
    }).toList();
  }

  Widget _buildBottomBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
            color: Colors.black.withValues(alpha: 0.1),
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
                    onPressed: _transposeDown,
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
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          _getTransposedKey(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _transposeUp,
                    icon: const Icon(Icons.add),
                    tooltip: 'Subir tono',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Botón de reproducir audio (placeholder)
            IconButton.filled(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reproducción de audio (próximamente)'),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow_rounded),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
              ),
            ),
            const Spacer(),
            // Botón PROYECTAR (FAB)
            FilledButton.icon(
              onPressed: () {
                // Navegar a pantalla de control en vivo
                Navigator.pushNamed(context, '/live-control');
              },
              icon: const Icon(Icons.present_to_all),
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
}