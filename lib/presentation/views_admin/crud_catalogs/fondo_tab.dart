import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/fondo_pantalla_tipo.dart';
import '../../../domain/entities/fondo_pantalla.dart';
import '../../views_admin/providers/admin_providers.dart'
    show
        getAllFondosUseCaseProvider,
        createFondoUseCaseProvider,
        updateFondoUseCaseProvider,
        deleteFondoUseCaseProvider;
import '../../views_admin/providers/auth_providers.dart' show currentUserProvider;

// ─────────────────────────────────────────────────────────────
// Provider local: lista de fondos
// ─────────────────────────────────────────────────────────────

final _fondoListProvider =
    FutureProvider.autoDispose<List<FondoPantalla>>((ref) {
  return ref.watch(getAllFondosUseCaseProvider).execute();
});

// ─────────────────────────────────────────────────────────────

/// Tab de administración de fondos de pantalla.
///
/// Permite crear, editar y eliminar fondos. El formulario es condicional:
/// - Si tipo = color_solido → campo color_hex con vista previa
/// - Si tipo = imagen/video → campo ruta_archivo
/// Incluye checkbox "Predeterminado".
class FondoTab extends ConsumerStatefulWidget {
  const FondoTab({super.key});

  @override
  ConsumerState<FondoTab> createState() => _FondoTabState();
}

class _FondoTabState extends ConsumerState<FondoTab> {
  // Formulario
  final _nombreController = TextEditingController();
  final _rutaController = TextEditingController();
  final _colorController = TextEditingController();
  FondoPantallaTipo _tipo = FondoPantallaTipo.imagen;
  bool _esPredeterminado = false;

  // Modo edición
  FondoPantalla? _editando;

