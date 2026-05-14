import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/categoria.dart';
import '../../views_admin/providers/admin_providers.dart'
    show
        getAllCategoriasUseCaseProvider,
        createCategoriaUseCaseProvider,
        deleteCategoriaUseCaseProvider;
import '../../views_admin/providers/auth_providers.dart' show currentUserProvider;

// ─────────────────────────────────────────────────────────────
// Provider local: lista de categorías
// ─────────────────────────────────────────────────────────────

final _categoriaListProvider =
    FutureProvider.autoDispose<List<Categoria>>((ref) {
  return ref.watch(getAllCategoriasUseCaseProvider).execute();
});

// ─────────────────────────────────────────────────────────────

/// Tab de administración de categorías.
///
/// Permite crear nuevas categorías (solo nombre) y eliminar existentes.
/// Muestra la lista completa ordenada alfabéticamente.
class CategoriaTab extends ConsumerStatefulWidget {
  const CategoriaTab({super.key});

  @override
  ConsumerState<CategoriaTab> createState() => _CategoriaTabState();
}

class _CategoriaTabState extends ConsumerState<CategoriaTab> {
  final _nombreController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _agregarCategoria() async {
    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) return;

    final admin = ref.read(currentUserProvider);
    if (admin == null) return;

    setState(() => _loading = true);
    try {
      await ref.read(createCategoriaUseCaseProvider).execute(
            nombre,
            admin: admin,
          );
      _nombreController.clear();
      ref.invalidate(_categoriaListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Categoría "$nombre" creada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _eliminarCategoria(Categoria cat) async {
    final admin = ref.read(currentUserProvider);
    if (admin == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text('¿Eliminar "${cat.nombre}"?'),
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
      await ref.read(deleteCategoriaUseCaseProvider).execute(
            cat.id,
            admin: admin,
          );
      ref.invalidate(_categoriaListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Categoría "${cat.nombre}" eliminada')),
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
    final categoriasAsync = ref.watch(_categoriaListProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        // ── Formulario compacto ──────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(color: theme.dividerColor),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    hintText: 'Nueva categoría…',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _agregarCategoria(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _loading ? null : _agregarCategoria,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add, size: 20),
                label: const Text('Agregar'),
              ),
            ],
          ),
        ),
        // ── Lista de categorías ──────────────────────────────────
        Expanded(
          child: categoriasAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (categorias) {
              if (categorias.isEmpty) {
                return Center(
                  child: Text(
                    'No hay categorías',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: categorias.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final cat = categorias[index];
                  return ListTile(
                    title: Text(cat.nombre),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: theme.colorScheme.error,
                      ),
                      tooltip: 'Eliminar',
                      onPressed: () => _eliminarCategoria(cat),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
