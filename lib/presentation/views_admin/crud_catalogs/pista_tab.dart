import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/himno.dart';
import '../../../domain/entities/pista_audio.dart';
import '../../../domain/usecases/himno/search_hymns_usecase.dart';
import '../../views_admin/providers/admin_providers.dart'
    show
        getPistasByHimnoUseCaseProvider,
        createPistaUseCaseProvider,
        deletePistaUseCaseProvider;
import '../../views_admin/providers/auth_providers.dart' show currentUserProvider;

// ─────────────────────────────────────────────────────────────
// Providers locales
// ─────────────────────────────────────────────────────────────

/// Provider para la búsqueda de himnos por texto.
final _searchHimnosProvider =
    FutureProvider.autoDispose.family<List<Himno>, String>((ref, query) {
  if (query.trim().isEmpty) return Future.value([]);
  return ref.watch(searchHymnsUseCaseProvider).execute(query);
});

/// Provider para las pistas de un himno seleccionado.
final _pistasByHimnoProvider =
    FutureProvider.autoDispose.family<List<PistaAudio>, int>((ref, himnoId) {
  return ref.watch(getPistasByHimnoUseCaseProvider).execute(himnoId);
});

// ─────────────────────────────────────────────────────────────

/// Tab de administración de pistas de audio.
///
/// Permite seleccionar un himno y gestionar sus pistas de audio
/// (agregar, eliminar).
class PistaTab extends ConsumerStatefulWidget {
  const PistaTab({super.key});

  @override
  ConsumerState<PistaTab> createState() => _PistaTabState();
}

class _PistaTabState extends ConsumerState<PistaTab> {
  Himno? _himnoSeleccionado;
  int? _himnoIdSeleccionado;

  // Controladores para el formulario de agregar pista
  final _rutaController = TextEditingController();
  final _descripcionController = TextEditingController();
  String _origen = 'local';

  // Controlador para la búsqueda
  final _searchController = TextEditingController();
  bool _showSearchResults = false;

  @override
  void dispose() {
    _rutaController.dispose();
    _descripcionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _agregarPista() async {
    final admin = ref.read(currentUserProvider);
    if (admin == null) return;
    if (_himnoIdSeleccionado == null) return;
    final ruta = _rutaController.text.trim();
    if (ruta.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La ruta del archivo es requerida'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await ref.read(createPistaUseCaseProvider).execute(
            himnoId: _himnoIdSeleccionado!,
            rutaArchivo: ruta,
            descripcion: _descripcionController.text.trim().isEmpty
                ? null
                : _descripcionController.text.trim(),
            origen: _origen,
            admin: admin,
          );
      _rutaController.clear();
      _descripcionController.clear();
      setState(() => _origen = 'local');
      ref.invalidate(_pistasByHimnoProvider(_himnoIdSeleccionado!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pista agregada')),
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

  Future<void> _eliminarPista(PistaAudio pista) async {
    final admin = ref.read(currentUserProvider);
    if (admin == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar pista'),
        content: Text(
          '¿Eliminar la pista "${pista.descripcion ?? pista.rutaArchivo}"?',
        ),
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
      await ref.read(deletePistaUseCaseProvider).execute(
            pista.id,
            admin: admin,
          );
      if (_himnoIdSeleccionado != null) {
        ref.invalidate(_pistasByHimnoProvider(_himnoIdSeleccionado!));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pista eliminada')),
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

  void _seleccionarHimno(Himno himno) {
    setState(() {
      _himnoSeleccionado = himno;
      _himnoIdSeleccionado = himno.id;
      _showSearchResults = false;
      _searchController.text = '${himno.numero ?? ""} - ${himno.titulo}';
    });
    ref.invalidate(_pistasByHimnoProvider(himno.id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final himnoId = _himnoIdSeleccionado;

    return Column(
      children: [
        // ── Selector de himno ────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(color: theme.dividerColor),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seleccionar himno',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por número o título…',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  suffixIcon: _himnoSeleccionado != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _himnoSeleccionado = null;
                              _himnoIdSeleccionado = null;
                              _searchController.clear();
                              _showSearchResults = false;
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() => _showSearchResults = value.trim().isNotEmpty);
                },
              ),
              if (_showSearchResults) _buildSearchResults(),
            ],
          ),
        ),
        // ── Lista de pistas ──────────────────────────────────────
        if (himnoId != null)
          Expanded(
            child: _buildPistasList(himnoId, theme),
          ),
        // ── Formulario para agregar pista ────────────────────────
        if (himnoId != null)
          _buildAddForm(theme),
      ],
    );
  }

  Widget _buildSearchResults() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return const SizedBox.shrink();

    final resultAsync = ref.watch(_searchHimnosProvider(query));

    return resultAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: LinearProgressIndicator(),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.all(8),
        child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
      ),
      data: (himnos) {
        if (himnos.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Sin resultados'),
          );
        }
        return Container(
          constraints: const BoxConstraints(maxHeight: 200),
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView(
            shrinkWrap: true,
            children: himnos.map((h) {
              return ListTile(
                dense: true,
                title: Text(
                  '${h.numero ?? "—"} · ${h.titulo}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => _seleccionarHimno(h),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildPistasList(int himnoId, ThemeData theme) {
    final pistasAsync = ref.watch(_pistasByHimnoProvider(himnoId));

    return pistasAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (pistas) {
        if (pistas.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.music_note_outlined,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  'Sin pistas para este himno',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: pistas.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final pista = pistas[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.tertiaryContainer,
                child: Icon(
                  Icons.audiotrack,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
              title: Text(
                pista.rutaArchivo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                [
                  if (pista.descripcion != null) pista.descripcion!,
                  if (pista.formato != null) 'Formato: ${pista.formato}',
                  if (pista.duracionSegundos != null)
                    '${pista.duracionSegundos!.toStringAsFixed(1)}s',
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                ),
                tooltip: 'Eliminar',
                onPressed: () => _eliminarPista(pista),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAddForm(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Agregar pista',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _rutaController,
            decoration: const InputDecoration(
              hintText: 'Ruta del archivo…',
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descripcionController,
            decoration: const InputDecoration(
              hintText: 'Descripción (opcional)…',
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey(_origen),
            initialValue: _origen,
            decoration: const InputDecoration(
              labelText: 'Origen',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: const [
              DropdownMenuItem(value: 'local', child: Text('Local')),
              DropdownMenuItem(value: 'donación', child: Text('Donación')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _origen = v);
            },
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _agregarPista,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Agregar pista'),
            ),
          ),
        ],
      ),
    );
  }
}
