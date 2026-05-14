import 'package:flutter/material.dart';

import '../../../../core/enums/estrofa_tipo.dart';

/// Editor de un bloque de estrofa individual.
///
/// Widget reutilizable que permite editar el tipo, contenido ChordPro
/// y reordenar/eliminar una estrofa dentro de la lista dinámica.
class StanzaBlockEditor extends StatelessWidget {
  final int index;
  final int total;
  final EstrofaTipo tipo;
  final String contenido;
  final ValueChanged<EstrofaTipo> onTipoChanged;
  final ValueChanged<String> onContenidoChanged;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onDelete;

  const StanzaBlockEditor({
    super.key,
    required this.index,
    required this.total,
    required this.tipo,
    required this.contenido,
    required this.onTipoChanged,
    required this.onContenidoChanged,
    this.onMoveUp,
    this.onMoveDown,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = 'Estrofa ${index + 1} (${tipo.value})';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabecera ─────────────────────────────────────
            Row(
              children: [
                Icon(Icons.music_note, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                _iconButton(
                  icon: Icons.keyboard_arrow_up,
                  tooltip: 'Mover arriba',
                  onPressed: index > 0 ? onMoveUp : null,
                ),
                _iconButton(
                  icon: Icons.keyboard_arrow_down,
                  tooltip: 'Mover abajo',
                  onPressed: index < total - 1 ? onMoveDown : null,
                ),
                _iconButton(
                  icon: Icons.delete_outline,
                  tooltip: 'Eliminar',
                  color: colorScheme.error,
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Dropdown de tipo ─────────────────────────────
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Tipo de estrofa',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<EstrofaTipo>(
                  value: tipo,
                  isDense: true,
                  isExpanded: true,
                  items: EstrofaTipo.values.map((t) {
                    return DropdownMenuItem(value: t, child: Text(t.value));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) onTipoChanged(v);
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Campo de contenido ChordPro ──────────────────
            TextField(
              controller: TextEditingController.fromValue(
                TextEditingValue(
                  text: contenido,
                  selection: TextSelection.collapsed(offset: contenido.length),
                ),
              ),
              onChanged: onContenidoChanged,
              maxLines: 6,
              minLines: 3,
              decoration: InputDecoration(
                labelText: 'Contenido (ChordPro)',
                hintText: '[C]Texto del acorde y letra...',
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
                suffixIcon: contenido.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => onContenidoChanged(''),
                      )
                    : null,
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      color: color,
    );
  }
}