  @override
  void dispose() {
    _nombreController.dispose();
    _rutaController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _nombreController.clear();
      _rutaController.clear();
      _colorController.clear();
      _tipo = FondoPantallaTipo.imagen;
      _esPredeterminado = false;
      _editando = null;
    });
  }

  void _cargarEnFormulario(FondoPantalla fondo) {
    setState(() {
      _editando = fondo;
      _nombreController.text = fondo.nombre;
      _tipo = fondo.tipo;
      _esPredeterminado = fondo.esPredeterminado;
      if (fondo.tipo == FondoPantallaTipo.colorSolido) {
        _colorController.text = fondo.colorHex ?? '';
        _rutaController.clear();
      } else {
        _rutaController.text = fondo.rutaArchivo ?? '';
        _colorController.clear();
      }
    });
  }

  Future<void> _guardar() async {
    final admin = ref.read(currentUserProvider);
    if (admin == null) return;

    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre es requerido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final rutaArchivo =
        _tipo != FondoPantallaTipo.colorSolido ? _rutaController.text.trim() : null;
    final colorHex =
        _tipo == FondoPantallaTipo.colorSolido ? _colorController.text.trim() : null;

    try {
      if (_editando != null) {
        // Actualizar
        await ref.read(updateFondoUseCaseProvider).execute(
              id: _editando!.id,
              nombre: nombre,
              tipo: _tipo,
              rutaArchivo: rutaArchivo,
              colorHex: colorHex,
              esPredeterminado: _esPredeterminado,
              activo: true,
              admin: admin,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fondo "$nombre" actualizado')),
          );
        }
      } else {
        // Crear
        await ref.read(createFondoUseCaseProvider).execute(
              nombre: nombre,
              tipo: _tipo,
              rutaArchivo: rutaArchivo,
              colorHex: colorHex,
              esPredeterminado: _esPredeterminado,
              activo: true,
              admin: admin,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fondo "$nombre" creado')),
          );
        }
      }
      _resetForm();
      ref.invalidate(_fondoListProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _eliminarFondo(FondoPantalla fondo) async {
    final admin = ref.read(currentUserProvider);
    if (admin == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar fondo'),
        content: Text('¿Eliminar fondo "${fondo.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref.read(deleteFondoUseCaseProvider).execute(
            fondo.id,
            admin: admin,
          );
      if (_editando?.id == fondo.id) _resetForm();
      ref.invalidate(_fondoListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fondo "${fondo.nombre}" eliminado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // ── Formulario ───────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(color: theme.dividerColor),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _editando != null ? 'Editar fondo' : 'Nuevo fondo',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 12),
                // Nombre
                TextField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                // Tipo
                DropdownButtonFormField<FondoPantallaTipo>(
                  key: ValueKey(_tipo),
                  initialValue: _tipo,
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: FondoPantallaTipo.imagen,
                      child: Text('Imagen'),
                    ),
                    DropdownMenuItem(
                      value: FondoPantallaTipo.video,
                      child: Text('Video'),
                    ),
                    DropdownMenuItem(
                      value: FondoPantallaTipo.colorSolido,
                      child: Text('Color sólido'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _tipo = v);
                  },
                ),
                const SizedBox(height: 12),
                // Campo condicional
                if (_tipo == FondoPantallaTipo.colorSolido)
                  _buildColorField(theme)
                else
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _rutaController,
                          decoration: InputDecoration(
                            labelText: _tipo == FondoPantallaTipo.imagen
                                ? 'Ruta de imagen'
                                : 'Ruta de video',
                            hintText: 'Selecciona un archivo...',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.folder_open),
                        tooltip: 'Seleccionar archivo',
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.media,
                            allowMultiple: false,
                          );
                          if (result != null && result.files.isNotEmpty) {
                            _rutaController.text =
                                result.files.single.path ?? '';
                          }
                        },
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                // Checkbox predeterminado
                CheckboxListTile(
                  title: const Text('Predeterminado'),
                  value: _esPredeterminado,
                  onChanged: (v) {
                    setState(() => _esPredeterminado = v ?? false);
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 8),
                // Botones
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _guardar,
                        icon: Icon(
                          _editando != null ? Icons.save : Icons.add,
                          size: 20,
                        ),
                        label: Text(_editando != null ? 'Actualizar' : 'Crear'),
                      ),
                    ),
                    if (_editando != null) ...[
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _resetForm,
                        child: const Text('Cancelar'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        // ── Lista de fondos ─────────────────────────────────────
        Expanded(
          child: ref.watch(_fondoListProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (fondos) {
              if (fondos.isEmpty) {
                return Center(
                  child: Text(
                    'No hay fondos registrados',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: fondos.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final fondo = fondos[index];
                  return ListTile(
                    leading: _buildFondoPreview(fondo),
                    title: Text(fondo.nombre),
                    subtitle: Text(
                      [
                        _tipoLabel(fondo.tipo),
                        if (fondo.esPredeterminado) 'Predeterminado',
                        if (!fondo.activo) 'Inactivo',
                      ].join(' · '),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Editar',
                          onPressed: () => _cargarEnFormulario(fondo),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: theme.colorScheme.error,
                          ),
                          tooltip: 'Eliminar',
                          onPressed: () => _eliminarFondo(fondo),
                        ),
                      ],
                    ),
                    onTap: () => _cargarEnFormulario(fondo),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColorField(ThemeData theme) {
    // Intentar parsear el color hex para vista previa
    Color? previewColor;
    final hex = _colorController.text.trim();
    if (hex.isNotEmpty) {
      try {
        final cleanHex = hex.replaceFirst('#', '');
        if (cleanHex.length == 6) {
          previewColor = Color(int.parse('FF$cleanHex', radix: 16));
        } else if (cleanHex.length == 8) {
          previewColor = Color(int.parse(cleanHex, radix: 16));
        }
      } catch (_) {}
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _colorController,
            decoration: const InputDecoration(
              labelText: 'Color hex',
              hintText: '#RRGGBB',
              isDense: true,
              prefixText: '#',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (previewColor != null) ...[
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: previewColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFondoPreview(FondoPantalla fondo) {
    if (fondo.tipo == FondoPantallaTipo.colorSolido && fondo.colorHex != null) {
      Color? color;
      try {
        final hex = fondo.colorHex!.replaceFirst('#', '');
        if (hex.length == 6) {
          color = Color(int.parse('FF$hex', radix: 16));
        }
      } catch (_) {}
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color ?? Colors.grey,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
      );
    }
    return CircleAvatar(
      backgroundColor: fondo.tipo == FondoPantallaTipo.video
          ? Colors.blue.shade100
          : Colors.green.shade100,
      child: Icon(
        fondo.tipo == FondoPantallaTipo.video
            ? Icons.videocam
            : Icons.image,
        color: fondo.tipo == FondoPantallaTipo.video
            ? Colors.blue.shade700
            : Colors.green.shade700,
      ),
    );
  }

  String _tipoLabel(FondoPantallaTipo tipo) {
    switch (tipo) {
      case FondoPantallaTipo.imagen:
        return 'Imagen';
      case FondoPantallaTipo.video:
        return 'Video';
      case FondoPantallaTipo.colorSolido:
        return 'Color sólido';
    }
  }
}
